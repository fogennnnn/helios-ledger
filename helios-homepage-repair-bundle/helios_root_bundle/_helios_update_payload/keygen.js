// keygen.js — Generate Ed25519 keypair for Helios Ledger signing
// Run: node keygen.js
// Then set as wrangler secrets:
//   echo '<private_jwk>' | npx wrangler secret put SIGNING_PRIVATE_KEY
//   echo '<public_jwk>'  | npx wrangler secret put SIGNING_PUBLIC_KEY

const { generateKeyPairSync } = require('node:crypto');

const { privateKey, publicKey } = generateKeyPairSync('ed25519');
const privateJwk = privateKey.export({ format: 'jwk' });
const publicJwk = publicKey.export({ format: 'jwk' });
const publicJwkClean = { kty: publicJwk.kty, crv: publicJwk.crv, x: publicJwk.x };

console.log(JSON.stringify(privateJwk));
console.log(JSON.stringify(publicJwkClean));
