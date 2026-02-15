# App Store Connect — Upload Checklist

## Before You Upload

- [ ] **Bundle ID** matches: `com.brianbruce.EZTeach`
- [ ] **Version**: 1.0 / Build: 1
- [ ] **Signing**: Automatic signing with your Apple Developer account
- [ ] **Archive**: Product > Archive in Xcode (select "Any iOS Device" as build target)
- [ ] **Upload**: Window > Organizer > Distribute App > App Store Connect

## App Store Connect Setup

### General Information
- [ ] App Name: `EZTeach — School Management K-12`
- [ ] Subtitle: `Grades, Games, AI & More`
- [ ] Primary Language: English (U.S.)
- [ ] Category: Education (Primary), Productivity (Secondary)
- [ ] Content Rights: Yes, I own or have rights to all content
- [ ] Age Rating: 4+

### Pricing & Availability
- [ ] Price: Free
- [ ] Availability: All territories (or select specific countries)
- [ ] Pre-Orders: Optional (not required for v1.0)

### App Privacy
- [ ] Privacy Policy URL: `https://ezteach.org/privacy`
- [ ] Data collection practices declared (Firebase Auth collects email, name)
- [ ] Data types: Contact Info (email, name), Usage Data (analytics), Identifiers (user ID)
- [ ] Data not linked to identity: Crash data, performance data
- [ ] Data linked to identity: Email, name, user ID (for account functionality)

### Version Information
- [ ] Screenshots uploaded for all required device sizes (see Screenshot-Captions.md)
- [ ] Description pasted from App-Store-Listing.md
- [ ] Keywords pasted from App-Store-Listing.md
- [ ] Support URL: `https://ezteach.org/support`
- [ ] Marketing URL: `https://ezteach.org`
- [ ] Promotional Text pasted
- [ ] What's New pasted

### App Review Information
- [ ] Demo Account provided (school admin — full access to all features):
  - Email: `test.faestreets.ezteach@gmail.com`
  - Password: `EZTeachTest2026!`
  - School: Fae Streets Academy (School Code: 987654)
- [ ] Student Login (students log in separately on the Student Login screen):
  - Student ID: *(open the school account above → Students → tap any student → copy their Student ID)*
  - Password: Student ID + `!` (e.g. if Student ID is `ABC123`, password is `ABC123!`)
  - Demo student "Pepper Clap Snap" is enrolled at Fae Streets Academy
- [ ] Notes for Reviewer:
  ```
  EZTeach is a free K-12 school management platform. There are no in-app
  purchases. The app is free to download and use for all roles (teachers,
  parents, students, staff). School accounts are managed by administrators.

  ACCOUNT DELETION (Guideline 5.1.1v):
  Account deletion is available in the app:
  - Staff/Admin: Menu → Account → scroll to bottom → "Delete My Account"
  - Students: Menu → Account → scroll to bottom → "Delete My Account"
  Both include double confirmation dialogs before permanent deletion.
  Deletion removes all user data from Firebase Auth and Firestore.

  SCHOOL ADMIN ACCOUNT (recommended for review):
  Email: test.faestreets.ezteach@gmail.com
  Password: EZTeachTest2026!
  This account has full access to all features — grades, attendance, AI lesson
  plans, movies, homework, messaging, bell schedules, analytics, and more.

  STUDENT LOGIN:
  Students log in via the "Student Login" button on the main login screen.
  They use their Student ID and password (default: Student ID + "!").
  To find a Student ID: log in with the school account above, go to Students,
  tap any student, and the Student ID is displayed on their profile.

  The app supports iPhone, iPad, and Mac (via Mac Catalyst).
  ```

### Subscription / In-App Purchases
- [ ] **No in-app purchases** — subscriptions are managed on the website
- [ ] If Apple asks: Explain that billing happens on ezteach.org via Stripe
- [ ] The app clearly states this on the Plans & Billing screen

### Export Compliance
- [ ] ITSAppUsesNonExemptEncryption: NO (already set in Info.plist)
- [ ] App uses HTTPS (standard Apple frameworks) — exempt from export regulations

## After Upload

- [ ] Wait for build processing (5-15 minutes)
- [ ] Select the build in App Store Connect
- [ ] Submit for Review
- [ ] Expected review time: 24-48 hours (first submission may take longer)

## Common Rejection Reasons to Avoid
1. **Missing demo account** — Always provide one
2. **Broken features** — Test every feature before submission
3. **Missing privacy policy** — ✅ Already at ezteach.org/privacy
4. **Missing terms of use** — ✅ Already at ezteach.org/terms
5. **Subscription wording** — ✅ Already compliant (restore purchases, terms links)
6. **Incomplete metadata** — Fill in every field in App Store Connect
7. **iPad layout issues** — ✅ Already optimized with NavigationSplitView
