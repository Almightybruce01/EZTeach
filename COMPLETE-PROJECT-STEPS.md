# EZTeach — Complete Project Steps

Run these in order. You have **ezteach-website** on GitHub. You need to add the **main app** repo.

---

## PART 1: GitHub — Main App Repo

### Step 1.1 — Create EZTeach repo on GitHub
1. Go to https://github.com/new
2. **Repository name:** `EZTeach`
3. Leave **Public** (or Private if you prefer)
4. Do **NOT** check "Add a README" or any other files
5. Click **Create repository**

### Step 1.2 — Push main project to GitHub
```bash
cd /Users/brianbruce/Desktop/EZTeach
git push -u origin main
```

---

## PART 2: Website — ezteach-website

### Step 2.1 — Push website changes (if any)
```bash
cd /Users/brianbruce/Desktop/EZTeach/ezteach-website
git add -A
git status
git commit -m "Updates"  # only if status shows changes
git push origin main
```

---

## PART 3: Firebase Deploy

### Step 3.1 — Firestore rules
```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only firestore:rules
```

### Step 3.2 — Cloud Functions
```bash
firebase deploy --only functions
```

### Step 3.3 — Storage rules
```bash
firebase deploy --only storage
```

---

## PART 4: Netlify — Website Hosting

### Step 4.1 — Connect repo (if not already)
1. Go to https://app.netlify.com
2. **Sites** → **Add new site** → **Import an existing project**
3. Choose **GitHub** → **Almightybruce01/ezteach-website**
4. **Build command:** leave blank
5. **Publish directory:** `.` (root)
6. **Deploy site**

### Step 4.2 — Custom domain (ezteach.org)
1. **Site settings** → **Domain management** → **Add custom domain**
2. Enter `ezteach.org`
3. Follow Netlify’s DNS instructions (e.g. add CNAME in Namecheap)

---

## PART 5: App Store Connect

### Step 5.1 — App Information URLs
- **Privacy Policy URL:** `https://ezteach.org/privacy.html`
- **Support URL:** `https://ezteach.org/support.html`
- **Marketing URL:** `https://ezteach.org`

### Step 5.2 — Version 1.0 page
- Support URL, Marketing URL, Description, Keywords, Copyright
- At least 3 iPhone screenshots (6.5" display: 1284×2778 or 2778×1284)
- Sign-in credentials for App Review (test account)

---

## PART 6: Xcode — Build and Upload

### Step 6.1 — Archive and upload
1. Open `/Users/brianbruce/Desktop/EZTeach/EZTeach.xcodeproj`
2. **Product** → **Archive**
3. **Distribute App** → **App Store Connect** → **Upload**

### Step 6.2 — Submit for review
1. Go to https://appstoreconnect.apple.com
2. **My Apps** → **EZTeach** → **1.0**
3. Select the uploaded build
4. **Add for Review** → **Submit for Review**

---

## PART 7: External Services (Optional / Later)

### Stripe — Live payments
- Connect bank account in Stripe Dashboard
- Test subscriptions in Test mode, then switch to Live mode

### SendGrid — Email
```bash
firebase functions:config:set sendgrid.api_key="SG.your_key"
firebase deploy --only functions
```

### FormGrid — Contact form
- Webhook URL: `https://us-central1-ezteach-cdf5c.cloudfunctions.net/formGridWebhook`

---

## Command Summary (Copy-Paste)

```bash
# 1. Main app push (after creating EZTeach repo on GitHub)
cd /Users/brianbruce/Desktop/EZTeach
git push -u origin main

# 2. Website push
cd /Users/brianbruce/Desktop/EZTeach/ezteach-website
git add -A
git status
git commit -m "Updates"  # if there are changes
git push origin main

# 3. Firebase deploy
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only firestore:rules
firebase deploy --only functions
firebase deploy --only storage
```
