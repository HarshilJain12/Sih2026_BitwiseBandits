"""
Server-side Python script to assign { role: "authenticated" } claim to Firebase users for Supabase RLS.

Usage:
  python scripts/set_supabase_claim.py <FIREBASE_UID_OR_PHONE> [path_to_service_account.json]
  python scripts/set_supabase_claim.py --all [path_to_service_account.json]

Requirements:
  pip install firebase-admin
"""

import sys
import os
import firebase_admin
from firebase_admin import auth, credentials

def initialize_app(service_account_path=None):
    if firebase_admin._apps:
        return
    if service_account_path and os.path.exists(service_account_path):
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
    elif os.environ.get("GOOGLE_APPLICATION_CREDENTIALS") and os.path.exists(os.environ["GOOGLE_APPLICATION_CREDENTIALS"]):
        firebase_admin.initialize_app()
    else:
        try:
            firebase_admin.initialize_app(options={"projectId": "sih2026-75333"})
        except Exception as e:
            print(f"Error initializing Firebase Admin SDK: {e}")
            print("Please provide the service account JSON path as argument or set GOOGLE_APPLICATION_CREDENTIALS.")
            sys.exit(1)

def assign_claim(user_record):
    current_claims = user_record.custom_claims or {}
    updated_claims = {**current_claims, "role": "authenticated"}
    auth.set_custom_user_claims(user_record.uid, updated_claims)
    print(f"[SUCCESS] Assigned {{'role': 'authenticated'}} to UID: {user_record.uid} ({user_record.phone_number or 'no-phone'})")

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python scripts/set_supabase_claim.py <FIREBASE_UID_OR_PHONE> [path_to_service_account.json]")
        print("  python scripts/set_supabase_claim.py --all [path_to_service_account.json]")
        sys.exit(1)

    target = sys.argv[1]
    sa_path = sys.argv[2] if len(sys.argv) > 2 else None
    initialize_app(sa_path)

    if target == "--all":
        page = auth.list_users()
        count = 0
        while page:
            for u in page.users:
                assign_claim(u)
                count += 1
            page = page.get_next_page()
        print(f"Finished assigning claims to {count} users.")
        return

    if target.startswith("+"):
        user = auth.get_user_by_phone_number(target)
    else:
        user = auth.get_user(target)

    assign_claim(user)
    refreshed = auth.get_user(user.uid)
    print("Verified claims:", refreshed.custom_claims)

if __name__ == "__main__":
    main()
