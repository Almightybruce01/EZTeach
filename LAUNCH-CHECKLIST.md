# EZTeach — Launch Checklist

## 1. Deploy Firestore Rules & Functions
```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only firestore:rules
firebase deploy --only functions
```

**Funday Friday (optional):** To secure the dashboard, set a secret:
```bash
firebase functions:config:set funday.secret="your-secret-here"
firebase deploy --only functions
```
Then open FundayFriday-Dashboard.html?key=your-secret-here

## 2. Create Test Accounts
Use **TEST-ACCOUNTS.md** — create one of each role (school, teacher, sub, parent, district) with the generic info. Use NEW emails (e.g. test.school.ezteach@gmail.com).

## 3. Capture App Store Screenshots
- Run app in Simulator (iPhone 15 Pro Max)
- Sign in as test school account
- Navigate: Home → Grades → Sub Requests → Calendar → School Info → Account
- Cmd + S to save each (saves to Desktop)
- Upload to App Store Connect → Screenshots

## 4. App Store Connect — Fill In
- **Promotional Text:** See APP-STORE-ASSETS.md
- **Description:** See APP-STORE-ASSETS.md  
- **Keywords:** See APP-STORE-ASSETS.md
- **Support URL:** https://ezteach.org/support.html
- **Marketing URL:** https://ezteach.org
- **Privacy URL:** https://ezteach.org/privacy.html
- **App Review:** Provide test account from TEST-ACCOUNTS.md

## 5. Funday Friday Dashboard
- Open **FundayFriday-Dashboard.html** in browser (or from Admin-Dashboard link)
- Sign in with your EZTeach account
- Spin to pick 6 winners (1 school + 5 surprises)
- Picks save to Firestore `fundayFridayPicks`

## 6. Social & Presentation
- **SOCIAL-MEDIA-CALENDAR.md** — weekly posting plan, graphics in AppStore-Assets
- **PRESENTATION-SCRIPT.md** — script for school presentations
- **PRESENTATION-SLIDES.html** — slideshow (open in browser, use arrow keys)
- **EZTEACH-PAMPHLET.html** — printable pamphlet (File → Print)
- **TALKING-TIPS-AND-COUNTERS.md** — counters to common questions
