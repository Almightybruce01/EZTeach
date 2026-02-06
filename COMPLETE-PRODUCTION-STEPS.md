# EZTeach — Complete Production Steps

**Follow in order. You have done none of these yet.**

---

## Funday Friday Flow
1. Press **SPIN** — wheel animates, random school is picked
2. Confetti + fireworks + school name pops up
3. 6 prizes appear with animated "pick me" motion
4. You **choose one** prize (click it)
5. School is stored as picked, ready for next spin  
**Tip:** Start screen recording (QuickTime, OBS, or built-in) before pressing SPIN for Instagram.

---

## Step 1 — Deploy Firebase
```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only firestore:rules
firebase deploy --only functions
firebase deploy --only storage
```

---

## Step 2 — Funday Friday
Start a local server, then open the dashboard:
```bash
cd /Users/brianbruce/Desktop/EZTeach
python3 -m http.server 8080
```
Open: **http://localhost:8080/FundayFriday-Dashboard.html**

**Screen recording for Instagram:** Start recording, then press SPIN. Wheel → fireworks → 6 animated prizes → choose one. Ready to tape.

Optional: restrict with `firebase functions:config:set funday.secret="your-secret"` and add `?key=your-secret` to the URL.

---

## Step 3 — Create Test Accounts
Use **TEST-ACCOUNTS.md**. Create these **new** accounts in the app:

| Order | Role   | Email                        | Key Info                          |
|-------|--------|------------------------------|-----------------------------------|
| 1     | School | test.faestreets.ezteach@gmail.com | Fae Streets Academy, code 987654 |
| 2     | Teacher| test.crustyrab.ezteach@gmail.com  | Crusty Rab                        |
| 3     | Sub    | test.sub.ezteach@gmail.com   | Add school 987654                 |
| 4     | Parent | test.parent.ezteach@gmail.com| Search "Fae Streets" → student code |
| 5     | District | test.district.ezteach@gmail.com | Add school 987654              |

**Password for all:** `EZTeachTest2026!`

---

## Step 4 — Verify Role Creation
When you create each account:
- **School:** `users/{uid}` + `schools/{schoolId}` created
- **Teacher:** `users/{uid}` + `teachers/{docId}` with `userId` and `schoolId: null` (until they add a school)
- **Sub:** `users/{uid}` + `subs/{docId}` with `userId` and `schoolId: null`
- **Parent:** `users/{uid}` + `parents/{docId}` with `userId`
- **District:** `users/{uid}` + `districts/{districtId}`

Check Firestore after creating each account to confirm.

---

## Step 5 — Add Sample Data (School Account)
1. Sign in as Fae Streets Academy
2. Add teacher Crusty Rab (or create teacher account and add school 987654)
3. Add 1–2 students (student codes are auto-generated)
4. Create 1–2 announcements
5. Create 1–2 calendar events

---

## Step 6 — Test Parent Flow
1. Sign in as parent
2. My Children → Search "Fae Streets" or "Testville"
3. Select Fae Streets Academy
4. Enter student code from the school
5. Confirm and link

---

## District Creating a School
When a district creates a new school (during subscription flow):
- Same fields as school account: name, address, city, state, zip, 6‑digit school code
- School admin: first name, last name, email, password (creates full school account)

---

## Step 7 — Capture App Store Screenshots
1. Xcode → Run on **iPhone 15 Pro Max** simulator
2. Sign in as test.faestreets.ezteach@gmail.com
3. Navigate: Home, Grades, Sub Requests, Calendar, School Info, Account
4. **Cmd + S** to save each screenshot (saves to Desktop)
5. App Store Connect → Your App → Version → Screenshots → 6.5" Display → Upload

---

## Step 8 — Fill App Store Connect
Use **APP-STORE-ASSETS.md**:

- Promotional Text  
- Description  
- Keywords  
- Support URL: https://ezteach.org/support.html  
- Marketing URL: https://ezteach.org  
- Privacy URL: https://ezteach.org/privacy.html  
- App Review: test.faestreets.ezteach@gmail.com / EZTeachTest2026!

---

## Step 9 — Student Codes
Student codes are **auto-generated** when you add a student (8-character alphanumeric). No extra setup.

---

## Step 10 — Weak Points Checklist
- [ ] Firestore rules deployed
- [ ] All roles create `users` + role-specific collection (teachers, subs, parents, schools, districts)
- [ ] Student codes generated on student creation
- [ ] Parent must pick school before entering student code
- [ ] Funday Friday: spin → 6 prizes appear → you choose one
- [ ] Test accounts use Fae Streets / Crusty Rab (not Lincoln)

---

## About index.html
`ezteach-website/index.html` is your site’s main page. It may appear in “recently viewed files” because you opened it or the IDE indexed it. It’s the landing page for ezteach.org and isn’t related to the iOS app’s internal logic.
