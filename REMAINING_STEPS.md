# EZTeach — Steps to Complete Setup

---

## Step 1 — Deploy functions

```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only functions
```

---

## Step 2 — Create promo codes (Firestore)

1. Go to: **https://console.firebase.google.com**
2. Click project **ezteach-cdf5c**
3. Left sidebar → **Build** → **Firestore Database**
4. Click **+ Start collection** (or **+ Add collection**)
5. **Collection ID:** type `promoCodes` → **Next**

**First document:**
6. **Document ID:** type `EZT6X7K2M9QPN4LR` (exactly, copy-paste)
7. Click **Add field** → Field: `isActive` → Type: **boolean** → Value: `true` → **Add**
8. Click **Add field** → Field: `yearlyOnly` → Type: **boolean** → Value: `true` → **Add**
9. Click **Add field** → Field: `discountPercent` → Type: **number** → Value: `1` → **Add**
10. Click **Add field** → Field: `description` → Type: **string** → Value: `100% off yearly` → **Add**
11. Click **Save**

**Second document:**
12. Click **+ Add document**
13. **Document ID:** type `EZT4Y9N2QR7LKP3M` (exactly, copy-paste)
14. Add field: `isActive` → boolean → `true`
15. Add field: `yearlyOnly` → boolean → `true`
16. Add field: `discountPercent` → number → `0.25`
17. Add field: `description` → string → `25% off yearly`
18. Click **Save**

---

## Step 3 — Enable Firebase Auth

1. Go to: **https://console.firebase.google.com**
2. Project **ezteach-cdf5c**
3. **Build** → **Authentication** → **Sign-in method**
4. Click **Email/Password**
5. Turn **Enable** ON → **Save**

---

## Step 4 — Deploy Firestore and Storage rules

```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only firestore:rules
firebase deploy --only storage
```

---

## Step 5 — Push website to GitHub

```bash
cd /Users/brianbruce/Desktop/EZTeach/ezteach-website
git add -A
git commit -m "Update"
git push
```

Then open **https://ezteach.org** and verify it looks correct.

---

## Step 6 — App Store Connect

1. Go to: **https://appstoreconnect.apple.com**
2. **My Apps** → **EZTeach** → **App Information**
3. Set:
   - Support URL: `https://ezteach.org/support.html`
   - Marketing URL: `https://ezteach.org`
   - Privacy Policy URL: `https://ezteach.org/privacy.html`
4. **Save**

---

## Step 7 — Stripe webhook

1. Go to: **https://dashboard.stripe.com/webhooks**
2. Open your webhook
3. URL must be: `https://us-central1-ezteach-cdf5c.cloudfunctions.net/stripeWebhook`
4. Events: `checkout.session.completed`, `invoice.paid`, `invoice.payment_failed`, `customer.subscription.deleted`

---

## Checklist

- [ ] Step 1: Deploy functions
- [ ] Step 2: Create 2 promo code docs in Firestore
- [ ] Step 3: Enable Email/Password auth
- [ ] Step 4: Deploy rules
- [ ] Step 5: Push website, verify ezteach.org
- [ ] Step 6: App Store Connect URLs
- [ ] Step 7: Stripe webhook correct
