/**
 * keygen.js — generates an Ed25519 keypair for Helios Ledger
 * Run: node keygen.js
 * Output: two JSON strings to set as Wrangler secrets
 */
const { generateKeyPairSync } = require('crypto');

const { privateKey, publicKey } = generateKeyPairSync('ed25519');

const privateJwk = privateKey.export({ format: 'jwk' });
const publicJwk  = publicKey.export({ format: 'jwk' });

// Remove private component from public key JWK
const publicJwkClean = { kty: publicJwk.kty, crv: publicJwk.crv, x: publicJwk.x };

console.log('\n=== HELIOS LEDGER KEY GENERATION ===\n');
console.log('SIGNING_PRIVATE_KEY (keep secret!):');
console.log(JSON.stringify(privateJwk));
console.log('\nSIGNING_PUBLIC_KEY (safe to share):');
console.log(JSON.stringify(publicJwkClean));
console.log('\n=====================================');
console.log('Next: set both as Wrangler secrets (deploy-v2.ps1 does this for you)');
