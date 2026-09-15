import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const cjs = require("../dist/index.js");
const esm = await import(new URL("../dist/index.mjs", import.meta.url).href);

for (const [format, exports] of [
  ["CommonJS", cjs],
  ["ES module", esm],
]) {
  for (const name of ["ConfigManager", "EnvConfigSource", "FileConfigSource"]) {
    if (typeof exports[name] !== "function") {
      throw new Error(`${format} build is missing ${name}`);
    }
  }
}

const source = new esm.EnvConfigSource("CONFT_SMOKE_");
if (source.name !== "env" || source.isWritable() !== false) {
  throw new Error("Built EnvConfigSource contract is invalid");
}

console.log("package smoke passed: CJS + ESM exports and adapter contract");
