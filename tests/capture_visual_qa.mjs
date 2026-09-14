import { access, mkdir } from "node:fs/promises";
import { spawn } from "node:child_process";
import { chromium } from "playwright-core";

const candidates = [
  process.env.CHROME_PATH,
  "/usr/bin/google-chrome",
  "/usr/bin/google-chrome-stable",
  "/usr/bin/chromium",
].filter(Boolean);

let executablePath = "";
for (const candidate of candidates) {
  try {
    await access(candidate);
    executablePath = candidate;
    break;
  } catch {
    // Try the next runner-provided browser.
  }
}
if (!executablePath) {
  throw new Error("No Chrome or Chromium executable found for visual QA");
}

await mkdir("artifacts/visual-qa", { recursive: true });
const server = spawn("python3", ["-m", "http.server", "8060", "--directory", "dist/web"], {
  stdio: "inherit",
});

const browser = await chromium.launch({
  executablePath,
  headless: true,
  args: ["--no-sandbox", "--disable-dev-shm-usage"],
});

for (let attempt = 0; attempt < 50; attempt += 1) {
  try {
    const response = await fetch("http://127.0.0.1:8060");
    if (response.ok) break;
  } catch {
    if (attempt === 49) throw new Error("Visual QA web server did not start");
  }
  await new Promise((resolve) => setTimeout(resolve, 100));
}

async function capture(name, options) {
  const context = await browser.newContext(options);
  const page = await context.newPage();
  await page.goto("http://127.0.0.1:8060", { waitUntil: "networkidle" });
  const canvas = page.locator("canvas");
  await canvas.waitFor({ state: "visible", timeout: 30_000 });
  await page.waitForTimeout(1_500);
  await page.screenshot({ path: `artifacts/visual-qa/${name}-hub.png` });
  await canvas.click({ position: { x: 16, y: 16 } });
  await page.keyboard.press("Enter");
  await page.waitForTimeout(1_500);
  await page.screenshot({ path: `artifacts/visual-qa/${name}-gameplay.png` });
  await context.close();
}

try {
  await capture("desktop-960x640", {
    viewport: { width: 960, height: 640 },
    screen: { width: 960, height: 640 },
  });
  await capture("portrait-390x844", {
    viewport: { width: 390, height: 844 },
    screen: { width: 390, height: 844 },
    hasTouch: true,
    isMobile: true,
    userAgent: "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/128 Mobile Safari/537.36",
  });
} finally {
  await browser.close();
  server.kill("SIGTERM");
}
