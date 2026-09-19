/**
 * Server-side script to assign Supabase-compatible custom claim to Firebase users.
 *
 * Sets { role: "authenticated" } so that Supabase Third-Party Auth recognizes
 * Firebase JWTs as the PostgreSQL "authenticated" role for Storage RLS.
 *
 * Usage:
 *   node scripts/set_supabase_claim.js <FIREBASE_UID_OR_PHONE>
 *   node scripts/set_supabase_claim.js --all
 *
 * Requirements:
 *   npm install firebase-admin
 *   Set GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json
 *   (or pass serviceAccountKey.json path as second argument)
 */

const { initializeApp, getApps, cert, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin SDK
if (!getApps().length) {
  const serviceAccountArg = process.argv[3];
  if (serviceAccountArg && fs.existsSync(serviceAccountArg)) {
    const serviceAccount = JSON.parse(fs.readFileSync(path.resolve(serviceAccountArg), 'utf8'));
    initializeApp({
      credential: cert(serviceAccount),
    });
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS && fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS)) {
    initializeApp({
      credential: applicationDefault(),
    });
  } else {
    try {
      initializeApp({
        projectId: 'sih2026-75333',
      });
    } catch (e) {
      console.error('Failed to initialize Firebase Admin SDK. Please set GOOGLE_APPLICATION_CREDENTIALS or provide the service account JSON path as an argument.');
      process.exit(1);
    }
  }
}

const auth = getAuth();

async function setClaimForUser(userRecord) {
  const existingClaims = userRecord.customClaims || {};
  const updatedClaims = {
    ...existingClaims,
    role: 'authenticated',
  };

  await auth.setCustomUserClaims(userRecord.uid, updatedClaims);
  console.log(`[SUCCESS] Assigned { role: 'authenticated' } to UID: ${userRecord.uid} (${userRecord.phoneNumber || userRecord.email || 'no-contact'})`);
}

async function main() {
  const target = process.argv[2];

  if (!target) {
    console.error('Usage:');
    console.error('  node scripts/set_supabase_claim.js <FIREBASE_UID_OR_PHONE>');
    console.error('  node scripts/set_supabase_claim.js --all');
    console.error('  node scripts/set_supabase_claim.js <UID> /path/to/serviceAccountKey.json');
    process.exit(1);
  }

  try {
    if (target === '--all') {
      console.log('Listing all users to assign role=authenticated...');
      let pageToken;
      let total = 0;
      do {
        const listUsersResult = await auth.listUsers(1000, pageToken);
        for (const userRecord of listUsersResult.users) {
          await setClaimForUser(userRecord);
          total++;
        }
        pageToken = listUsersResult.pageToken;
      } while (pageToken);
      console.log(`Done! Assigned claims to ${total} users.`);
      return;
    }

    let user;
    if (target.startsWith('+')) {
      // Lookup by phone number
      user = await auth.getUserByPhoneNumber(target);
    } else {
      // Lookup by UID
      user = await auth.getUser(target);
    }

    await setClaimForUser(user);
    const refreshed = await auth.getUser(user.uid);
    console.log('[VERIFIED] Custom claims:', refreshed.customClaims);
  } catch (error) {
    console.error('[ERROR]', error);
    process.exit(1);
  }
}

main();

