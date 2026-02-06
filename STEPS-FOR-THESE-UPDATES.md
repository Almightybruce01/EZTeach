# Steps for These Updates

## 1. Deploy Cloud Functions (Required)
```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only functions
```
This deploys: `getFundayFridaySchools`, `saveFundayFridayPick`, `searchSchools`.

---

## 2. Funday Friday (Optional Secret)
To restrict access to your dashboard:
```bash
firebase functions:config:set funday.secret="your-secret-here"
firebase deploy --only functions
```
Then open: `FundayFriday-Dashboard.html?key=your-secret-here`

If you skip this, the dashboard works without a key (open `FundayFriday-Dashboard.html`). For local use, serve the file (e.g. `python3 -m http.server 8080`) and open `http://localhost:8080/FundayFriday-Dashboard.html` so the fetch to Cloud Functions works (CORS).

---

## 3. Create Test Accounts
Use **TEST-ACCOUNTS.md** — create accounts with:
- School: **Fae Streets Academy** (code 987654)
- Teacher: **Crusty Rab**
- Sub, Parent, District as listed

---

## 4. Presentation Materials
- **PRESENTATION-SLIDES.html** — Open in browser, use arrow keys or buttons.
- **EZTEACH-PAMPHLET.html** — File → Print for handouts.
- **TALKING-TIPS-AND-COUNTERS.md** — Counters to common questions.
- **PRESENTATION-SCRIPT.md** — Updated with creation story, why choose us, safety, updates.

---

## 5. Parent Flow (App)
Parents now:
1. **Pick school** — Search by name, city, or 6‑digit code.
2. **Enter student code** — Code must match a student at that school.
3. **Confirm and link** — Same as before.

---

## 6. School Display
- **Switch School** and **joined schools** — Now show **city** under school name.
- **New joins** — City is stored when teachers/subs add a school by code.

---

## 7. Build & Test
1. Build in Xcode.
2. Create Fae Streets Academy (school code 987654).
3. Add teacher Crusty Rab, add a student.
4. Test parent: search "Fae" or "Testville", pick school, enter student code.
