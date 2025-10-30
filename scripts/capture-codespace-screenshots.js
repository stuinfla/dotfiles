#!/usr/bin/env node
/**
 * Simple screenshot capture for codespace testing
 * Takes screenshots every 15 seconds for 10 minutes
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const CODESPACE_URL = process.argv[2];
const SCREENSHOT_DIR = path.join(__dirname, '..', 'validation-screenshots');
const DURATION_MINUTES = 10;
const INTERVAL_SECONDS = 15;

if (!CODESPACE_URL) {
  console.error('Usage: node capture-codespace-screenshots.js <codespace-url>');
  process.exit(1);
}

async function main() {
  console.log('╔═══════════════════════════════════════════════════╗');
  console.log('║   CODESPACE INSTALLATION VISUAL VALIDATION        ║');
  console.log('╚═══════════════════════════════════════════════════╝\n');

  // Create screenshot directory
  if (!fs.existsSync(SCREENSHOT_DIR)) {
    fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
  }

  console.log(`📸 Screenshots will be saved to: ${SCREENSHOT_DIR}`);
  console.log(`🌐 Opening: ${CODESPACE_URL}\n`);

  // Launch browser
  const browser = await chromium.launch({
    headless: false,
    channel: 'chrome'
  });

  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 }
  });

  const page = await context.newPage();

  // Navigate to codespace
  console.log('⏳ Loading codespace...');
  await page.goto(CODESPACE_URL, {
    waitUntil: 'networkidle',
    timeout: 120000
  });

  console.log('✅ Codespace loaded\n');
  console.log(`📸 Taking screenshots every ${INTERVAL_SECONDS}s for ${DURATION_MINUTES} minutes...\n`);

  const totalScreenshots = (DURATION_MINUTES * 60) / INTERVAL_SECONDS;
  const findings = {
    statusFileVisible: false,
    statusFileTimestamp: null,
    screenshots: []
  };

  for (let i = 0; i < totalScreenshots; i++) {
    const elapsedSeconds = i * INTERVAL_SECONDS;
    const minutes = Math.floor(elapsedSeconds / 60);
    const seconds = elapsedSeconds % 60;
    const timeStr = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

    console.log(`[${timeStr}] Screenshot ${i + 1}/${totalScreenshots}`);

    const filename = `${Date.now()}-${timeStr.replace(':', 'm')}s.png`;
    const filepath = path.join(SCREENSHOT_DIR, filename);

    await page.screenshot({
      path: filepath,
      fullPage: false
    });

    // Check for status file in Explorer
    try {
      const statusFileVisible = await page.locator('[aria-label*="DOTFILES-INSTALLATION-STATUS"]').isVisible({ timeout: 1000 });
      if (statusFileVisible && !findings.statusFileVisible) {
        findings.statusFileVisible = true;
        findings.statusFileTimestamp = timeStr;
        console.log(`   🎯 STATUS FILE APPEARED AT ${timeStr}!`);
      }
    } catch (e) {
      // File not visible yet
    }

    findings.screenshots.push({
      timestamp: timeStr,
      filename,
      statusFileVisible: findings.statusFileVisible
    });

    await page.waitForTimeout(INTERVAL_SECONDS * 1000);
  }

  console.log('\n✅ Screenshot capture complete!\n');

  // Generate report
  const report = `
╔═══════════════════════════════════════════════════════════════════╗
║                   INSTALLATION VALIDATION REPORT                  ║
╚═══════════════════════════════════════════════════════════════════╝

Test Duration: ${DURATION_MINUTES} minutes
Screenshots Taken: ${findings.screenshots.length}

FINDINGS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status File Visibility:
  ${findings.statusFileVisible ? '✅' : '❌'} Status file appeared: ${findings.statusFileVisible ? findings.statusFileTimestamp : 'NEVER'}

Screenshots Directory: ${SCREENSHOT_DIR}/
Total Screenshots: ${findings.screenshots.length}

${findings.statusFileVisible
  ? `✅ SUCCESS: Status file visible within ${findings.statusFileTimestamp}`
  : '❌ FAILURE: Status file never appeared in VS Code Explorer'
}

Test completed at: ${new Date().toISOString()}
`;

  console.log(report);

  // Save report
  fs.writeFileSync(
    path.join(SCREENSHOT_DIR, 'validation-report.txt'),
    report
  );

  await browser.close();

  process.exit(findings.statusFileVisible ? 0 : 1);
}

main().catch(error => {
  console.error('❌ Test failed:', error);
  process.exit(1);
});
