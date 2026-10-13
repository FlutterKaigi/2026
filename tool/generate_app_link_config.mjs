import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const originNames = {
  officialWebsiteHost: "officialWebsiteOrigin",
  productionAppHost: "productionAppOrigin",
  stagingAppHost: "stagingAppOrigin",
};
const hostnamePattern = /^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/;

function readHosts(root) {
  const hosts = JSON.parse(readFileSync(resolve(root, "tool/app_link_hosts.json"), "utf8"));
  if (Object.keys(hosts).sort().join() !== Object.keys(originNames).sort().join()) {
    throw new Error("app_link_hosts.json must contain exactly the documented host keys");
  }
  for (const [key, value] of Object.entries(hosts)) {
    if (typeof value !== "string" || value.length > 253 || !hostnamePattern.test(value)) {
      throw new Error(`${key} must be a lowercase DNS hostname without scheme, port or path`);
    }
  }
  if (new Set(Object.values(hosts)).size !== Object.keys(hosts).length) {
    throw new Error("Website, production and staging hosts must be distinct");
  }
  return hosts;
}

function generatedFiles(hosts) {
  const header = "// Generated from tool/app_link_hosts.json. Do not edit.\n"
    + "// Regenerate: node tool/generate_app_link_config.mjs\n\n";
  const entries = Object.entries(originNames);
  return {
    "packages/data/lib/src/app_link_origins.dart": header
      + entries.map(([key, name]) => `const ${name} = 'https://${hosts[key]}';\n`).join(""),
    "tool/app_link_origins.mjs": header
      + entries.map(([key, name]) => `export const ${name} = "https://${hosts[key]}";\n`).join(""),
    "apps/website/lib/constants/generated_link_origins.dart": header
      + `const officialWebsiteOrigin = 'https://${hosts.officialWebsiteHost}';\n`,
  };
}

function main() {
  const args = process.argv.slice(2);
  const rootIndex = args.indexOf("--root");
  const root = rootIndex < 0
    ? fileURLToPath(new URL("../", import.meta.url))
    : args[rootIndex + 1];
  if (!root || args.some((arg, index) => arg !== "--check" && arg !== "--root" && !(rootIndex >= 0 && index === rootIndex + 1))) {
    throw new Error("Usage: node tool/generate_app_link_config.mjs [--check] [--root directory]");
  }
  const check = args.includes("--check");
  const files = generatedFiles(readHosts(root));
  const stale = Object.entries(files).filter(([path, content]) => {
    const target = resolve(root, path);
    return !existsSync(target) || readFileSync(target, "utf8") !== content;
  });
  if (check && stale.length > 0) {
    throw new Error(`Regenerate app link configuration:\n${stale.map(([path]) => path).join("\n")}`);
  }
  if (!check) {
    for (const [path, content] of stale) {
      const target = resolve(root, path);
      mkdirSync(dirname(target), { recursive: true });
      writeFileSync(target, content);
    }
  }
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
