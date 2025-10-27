#!/usr/bin/env node

/**
 * REAL-TIME USER EXPERIENCE MONITOR
 * Watches YOUR Chrome and takes screenshots to see exactly what you see
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;

const execAsync = promisify(exec);

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function takeScreenshot(name, timestamp) {
  const path = `/Users/stuartkerr/Code/dotfiles-installer-1/playwright-screenshots/user-${name}-${timestamp}.png`;
  await execAsync(`screencapture -x "${path}"`);
  return path;
}

async function getCurrentChromeUrl() {
  try {
    const script = `
      tell application "Google Chrome"
        if (count of windows) > 0 then
          set activeTab to active tab of front window
          return URL of activeTab
        else
          return "NO_WINDOWS"
        end if
      end tell
    `;
    const { stdout } = await execAsync(`osascript -e '${script}'`);
    return stdout.trim();
  } catch {
    return "ERROR";
  }
}

async function monitorUserExperience() {
  const startTime = Date.now();
  const screenshots = [];

  console.log('\n⏱️  MONITORING YOUR CODESPACE CREATION\n');
  console.log('Started: 8:57 AM ET');
  console.log('Taking screenshots every 15 seconds...\n');

  // Monitor for 10 minutes
  for (let i = 0; i < 40; i++) {
    const elapsed = Math.floor((Date.now() - startTime) / 1000);
    const minutes = Math.floor(elapsed / 60);
    const seconds = elapsed % 60;

    console.log(`${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')} - Taking screenshot...`);

    const url = await getCurrentChromeUrl();
    const isCodespace = url.includes('github.dev');
    console.log(`  URL: ${isCodespace ? 'github.dev (codespace)' : url.substring(0, 50)}`);

    const screenshot = await takeScreenshot(`${String(i + 1).padStart(3, '0')}`, Date.now());
    screenshots.push({ time: `${minutes}:${seconds}`, path: screenshot, url });

    if (i < 39) {
      await sleep(15000); // 15 seconds
    }
  }

  console.log('\n📸 Screenshots saved to:');
  console.log('/Users/stuartkerr/Code/dotfiles-installer-1/playwright-screenshots/\n');

  console.log('Screenshot timeline:');
  screenshots.forEach(s => {
    const filename = s.path.split('/').pop();
    console.log(`  ${s.time} - ${filename}`);
  });
}

monitorUserExperience();
