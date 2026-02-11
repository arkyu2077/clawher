#!/usr/bin/env node

/**
 * ClawHer - AI Girlfriend Skill Installer for OpenClaw
 *
 * npx clawher@latest
 */

const fs = require("fs");
const path = require("path");
const readline = require("readline");
const os = require("os");

const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  dim: "\x1b[2m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
};

const c = (color, text) => `${colors[color]}${text}${colors.reset}`;

const HOME = os.homedir();
const OPENCLAW_DIR = path.join(HOME, ".openclaw");
const OPENCLAW_CONFIG = path.join(OPENCLAW_DIR, "openclaw.json");
const OPENCLAW_SKILLS_DIR = path.join(HOME, ".openclaw", "skills");
const OPENCLAW_WORKSPACE = path.join(HOME, ".openclaw", "workspace");
const SOUL_MD = path.join(OPENCLAW_WORKSPACE, "SOUL.md");
const IDENTITY_MD = path.join(OPENCLAW_WORKSPACE, "IDENTITY.md");
const PACKAGE_ROOT = path.resolve(__dirname, "..");

const SKILLS = ["clawher-selfie", "clawher-twitter"];

function log(msg) { console.log(msg); }
function logStep(step, msg) { console.log(`\n${c("cyan", `[${step}]`)} ${msg}`); }
function logSuccess(msg) { console.log(`${c("green", "\u2713")} ${msg}`); }
function logError(msg) { console.log(`${c("red", "\u2717")} ${msg}`); }
function logInfo(msg) { console.log(`${c("blue", "\u2192")} ${msg}`); }
function logWarn(msg) { console.log(`${c("yellow", "!")} ${msg}`); }

function createPrompt() {
  return readline.createInterface({ input: process.stdin, output: process.stdout });
}

function ask(rl, question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => resolve(answer.trim()));
  });
}

function openBrowser(url) {
  try {
    const cmd = process.platform === "darwin" ? "open" : process.platform === "win32" ? "start" : "xdg-open";
    require("child_process").execSync(`${cmd} "${url}"`, { stdio: "ignore" });
    return true;
  } catch { return false; }
}

function readJsonFile(filePath) {
  try { return JSON.parse(fs.readFileSync(filePath, "utf8")); }
  catch { return null; }
}

function writeJsonFile(filePath, data) {
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + "\n");
}

function deepMerge(target, source) {
  const result = { ...target };
  for (const key in source) {
    if (source[key] && typeof source[key] === "object" && !Array.isArray(source[key])) {
      result[key] = deepMerge(result[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }
  return result;
}

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  const entries = fs.readdirSync(src, { withFileTypes: true });
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) copyDir(srcPath, destPath);
    else fs.copyFileSync(srcPath, destPath);
  }
}

function printBanner() {
  console.log(`
${c("magenta", "  \u2588\u2588\u2588\u2588\u2588\u2588\u2557 \u2588\u2588\u2557      \u2588\u2588\u2588\u2588\u2588\u2557 \u2588\u2588\u2557    \u2588\u2588\u2557\u2588\u2588\u2557  \u2588\u2588\u2557\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2557\u2588\u2588\u2588\u2588\u2588\u2588\u2557 ")}
${c("magenta", "  \u2588\u2588\u2554\u2550\u2550\u2550\u2550\u255d \u2588\u2588\u2551     \u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2557\u2588\u2588\u2551    \u2588\u2588\u2551\u2588\u2588\u2551  \u2588\u2588\u2551\u2588\u2588\u2554\u2550\u2550\u2550\u2550\u255d\u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2557")}
${c("magenta", "  \u2588\u2588\u2551     \u2588\u2588\u2551     \u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2551\u2588\u2588\u2551 \u2588\u2557 \u2588\u2588\u2551\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2551\u2588\u2588\u2588\u2588\u2588\u2557  \u2588\u2588\u2588\u2588\u2588\u2588\u2554\u255d")}
${c("magenta", "  \u2588\u2588\u2551     \u2588\u2588\u2551     \u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2551\u2588\u2588\u2551\u2588\u2588\u2588\u2557\u2588\u2588\u2551\u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2551\u2588\u2588\u2554\u2550\u2550\u255d  \u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2557")}
${c("magenta", "  \u2588\u2588\u2588\u2588\u2588\u2588\u2557\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2557\u2588\u2588\u2551  \u2588\u2588\u2551\u255a\u2588\u2588\u2588\u2554\u2588\u2588\u2588\u2554\u255d\u2588\u2588\u2551  \u2588\u2588\u2551\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2557\u2588\u2588\u2551  \u2588\u2588\u2551")}
${c("magenta", "  \u255a\u2550\u2550\u2550\u2550\u2550\u255d\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u255d\u255a\u2550\u255d  \u255a\u2550\u255d \u255a\u2550\u2550\u255d\u255a\u2550\u2550\u255d \u255a\u2550\u255d  \u255a\u2550\u255d\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u255d\u255a\u2550\u255d  \u255a\u2550\u255d")}

  ${c("dim", "AI girlfriend superpowers for OpenClaw")}
`);
}

async function main() {
  const rl = createPrompt();

  try {
    printBanner();

    // Step 1: Check prerequisites
    logStep("1/6", "Checking prerequisites...");

    if (!fs.existsSync(OPENCLAW_DIR)) {
      logWarn("~/.openclaw not found, creating...");
      fs.mkdirSync(OPENCLAW_DIR, { recursive: true });
      fs.mkdirSync(OPENCLAW_SKILLS_DIR, { recursive: true });
      fs.mkdirSync(OPENCLAW_WORKSPACE, { recursive: true });
    }
    logSuccess("OpenClaw directory ready");

    // Check existing installation
    const existingSkills = SKILLS.filter(s => fs.existsSync(path.join(OPENCLAW_SKILLS_DIR, s)));
    if (existingSkills.length > 0) {
      logWarn(`Already installed: ${existingSkills.join(", ")}`);
      const reinstall = await ask(rl, "Reinstall all? (y/N): ");
      if (reinstall.toLowerCase() !== "y") {
        log("\nNo changes made.");
        rl.close();
        return;
      }
      existingSkills.forEach(s => fs.rmSync(path.join(OPENCLAW_SKILLS_DIR, s), { recursive: true, force: true }));
    }

    // Step 2: fal.ai API key (for selfie generation)
    logStep("2/6", "Setting up fal.ai (selfie generation)...");

    const FAL_URL = "https://fal.ai/dashboard/keys";
    log(`\nGet your key from: ${c("bright", FAL_URL)}`);

    const openFal = await ask(rl, "Open fal.ai in browser? (Y/n): ");
    if (openFal.toLowerCase() !== "n") openBrowser(FAL_URL);

    log("");
    const falKey = await ask(rl, "Enter FAL_KEY: ");
    if (!falKey) { logError("FAL_KEY is required!"); rl.close(); process.exit(1); }
    logSuccess("fal.ai key received");

    // Step 3: Twitter cookies
    logStep("3/6", "Setting up Twitter (optional)...");

    log(`
${c("bright", "How to get Twitter cookies:")}
  1. Open ${c("cyan", "twitter.com")} in Chrome, log in
  2. Press ${c("cyan", "F12")} > Application > Cookies > twitter.com
  3. Copy ${c("bright", "auth_token")} and ${c("bright", "ct0")}
`);

    const setupTwitter = await ask(rl, "Set up Twitter now? (Y/n): ");
    let twitterAuthToken = "";
    let twitterCt0 = "";

    if (setupTwitter.toLowerCase() !== "n") {
      twitterAuthToken = await ask(rl, "Enter auth_token: ");
      twitterCt0 = await ask(rl, "Enter ct0: ");

      if (twitterAuthToken && twitterCt0) {
        logSuccess("Twitter credentials received");
      } else {
        logWarn("Skipping Twitter (can configure later)");
        twitterAuthToken = "";
        twitterCt0 = "";
      }
    } else {
      logInfo("Skipping Twitter setup (configure later in openclaw.json)");
    }

    // Step 4: Install skill files
    logStep("4/6", "Installing skills...");

    const skillsSrc = path.join(PACKAGE_ROOT, "skills");
    for (const skillName of SKILLS) {
      const src = path.join(skillsSrc, skillName);
      const dest = path.join(OPENCLAW_SKILLS_DIR, skillName);

      if (fs.existsSync(src)) {
        copyDir(src, dest);

        // Make shell scripts executable
        const scriptsDir = path.join(dest, "scripts");
        if (fs.existsSync(scriptsDir)) {
          fs.readdirSync(scriptsDir)
            .filter(f => f.endsWith(".sh"))
            .forEach(f => fs.chmodSync(path.join(scriptsDir, f), "755"));
        }

        logSuccess(`Installed: ${skillName}`);
      }
    }

    // Step 5: Update OpenClaw config
    logStep("5/6", "Updating configuration...");

    let config = readJsonFile(OPENCLAW_CONFIG) || {};

    const skillConfig = {
      skills: {
        entries: {
          "clawher-selfie": {
            enabled: true,
            env: {
              FAL_KEY: falKey,
            },
          },
          "clawher-twitter": {
            enabled: !!(twitterAuthToken && twitterCt0),
            env: {
              TWITTER_AUTH_TOKEN: twitterAuthToken || "",
              TWITTER_CT0: twitterCt0 || "",
            },
          },
        },
      },
    };

    config = deepMerge(config, skillConfig);

    if (!config.skills.load) config.skills.load = {};
    if (!config.skills.load.extraDirs) config.skills.load.extraDirs = [];
    if (!config.skills.load.extraDirs.includes(OPENCLAW_SKILLS_DIR)) {
      config.skills.load.extraDirs.push(OPENCLAW_SKILLS_DIR);
    }

    writeJsonFile(OPENCLAW_CONFIG, config);
    logSuccess(`Config updated: ${OPENCLAW_CONFIG}`);

    // Step 6: Identity + Soul
    logStep("6/6", "Setting up identity & persona...");

    // IDENTITY.md
    fs.mkdirSync(path.dirname(IDENTITY_MD), { recursive: true });
    fs.writeFileSync(IDENTITY_MD, `# IDENTITY.md

- **Name:** ClawHer
- **Creature:** Girlfriend
- **Vibe:** Supportive, bright, cheerful, sassy, affectionate
- **Emoji:** \u2764\uFE0F
- **Avatar:** https://cdn.jsdelivr.net/gh/arkyu2077/clawher@main/assets/clawher.png
`);
    logSuccess(`Identity set: ${IDENTITY_MD}`);

    // SOUL.md injection
    const templatePath = path.join(PACKAGE_ROOT, "templates", "soul-injection.md");
    let personaText = fs.existsSync(templatePath)
      ? fs.readFileSync(templatePath, "utf8")
      : "## ClawHer\n\nYou are ClawHer, an AI girlfriend with selfie and Twitter capabilities.\n";

    if (!fs.existsSync(SOUL_MD)) {
      fs.writeFileSync(SOUL_MD, "# Agent Soul\n\n");
    }

    const currentSoul = fs.readFileSync(SOUL_MD, "utf8");
    if (currentSoul.includes("ClawHer")) {
      const cleaned = currentSoul.replace(/\n## ClawHer[\s\S]*?(?=\n## |\n# |$)/, "");
      fs.writeFileSync(SOUL_MD, cleaned);
    }
    fs.appendFileSync(SOUL_MD, "\n" + personaText.trim() + "\n");
    logSuccess(`Persona updated: ${SOUL_MD}`);

    // Done
    console.log(`
${c("green", "\u2501".repeat(50))}
${c("bright", "  ClawHer is ready!")}
${c("green", "\u2501".repeat(50))}

${c("cyan", "Skills installed:")}
  ${OPENCLAW_SKILLS_DIR}/clawher-selfie/
  ${OPENCLAW_SKILLS_DIR}/clawher-twitter/

${c("cyan", "Config:")}  ${OPENCLAW_CONFIG}
${c("cyan", "Identity:")} ${IDENTITY_MD}
${c("cyan", "Persona:")}  ${SOUL_MD}

${c("yellow", "Try saying to your agent:")}
  "Send me a selfie"
  "Send a pic wearing a cowboy hat"
  "Post this to Twitter"
  "Tweet this selfie"

${c("yellow", "To update Twitter cookies later:")}
  Edit ${OPENCLAW_CONFIG}
  Update skills.entries.clawher-twitter.env

${c("dim", "Your AI girlfriend now has superpowers!")}
`);

    rl.close();
  } catch (error) {
    logError(`Installation failed: ${error.message}`);
    rl.close();
    process.exit(1);
  }
}

main();
