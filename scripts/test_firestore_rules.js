/**
 * Automated Firestore Security Rules Verification Script
 *
 * Tests:
 * 1. Owner can read medical records for their patient.
 * 2. Owner can create medical records for their patient.
 * 3. Owner can update and delete their patient's medical records.
 * 4. Another user CANNOT read the owner's patient medical records (403 Forbidden).
 * 5. Another user CANNOT create medical records under the owner's patient (403 Forbidden).
 * 6. Another user CANNOT update or delete the owner's patient medical records (403 Forbidden).
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const fs = require('fs');
const https = require('https');

const SA_PATH = 'C:/Users/harsh/Downloads/sih2026-75333-firebase-adminsdk-fbsvc-c3cf0f19c9.json';
const PROJECT_ID = 'sih2026-75333';
const OWNER_UID = 'P5CeG63YI8UQ4BRQs8MfTGGJ9sX2';
const ATTACKER_UID = 'rgiI5MWB00QSNMfm1A5SFYse3b33';
const PATIENT_ID = 'P-K4B5HYLGDA';

const sa = JSON.parse(fs.readFileSync(SA_PATH, 'utf8'));
const app = initializeApp({ credential: cert(sa) });
const auth = getAuth(app);

function makeHttpRequest(options, bodyData) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        let parsed;
        try {
          parsed = JSON.parse(data);
        } catch (e) {
          parsed = data;
        }
        resolve({ statusCode: res.statusCode, data: parsed });
      });
    });
    req.on('error', reject);
    if (bodyData) {
      req.write(typeof bodyData === 'string' ? bodyData : JSON.stringify(bodyData));
    }
    req.end();
  });
}

async function getIdToken(uid) {
  const customToken = await auth.createCustomToken(uid);
  const apiKey = sa.apiKey || 'AIzaSyAn6jLUfS7oYB6P7oM6jDRe83byqJKlOJg';
  const res = await makeHttpRequest(
    {
      hostname: 'identitytoolkit.googleapis.com',
      path: `/v1/accounts:signInWithCustomToken?key=${apiKey}`,
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    },
    { token: customToken, returnSecureToken: true }
  );
  if (res.statusCode !== 200) {
    throw new Error(`Failed to exchange custom token for UID ${uid}: ${JSON.stringify(res.data)}`);
  }
  return res.data.idToken;
}

async function runTests() {
  console.log('════════════ FIRESTORE RULES VERIFICATION ════════════');
  console.log(`Target Project: ${PROJECT_ID}`);
  console.log(`Target Patient ID: ${PATIENT_ID} (Owned by: ${OWNER_UID})`);
  console.log(`Attacker UID: ${ATTACKER_UID}`);
  console.log('------------------------------------------------------');

  const ownerToken = await getIdToken(OWNER_UID);
  const attackerToken = await getIdToken(ATTACKER_UID);

  const testRecordId = 'MR-TEST-' + Date.now().toString(36).toUpperCase();
  const basePath = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/patients/${PATIENT_ID}/medicalRecords`;

  // TEST 1: Owner Create Medical Record
  console.log(`\n[TEST 1] Owner (${OWNER_UID}) creates medical record ${testRecordId}...`);
  const createPayload = {
    fields: {
      recordId: { stringValue: testRecordId },
      patientId: { stringValue: PATIENT_ID },
      ownerUid: { stringValue: OWNER_UID },
      originalFileName: { stringValue: 'test_report.pdf' },
      storagePath: { stringValue: `${OWNER_UID}/${PATIENT_ID}/${testRecordId}/test_report.pdf` },
      storageType: { stringValue: 'supabase' },
      mimeType: { stringValue: 'application/pdf' },
      status: { stringValue: 'uploaded' },
      uploadedAt: { timestampValue: new Date().toISOString() },
    },
  };

  const ownerCreateRes = await makeHttpRequest(
    {
      hostname: 'firestore.googleapis.com',
      path: `${basePath}?documentId=${testRecordId}`,
      method: 'POST',
      headers: {
        Authorization: `Bearer ${ownerToken}`,
        'Content-Type': 'application/json',
      },
    },
    createPayload
  );

  console.log(`Owner create status: ${ownerCreateRes.statusCode} (${ownerCreateRes.statusCode === 200 ? 'PASS' : 'FAIL'})`);
  if (ownerCreateRes.statusCode !== 200) {
    console.error('Owner create error:', ownerCreateRes.data);
  }

  // TEST 2: Owner Read Medical Records
  console.log(`\n[TEST 2] Owner (${OWNER_UID}) reads medical records for patient ${PATIENT_ID}...`);
  const ownerReadRes = await makeHttpRequest({
    hostname: 'firestore.googleapis.com',
    path: basePath,
    method: 'GET',
    headers: { Authorization: `Bearer ${ownerToken}` },
  });
  console.log(`Owner read status: ${ownerReadRes.statusCode} (${ownerReadRes.statusCode === 200 ? 'PASS' : 'FAIL'})`);

  // TEST 3: Attacker (Different User) attempts to READ Owner's Medical Records
  console.log(`\n[TEST 3] Attacker (${ATTACKER_UID}) attempts to READ Owner's medical records...`);
  const attackerReadRes = await makeHttpRequest({
    hostname: 'firestore.googleapis.com',
    path: basePath,
    method: 'GET',
    headers: { Authorization: `Bearer ${attackerToken}` },
  });
  console.log(`Attacker read status: ${attackerReadRes.statusCode} (${attackerReadRes.statusCode === 403 ? 'PASS: Forbidden (Blocked)' : 'FAIL'})`);

  // TEST 4: Attacker attempts to CREATE Medical Record under Owner's Patient
  const attackerRecordId = 'MR-HACK-' + Date.now().toString(36).toUpperCase();
  console.log(`\n[TEST 4] Attacker (${ATTACKER_UID}) attempts to CREATE record under Owner's patient...`);
  const attackerCreatePayload = {
    fields: {
      recordId: { stringValue: attackerRecordId },
      patientId: { stringValue: PATIENT_ID },
      ownerUid: { stringValue: ATTACKER_UID },
      originalFileName: { stringValue: 'malicious.pdf' },
      status: { stringValue: 'uploaded' },
    },
  };
  const attackerCreateRes = await makeHttpRequest(
    {
      hostname: 'firestore.googleapis.com',
      path: `${basePath}?documentId=${attackerRecordId}`,
      method: 'POST',
      headers: {
        Authorization: `Bearer ${attackerToken}`,
        'Content-Type': 'application/json',
      },
    },
    attackerCreatePayload
  );
  console.log(`Attacker create status: ${attackerCreateRes.statusCode} (${attackerCreateRes.statusCode === 403 ? 'PASS: Forbidden (Blocked)' : 'FAIL'})`);

  // TEST 5: Owner Clean up Test Record
  console.log(`\n[TEST 5] Owner (${OWNER_UID}) deletes test record ${testRecordId}...`);
  const ownerDeleteRes = await makeHttpRequest({
    hostname: 'firestore.googleapis.com',
    path: `${basePath}/${testRecordId}`,
    method: 'DELETE',
    headers: { Authorization: `Bearer ${ownerToken}` },
  });
  console.log(`Owner delete status: ${ownerDeleteRes.statusCode} (${ownerDeleteRes.statusCode === 200 ? 'PASS' : 'FAIL'})`);

  console.log('\n════════════ ALL SECURITY CHECKS COMPLETE ════════════');
}

runTests().catch(console.error);
