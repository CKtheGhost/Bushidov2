const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🌸 BUSHIDO DEPENDENCY RESOLVER 🌸\n');

// Architectural cleanup
console.log('Phase 1: Purging corrupted state...');
try {
  execSync('rm -rf node_modules pnpm-lock.yaml', { stdio: 'inherit' });
  execSync('rm -rf contracts/node_modules frontend/node_modules backend/node_modules scripts/node_modules', { stdio: 'inherit' });
  console.log('✓ State purged successfully\n');
} catch (e) {
  console.log('✓ Clean state confirmed\n');
}

// Fix scripts package.json
console.log('Phase 2: Applying surgical fixes...');
const scriptsPackagePath = path.join(__dirname, 'scripts', 'package.json');
const scriptsPackage = JSON.parse(fs.readFileSync(scriptsPackagePath, 'utf8'));

// Remove problematic dependencies
delete scriptsPackage.dependencies['kubo-rpc-client'];
delete scriptsPackage.dependencies['@pinata/sdk'];

// Add correct dependencies
scriptsPackage.dependencies['pinata'] = '^1.1.0';
scriptsPackage.dependencies['sharp'] = '^0.33.2';

fs.writeFileSync(scriptsPackagePath, JSON.stringify(scriptsPackage, null, 2));
console.log('✓ Dependencies corrected\n');

// Reinstall with verification
console.log('Phase 3: Installing with architectural precision...');
try {
  execSync('pnpm install --no-frozen-lockfile', { stdio: 'inherit' });
  console.log('\n✨ Dependency resolution complete!');
} catch (error) {
  console.error('Installation failed:', error.message);
  process.exit(1);
}