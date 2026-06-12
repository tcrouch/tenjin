const eslintPluginPrettierRecommended = require("eslint-plugin-prettier/recommended");

module.exports = [
  {
    languageOptions: {
      ecmaVersion: 2022,
    },
    rules: {
      "prefer-const": "error",
    },
    files: ["**/*.js", "**/*.mjs"],
  },
  eslintPluginPrettierRecommended,
];
