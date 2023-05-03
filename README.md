# Orca Shift Left Security Action

[GitHub Action](https://github.com/features/actions)
for [Orca Shift Left Security](https://orca.security/solutions/shift-left-security/)

#### More info can be found in the official Orca Shift Left Security<a href="https://docs.orcasecurity.io/v1/docs/shift-left-security"> documentation</a>



## Table of Contents

- [Usage](#usage)
    - [Workflow](#workflow)
    - [Inputs](#inputs)
- [Annotations](#annotations)
- [Upload SARIF report](#upload-sarif-report)


## Usage

### Workflow

```yaml
name: Sample Orca IaC Scan Workflow
on:
  # Trigger the workflow on push request,
  # but only for the main branch
  push:
    branches:
      - main
jobs:
  orca-iac_scan:
    name: Orca IaC Scan
    runs-on: ubuntu-latest
    env:
      PROJECT_KEY: <project key> # Set the desired project to run the cli scanning with
    steps:
      # Checkout your repository under $GITHUB_WORKSPACE, so your job can access it
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Run Orca IaC Scan
        uses: orcasecurity/shiftleft-iac-action@v1
        with:
          api_token: ${{ secrets.ORCA_SECURITY_API_TOKEN }}
          project_key: ${{ env.PROJECT_KEY }}
          path:
            # scanning directories: ./terraform/ ./sub-dir/ and a file: ./Dockerfile
            "terraform,sub-dir,other-sub-dir/Dockerfile"
```

### Inputs

| Variable            | Example Value &nbsp;                       | Description &nbsp;                                                                                      | Type    | Required | Default                       |
|---------------------|--------------------------------------------|---------------------------------------------------------------------------------------------------------|---------|----------|-------------------------------|
| api_token           |                                            | Orca API Token used for Authentication                                                                  | String  | Yes      | N/A                           |
| project_key         | my-project-key                             | Project Key name                                                                                        | String  | Yes      | N/A                           |
| path                | terraform,sub-dir,other-sub-dir/Dockerfile | Paths or directories to scan (comma-separated)                                                          | String  | Yes      | N/A                           |
| exclude_paths       | ./notToBeScanned/,example.tf               | List of paths to be excluded from scan (comma-separated)                                                | String  | No       | N/A                           |
| format              | json                                       | Format for displaying the results                                                                       | String  | No       | cli                           |
| output              | results/                                   | Output directory for scan results                                                                       | String  | No       | N/A                           |
| platform            | Terraform,CloudFormation                   | Limit scan to the specified list of platforms (comma-separated)                                         | String  | No       | All supported platforms       |
| cloud_provider      | aws,gcp                                    | Limit scan to the specified list of cloud providers                                                     | String  | No       | All supported cloud providers |
| no_color            | false                                      | Disable color output                                                                                    | Boolean | No       | false                         |
| exit_code           | 10                                         | Exit code for failed execution due to policy violations                                                 | Integer | No       | 3                             |
| control_timeout     | 30                                         | Number of seconds the control has to execute before being canceled                                      | Integer | No       | 60                            |
| silent              | false                                      | Disable logs and warnings output                                                                        | Boolean | No       | false                         |
| console_output      | json                                       | Prints results to console in the provided format (only when --output is provided)                       | String  | No       | cli                           |
| config              | config.json                                | path to configuration file (json, yaml or toml)                                                         | String  | No       | N/A                           |
| show_annotations    | true                                       | show github annotations on pull requests                                                                | Boolean | No       | true                          |
| custom_controls     | ./custom_control1/,./custom_control2       | paths to custom controls (comma-separated)                                                              | String  | No       | N/A                           |
| generate_rego_input | ./input.json                               | Generates an internal representation of scanned files, which can be utilized as input for Rego policies | String  | No       | N/A                           |


## Annotations
After scanning, the action will add the results as annotations in a pull request:

![](/assets/annotations_preview.png)
>  **NOTE:**  Annotations can be disabled by setting the "show_annotation" input to "false"


## Upload SARIF report
If you have [GitHub code scanning](https://docs.github.com/en/github/finding-security-vulnerabilities-and-errors-in-your-code/about-code-scanning) available you can use Orca Shift Left Security as a scanning tool
> **NOTE:**  Code scanning is available for all public repositories. Code scanning is also available in private repositories owned by organizations that use GitHub Enterprise Cloud and have a license for GitHub Advanced Security.

Configuration:

```yaml
name: Scan and upload SARIF

push:
  branches:
    - main

jobs:
  orca-iac_scan:
    name: Orca IaC Scan
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    env:
      PROJECT_KEY: <project key> # Set the desired project to run the cli scanning with
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Run Orca IaC Scan
        uses: orcasecurity/shiftleft-iac-action@v1
        with:
          api_token: ${{ secrets.ORCA_SECURITY_API_TOKEN }}
          project_key: ${{ env.PROJECT_KEY }}
          path: <path to scan>
          format: "sarif"
          output:
            "results/"
      - name: Upload SARIF file
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: results/iac.sarif
```

The results list can be found on the security tab of your GitHub project and should look like the following image

![](/assets/code_scanning.png)

An entry should describe the error and in which line it occurred 

![](/assets/code_scanning_alert.png)
