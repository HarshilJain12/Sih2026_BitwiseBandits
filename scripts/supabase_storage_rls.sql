-- ============================================================================
-- Supabase Storage RLS Policies for SIH 2026 Rural Healthcare App
-- Private Bucket: medical-records
-- Canonical Object Path: {firebaseUid}/{patientId}/{recordId}/{sanitizedFileName}
-- ============================================================================

-- 1. Ensure the medical-records bucket is created and marked PRIVATE
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'medical-records',
  'medical-records',
  false,
  10485760, -- 10 MB limit
  ARRAY['application/pdf', 'image/jpeg', 'image/jpg', 'image/png']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['application/pdf', 'image/jpeg', 'image/jpg', 'image/png'];

-- 2. Drop any existing/conflicting policies on medical-records bucket
DROP POLICY IF EXISTS "Patients can read own medical records" ON storage.objects;
DROP POLICY IF EXISTS "Patients can upload own medical records" ON storage.objects;
DROP POLICY IF EXISTS "Patients can update own medical records" ON storage.objects;
DROP POLICY IF EXISTS "Patients can delete own medical records" ON storage.objects;
DROP POLICY IF EXISTS "Patients can read their own medical records" ON storage.objects;
DROP POLICY IF EXISTS "Patients can upload their own medical records" ON storage.objects;
DROP POLICY IF EXISTS "Patients can delete their own medical records" ON storage.objects;

-- 4. SELECT (Download / Read):
-- Allows authenticated users (via Firebase JWT) whose UID (sub) matches the first path segment
CREATE POLICY "Patients can read own medical records"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (
  bucket_id = 'medical-records'
  AND (auth.jwt() ->> 'sub') IS NOT NULL
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub')
);

-- TEMPORARY POLICY FOR MOCK DOCTORS (MVP/Demo only):
-- Allows any authenticated user to read medical records so the mock doctor can view them.
CREATE POLICY "Mock Doctors can read all medical records"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (
  bucket_id = 'medical-records'
);

-- 5. INSERT (Upload):
-- Can only insert objects inside their own {firebaseUid}/ directory
CREATE POLICY "Patients can upload own medical records"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (
  bucket_id = 'medical-records'
  AND (auth.jwt() ->> 'sub') IS NOT NULL
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub')
);

-- 6. UPDATE (Overwrite / Metadata update):
-- Can only update objects inside their own {firebaseUid}/ directory
CREATE POLICY "Patients can update own medical records"
ON storage.objects FOR UPDATE
TO anon, authenticated
USING (
  bucket_id = 'medical-records'
  AND (auth.jwt() ->> 'sub') IS NOT NULL
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub')
)
WITH CHECK (
  bucket_id = 'medical-records'
  AND (auth.jwt() ->> 'sub') IS NOT NULL
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub')
);

-- 7. DELETE:
-- Can only delete objects inside their own {firebaseUid}/ directory
CREATE POLICY "Patients can delete own medical records"
ON storage.objects FOR DELETE
TO anon, authenticated
USING (
  bucket_id = 'medical-records'
  AND (auth.jwt() ->> 'sub') IS NOT NULL
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub')
);

