# EZTeach — Setup Steps

Product IDs are already set in `functions/index.js`:
- School monthly: `prod_TsvP71E7nTlzCb` ($75/mo)
- School yearly: `prod_TsvTxl5KTc3bcB` ($750/yr)

---

## Step 1 — Stripe config (use existing keys for now)

```bash
cd /Users/brianbruce/Desktop/EZTeach

firebase functions:config:set stripe.secret_key="sk_live_YOUR_KEY"
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
```

## Step 2 — Deploy functions

```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only functions
```

---

## Step 3 — Firebase

### 3a — Auth
https://console.firebase.google.com → **Authentication** → **Sign-in method** → **Email/Password** → **Enable** → **Save**

### 3b — Rules
```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only firestore:rules
firebase deploy --only storage
```

---

## Step 4 — Promo codes

https://console.firebase.google.com → **Firestore Database** → **Start collection** `promoCodes`

**Document 1**
- Document ID: `EZT6X7K2M9QPN4LR`
- Fields: `isActive` true, `yearlyOnly` true, `discountPercent` 1, `description` "100% off yearly"

**Document 2**
- Document ID: `EZT4Y9N2QR7LKP3M`
- Fields: `isActive` true, `yearlyOnly` true, `discountPercent` 0.25, `description` "25% off yearly"

Keep both codes private.

---

## Step 5 — District flow

Use EZTeach app: add schools first, then pay. No extra steps.

---

## Step 6 — Website

### 6a — Firebase config
Open `/Users/brianbruce/Desktop/EZTeach/ezteach-website/firebase-config.js`
Use Firebase web config from: https://console.firebase.google.com → project **ezteach-cdf5c** → **Project settings** → **Your apps** → **Web**

### 6b — Push to GitHub
```bash
cd /Users/brianbruce/Desktop/EZTeach/ezteach-website
git add -A
git commit -m "Update config"
git push
```

### 6c — Verify
Open https://ezteach.org and confirm pricing ($75/mo, $750/yr), contact form, and login.

---

## Step 7 — App Store Connect

https://appstoreconnect.apple.com → **My Apps** → **EZTeach** → **App Information**
- Support: https://ezteach.org/support.html
- Marketing: https://ezteach.org
- Privacy: https://ezteach.org/privacy.html
- **Save**

---

## Step 8 — Checklist

- [ ] Stripe: config set with real keys; functions deployed
- [ ] Firebase Auth enabled; rules deployed
- [ ] Promo codes in Firestore, private
- [ ] Website live; config set; pushed to GitHub
- [ ] App Store Connect URLs set

---

## If you switch to Price IDs later

1. In Stripe Dashboard → Products → open each product → copy the **Price ID** (starts with `price_`)
2. Update `functions/index.js`: replace `price_data` block with `price: 'price_xxx'`
3. Or set: `firebase functions:config:set stripe.price_monthly="price_xxx" stripe.price_yearly="price_xxx"` and update the code to use config
