#!/usr/bin/env node

const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function takeScreenshot(name) {
  const timestamp = Date.now();
  const path = `/Users/stuartkerr/Code/dotfiles-installer-1/playwright-screenshots/watch-${name}-${timestamp}.png`;
  await execAsync(`screencapture -x "${path}"`);
  return path;
}

async function watchCodespaceCreation() {
  console.log('\n╔═══════════════════════════════════════════════════════════════════╗');
  console.log('║       WATCHING CODESPACE CREATION IN YOUR CHROME                 ║');
  console.log('╚═══════════════════════════════════════════════════════════════════╝\n');

  const startTime = Date.now();

  // Create codespace
  console.log('Creating fresh codespace...');
  const { stdout: createOutput } = await execAsync(
    'gh codespace create --repo stuinfla/BWEconstruction --branch main --machine basicLinux32gb',
    { timeout: 120000 }
  );

  // Extract codespace name (last line of output)
  const codespaceId = createOutput.trim().split('\n').pop();
  console.log(`✅ Created: ${codespaceId}\n`);

  // Get codespace details including URL
  const { stdout: detailsJson } = await execAsync(`gh codespace view -c ${codespaceId} --json name,vscsTarget`);
  const details = JSON.parse(detailsJson);
  const codespaceUrl = `https://${details.name}.github.dev`;

  console.log('Opening in Chrome...');
  await execAsync(`osascript -e 'tell application "Google Chrome" to activate' -e 'tell application "Google Chrome" to open location "${codespaceUrl}"'`);
  
  await sleep(5000);
  console.log(`✅ Opened: ${codespaceUrl}\n`);
  
  // Take screenshots every 10 seconds for 15 minutes
  console.log('📸 Taking screenshots every 10 seconds (15 minutes)...\n');

  for (let i = 0; i < 90; i++) {
    const elapsed = Math.floor((Date.now() - startTime) / 1000);
    const minutes = Math.floor(elapsed / 60);
    const seconds = elapsed % 60;
    
    console.log(`[${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}] Screenshot ${i + 1}/90`);
    
    await takeScreenshot(`${String(i + 1).padStart(3, '0')}`);
    
    // Check installation status
    try {
      const { stdout: status } = await execAsync(
        `gh codespace ssh -c ${codespaceId} -- 'tail -3 /workspaces/*/DOTFILES-INSTALLATION-STATUS.txt 2>/dev/null || echo "INSTALLING"'`,
        { timeout: 10000 }
      );
      
      if (status.includes('COMPLETE')) {
        console.log(`         ✅ Installation complete!`);
      } else if (status.includes('STEP')) {
        console.log(`         ${status.match(/STEP \d\/\d/)?.[0]}`);
      }
    } catch {}
    
    await sleep(10000);
  }

  console.log('\n\n✅ Monitoring complete!');
  console.log(`\nTo delete: gh codespace delete -c ${codespaceId}\n`);
}

watchCodespaceCreation().catch(error => {
  console.error('ERROR:', error.message);
  process.exit(1);
});
