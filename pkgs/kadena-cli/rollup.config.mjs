import commonjs from "@rollup/plugin-commonjs";
import json from "@rollup/plugin-json";
import resolve from "@rollup/plugin-node-resolve";

export default {
  input: "node_modules/@kadena/kadena-cli/lib/index.js",
  output: {
    file: "./lib/cli.mjs",
    format: "es",
    intro: "const navigator = {};",
    entryFileNames: "[name].mjs",
    chunkFileNames: "[name].mjs",
    inlineDynamicImports: true,
  },
  plugins: [resolve(), commonjs(), json()],
};