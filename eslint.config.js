const js = require("@eslint/js");

module.exports = [
  {
    // Global ignores
    ignores: ["dist/**"],
  },
  {
    // Base configuration
    files: ["**/*.{js}"],
    settings: {
      "import/resolver": {
        typescript: {},
      },
    },
    rules: {
      ...js.configs.recommended.rules,

      // Spacing and formatting rules
      "space-before-blocks": "error",
      "keyword-spacing": "error",
      "no-trailing-spaces": "error",
      curly: "error",
      quotes: ["error", "single"],
      "object-curly-spacing": ["error", "always"],
      "no-multi-spaces": "error",
      "semi-spacing": "error",

      // Code style rules
      "prefer-const": ["error", { destructuring: "all" }],
      "max-classes-per-file": ["error", 10],
      "max-len": ["error", 200],

      // Import rules
      "import/no-unresolved": [
        "error",
        { commonjs: true, caseSensitive: true },
      ],
      "import/extensions": ["error", "ignorePackages", { js: "never" }],
    },
  },
  {
    // Test files override
    files: ["**/test/**"],
    rules: {
      "import/no-unresolved": "off",
      "import/extensions": "off",
    },
  },
];
