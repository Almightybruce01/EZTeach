# EZTeach — Complete Setup Steps

---

## Email: Where messages go

| Source | Where it goes |
|--------|----------------|
| **Website contact links** (mailto:) | Opens user's email client → they send TO the address in `firebase-config.js` (currently support@ezteach.org) |
| **FormGrid contact form** | Form submissions go wherever you configured in FormGrid (email or Google Sheets). Set to your real email. |
| **Support claims (in-app)** | Cloud Function emails TO `app.support_email` (set via Firebase config). If not set, uses support@ezteach.org |
| **Welcome/billing emails** | Sent FROM noreply@ezteach.org via SendGrid. Requires SendGrid setup and verified sender. |

**Update your support email in one place:**
1. **Website:** Edit `ezteach-website/firebase-config.js` → change `window.EZTEACH_SUPPORT_EMAIL = "support@ezteach.org"` to your real email.
2. **Cloud Functions (support claims):** Run:
   ```bash
   firebase functions:config:set app.support_email="your-real-email@gmail.com"
   firebase deploy --only functions
   ```
3. **FormGrid:** In FormGrid dashboard → your form → integrations → set email notifications to your real email.
4. **support@ezteach.org:** If you keep it, set up email forwarding in Namecheap (or your domain host) to forward support@ezteach.org → your personal inbox.

---

## Stripe checkout — verification

Your Stripe setup:
- **createCheckoutSession** Cloud Function: creates Stripe checkout for $75/mo or $750/yr (with promo discount)
- **stripeWebhook** handles: checkout.session.completed, invoice.paid, invoice.payment_failed, customer.subscription.deleted
- **Products:** prod_TsvP71E7nTlzCb (monthly), prod_TsvTxl5KTc3bcB (yearly)

**Check:**
1. https://dashboard.stripe.com/webhooks → endpoint URL: `https://us-central1-ezteach-cdf5c.cloudfunctions.net/stripeWebhook`
2. Events selected: checkout.session.completed, invoice.paid, invoice.payment_failed, customer.subscription.deleted
3. Firebase config: `stripe.secret_key` and `stripe.webhook_secret` set

---

## Steps to complete

### Step 1 — Deploy functions
```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only functions
```

### Step 2 — Promo codes (done if you created in Firestore)
- Collection `promoCodes` with docs EZT6X7K2M9QPN4LR and EZT4Y9N2QR7LKP3M

### Step 3 — Firebase Auth
- https://console.firebase.google.com → ezteach-cdf5c → Authentication → Sign-in method → Email/Password → Enable

### Step 4 — Rules
```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only firestore:rules
firebase deploy --only storage
```

### Step 5 — Set your support email
1. Edit `ezteach-website/firebase-config.js` → `EZTEACH_SUPPORT_EMAIL`
2. Run: `firebase functions:config:set app.support_email="your@email.com"`
3. Redeploy: `firebase deploy --only functions`

### Step 6 — Push website
```bash
cd /Users/brianbruce/Desktop/EZTeach/ezteach-website
git add -A
git commit -m "Support email config, updates"
git push
```

### Step 7 — App Store Connect
- https://appstoreconnect.apple.com → My Apps → EZTeach → App Information
- Support URL: https://ezteach.org/support.html
- Marketing URL: https://ezteach.org
- Privacy Policy URL: https://ezteach.org/privacy.html

### Step 8 — Stripe webhook
- https://dashboard.stripe.com/webhooks → URL and events correct

### Step 9 — FormGrid
- Set email notifications to your real email for contact form submissions

---

## Checklist

- [ ] Functions deployed
- [ ] Promo codes in Firestore
- [ ] Firebase Auth Email/Password enabled
- [ ] Firestore & Storage rules deployed
- [ ] Support email set (firebase-config.js + app.support_email)
- [ ] Website pushed to GitHub
- [ ] App Store Connect URLs set
- [ ] Stripe webhook correct
- [ ] FormGrid email → your inbox
