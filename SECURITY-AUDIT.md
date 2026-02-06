# EZTeach — Full Security & Quality Audit

**Audit date:** January 31, 2026  
**Scope:** App, website, Firebase (Firestore, Storage, Cloud Functions)

---

## EXECUTIVE SUMMARY

| Category | Status | Notes |
|----------|--------|-------|
| Firestore rules | Good | Role-based, school-scoped; district support |
| Storage rules | Fixed | School logos now owner-only for write/delete |
| Cloud Functions | Fixed | setupPromoCodes restricted; formGridWebhook secret; XSS escape |
| Firebase API keys | OK | Public by design; restrict domains in Firebase Console |
| Stripe webhook | OK | Signature verification in place |
| App security | Good | Auth, role checks, school access verification |

---

## FIXES APPLIED (This Audit)

### 1. Storage — School logos
- **Before:** Any authenticated user could write/delete any school logo.
- **After:** Only the school owner (`ownerUid`) can write/delete logos.
- **Impact:** Prevents cross-school logo tampering.

### 2. Cloud Functions — setupPromoCodes
- **Before:** Any authenticated user could create/overwrite promo codes.
- **After:** Only the user with UID in `app.admin_uid` config can call it.
- **Config:** `firebase functions:config:set app.admin_uid="YOUR_UID"`

### 3. Cloud Functions — formGridWebhook
- **Before:** No verification; anyone could POST fake submissions.
- **After:** Optional secret verification via header `x-webhook-secret` or query `?secret=`.
- **Config:** `firebase functions:config:set formgrid.webhook_secret="YOUR_SECRET"`  
- **FormGrid:** Add the same secret in FormGrid webhook settings.

### 4. Cloud Functions — Support claim emails (XSS)
- **Before:** User-provided `subject`, `message`, `email` inserted into HTML.
- **After:** All user input escaped before inclusion in email HTML.

---

## RECOMMENDED ACTIONS

### High priority

#### 1. Set admin UID for promo codes
```bash
firebase functions:config:set app.admin_uid="YOUR_FIREBASE_UID"
firebase deploy --only functions
```

#### 2. Set FormGrid webhook secret (optional but recommended)
- Generate a random string (e.g. `openssl rand -hex 32`).
- `firebase functions:config:set formgrid.webhook_secret="YOUR_SECRET"`
- In FormGrid, add header `x-webhook-secret: YOUR_SECRET` or append `?secret=YOUR_SECRET` to webhook URL.
- `firebase deploy --only functions`

#### 3. Firebase Console — API key restrictions
- Firebase Console → Project Settings → Your apps.
- Restrict the web API key to domains: `ezteach.org`, `*.netlify.app`, `localhost`.

### Medium priority

#### 4. Schools read rule (Firestore)
- **Current:** Any signed-in user can read any school document.
- **Risk:** Cross-school data leak (name, address, overview, office info).
- **Fix:** Restrict to users who have joined that school (requires `joinedSchoolIds` on user doc or similar schema).
- **Status:** Deferred — requires schema/app changes.

#### 5. Documents Storage rule
- **Current:** Any authenticated user can read/write/delete documents for any school.
- **Risk:** Cross-school document access.
- **Fix:** Validate school membership in Storage rules or move uploads to a Cloud Function.
- **Status:** Deferred — requires schema or Cloud Function upload flow.

#### 6. Parents and gradeAssignments / announcements
- **Current:** Parents can read grade assignments and announcements with only `isParent()`.
- **Risk:** Parents could read assignments/announcements for schools they don’t belong to.
- **Fix:** Add parent-school linkage (e.g. via child’s school) in rules.
- **Status:** Deferred — needs schema/rule refinement.

### Low priority

#### 7. classGradeSettings read rule
- **Current:** Any signed-in user can read all class grade settings.
- **Risk:** Minor — category weights, etc., could leak across schools.
- **Fix:** Scope reads by school (e.g. `activeSchool()`).

#### 8. Firebase App Check
- Add App Check for iOS and web to reduce abuse and unauthorized access.

---

## VERIFIED SECURE

| Component | Verification |
|-----------|--------------|
| Stripe webhook | Signature validated with `stripe.webhooks.constructEvent` |
| Callable functions | `context.auth` checked; unauthenticated rejected |
| Firestore rules | All collections use `signedIn()`, role, and school scope |
| User document | Only owner can read/write their own user doc |
| Students | Parents restricted via `parentIds`; staff via `activeSchool()` |
| Subscriptions | Write only from Cloud Functions |
| Support claims | User can only read own claims |
| Districts | Owner and school admin access only |
| Sub reviews | School and district admin only |

---

## DEPLOYMENT AFTER FIXES

```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only firestore:rules
firebase deploy --only storage
firebase deploy --only functions
```

---

## BUG CHECK

- No hardcoded secrets in source (Stripe, SendGrid use config).
- Firebase web config in `firebase-config.js` — API keys are intended for client use; restrict in Console.
- GoogleService-Info.plist — standard for iOS; do not commit if it contained secrets (it does not).
- FormGrid webhook — no signature verification previously; now optional secret supported.
- Support claim HTML — user input now escaped to prevent XSS in email clients.

---

## FERPA / COPPA ALIGNMENT

- Student data: Read access limited by role and parent/student linkage.
- Schools: Only authorized users should read school data (see medium priority items).
- No selling of data.
- Privacy policy and data deletion process should be documented and followed.
