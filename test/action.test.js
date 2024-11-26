const yaml = require("js-yaml");
const fs = require("fs");
const path = require("path");
const os = require("node:os");
const { spawnSync } = require("child_process");

describe("GitHub Action Tests", () => {
  describe("Action Configuration Validation", () => {
    let actionConfig;
    let entrypointContent;

    beforeAll(() => {
      entrypointContent = fs.readFileSync("./entrypoint.sh", "utf8");
      const actionYaml = fs.readFileSync("./action.yaml", "utf8");
      actionConfig = yaml.load(actionYaml);
    });

    test("action.yml structure matches entrypoint.sh usage", () => {
      Object.keys(actionConfig.inputs).forEach((input) => {
        const envVar = `\${INPUT_${input.toUpperCase()}\}`;
        expect(entrypointContent).toContain(envVar);
      });
    });

    test("all inputs in action.yml have corresponding handling in entrypoint.sh", () => {
      const entrypointContent = fs.readFileSync("./entrypoint.sh", "utf8");
      Object.keys(actionConfig.inputs).forEach((input) => {
        if (input !== "show_annotations" && input !== "api_token") {
          const flagName = input.replace(/_/g, "-");
          expect(entrypointContent).toContain(`--${flagName}`);
        }
      });
    });
  });

  describe("Entrypoint execution", () => {
    let originalEnv;
    const testFilesPath = path.join(os.tmpdir(), "shiftleft-sast-action-tests");
    const testWorkspace = path.join(testFilesPath, "test-workspace");
    const testResultsPath = path.join(testFilesPath, "results/");
    const mockOrcaPath = path.join(testFilesPath, "mock-orca-cli");
    const testEntrypoint = path.join(testFilesPath, "test-entrypoint.sh");
    const githubOutput = path.join(testFilesPath, "github_output");

    beforeAll(() => {
      // Create test workspace
      fs.mkdirSync(testWorkspace, { recursive: true });

      // Create mock orca-cli script
      fs.writeFileSync(mockOrcaPath, fs.readFileSync("./test/mock-orca-cli"), {
        mode: 0o755,
      });
      fs.mkdirSync(testResultsPath, { recursive: true });
      fs.writeFileSync(path.join(testResultsPath, "/sast.json"), "", {
        mode: 0o755,
      });

      // Create modified entrypoint that uses mock orca-cli
      const entrypoint = fs
        .readFileSync("./entrypoint.sh", "utf8")
        .replace(/orca-cli/g, mockOrcaPath);
      fs.writeFileSync(testEntrypoint, entrypoint, { mode: 0o755 });
      fs.writeFileSync(githubOutput, "", { mode: 0o755 });
    });

    beforeEach(() => {
      originalEnv = { ...process.env };
      process.env = {
        ...process.env,
        GITHUB_WORKSPACE: testWorkspace,
        GITHUB_OUTPUT: githubOutput,
        APP_DIR: testFilesPath,
      };
    });

    afterEach(() => {
      process.env = originalEnv;
      jest.clearAllMocks();
      if (fs.existsSync(testResultsPath)) {
        fs.rmSync(testResultsPath, { recursive: true, force: true });
      }
    });

    afterAll(() => {
      // Clean up the directory after all tests
      if (fs.existsSync(testFilesPath)) {
        fs.rmdirSync(testFilesPath, { recursive: true });
      }
    });

    test("all inputs provided", () => {
      const testInputs = {
        ...mockRequiredInputs(),
        exit_code: { value: "1" },
        no_color: { value: "true" },
        silent: { value: "true" },
        disable_err_report: { value: "true" },
        exclude_paths: { value: "test,temp" },
        format: { value: "json" },
        output: { value: testResultsPath },
        console_output: { value: "test-console_output", delimiter: "=" },
        timeout: { value: "1h" },
        preview_lines: { value: "5" },
        config: { value: "test-config" },
        max_file_size: { value: "10" },
        display_name: { value: "test-display-name" },
        debug: { value: "true" },
        log_path: { value: "/logs" },
      };
      const results = executeEntrypoint(testInputs);
      const orcaCliArgs = extractOrcaCliArgs(results);

      Object.entries(testInputs).forEach(
        ([inputKey, { value: inputValue, delimiter = " " }]) => {
          if (inputKey === "api_token" || inputKey === "show_annotations") {
            // api_token is set as an environment variable and show_annotations is not a cli flag
            return;
          }
          const flag = `--${inputKey.replace(/_/g, "-")}`;
          if (inputValue === "true") {
            expect(orcaCliArgs).toContain(flag);
            expect(orcaCliArgs).not.toContain(
              `${flag}${delimiter}${inputValue}`,
            );
          } else {
            expect(orcaCliArgs).toContain(`${flag}${delimiter}${inputValue}`);
          }
        },
      );
    });

    test("empty optional inputs", () => {
      let testInputs = mockRequiredInputs();
      const result = executeEntrypoint(testInputs);
      let cliArgs = extractOrcaCliArgs(result);
      expect(cliArgs).toEqual(
        `--project-key ${testInputs.project_key.value} iac scan --path ${testInputs.path.value} --format cli,json --output orca_results/ --console-output=cli`,
      );
    });

    test("adds json format when not specified", () => {
      const testInputs = {
        ...mockRequiredInputs(),
        format: { value: "test-format" },
      };
      let results = executeEntrypoint(testInputs);
      expect(results).toContain("--format test-format,json ");
    });

    test("preserves json format when already specified", () => {
      const testInputs = {
        ...mockRequiredInputs(),
        format: { value: "test-format,json" },
      };
      let results = executeEntrypoint(testInputs);
      expect(results).toContain("--format test-format,json ");
    });

    test("sets default format to cli,json when no format specified", () => {
      const testInputs = mockRequiredInputs();
      let results = executeEntrypoint(testInputs);
      expect(results).toContain("--format cli,json ");
    });

    test("handles output directory without format", () => {
      const testInputs = {
        ...mockRequiredInputs(),
        output: { value: testResultsPath },
      };
      const results = executeEntrypoint(testInputs);
      expect(results).toContain("--format cli,json");
      expect(results).toContain(`--output ${testResultsPath}`);
    });

    describe("Error Handling", () => {
      test.each([
        ["path", "Path must be provided"],
        ["api_token", "api_token must be provided"],
        ["project_key", "project_key must be provided"],
      ])("validates required input %s", (input, errorMessage) => {
        const testInputs = mockRequiredInputs();
        delete testInputs[input];

        expect(() => executeEntrypoint(testInputs)).toThrow(errorMessage);
      });

      test("validates path input format", () => {
        const testInputs = {
          ...mockRequiredInputs(),
          path: { value: "/absolute/path" },
        };
        expect(() => executeEntrypoint(testInputs)).toThrow(
          /Path shouldn't be absolute./,
        );
      });

      test("validates output directory format", () => {
        const testInputs = {
          ...mockRequiredInputs(),
          output: { value: "results" },
        };
        expect(() => executeEntrypoint(testInputs)).toThrow(
          /Output must be a folder \(end with \/\)/,
        );
      });
    });

    function mockRequiredInputs() {
      return {
        path: { value: "./src" },
        api_token: { value: "test-token" },
        project_key: { value: "test-project" },
        show_annotations: { value: "false" },
      };
    }

    function setupEnvVars(testInputs) {
      Object.entries(testInputs).forEach(([key, { value }]) => {
        process.env[`INPUT_${key.toUpperCase()}`] = value;
      });
    }

    function executeEntrypoint(testInputs) {
      setupEnvVars(testInputs);

      const result = spawnSync(testEntrypoint, {
        env: process.env,
        stdio: "pipe",
        shell: false,
      });

      if (result.error) {
        throw result.error;
      }
      if (result.status !== 0) {
        throw new Error(result.stdout.toString());
      }
      return result.stdout.toString();
    }

    function extractOrcaCliArgs(result) {
      const matches = result.toString().match(/mock-orca-cli (.*)/);
      return matches ? matches[1] : "";
    }
  });
});
