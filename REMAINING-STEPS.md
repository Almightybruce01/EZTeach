# EZTeach — Remaining Steps (for you)

Done automatically:
- ✅ Support email set to ezteach0@gmail.com (website + Cloud Functions)
- ✅ Firebase functions deployed
- ✅ Firestore rules deployed
- ✅ Storage rules deployed
- ✅ Website changes committed (push failed—run `git push` yourself)

---

## What you must do

### 0. Push website (if not done)
```bash
cd /Users/brianbruce/Desktop/EZTeach/ezteach-website
git push
```

### 1. Firebase Auth
https://console.firebase.google.com → **ezteach-cdf5c** → **Build** → **Authentication** → **Sign-in method** → **Email/Password** → Enable → **Save**

### 2. App Store Connect
https://appstoreconnect.apple.com → **My Apps** → **EZTeach** → **App Information**
- Support URL: https://ezteach.org/support.html
- Marketing URL: https://ezteach.org
- Privacy Policy URL: https://ezteach.org/privacy.html
- **Save**

### 3. Stripe webhook
https://dashboard.stripe.com/webhooks
- URL: `https://us-central1-ezteach-cdf5c.cloudfunctions.net/stripeWebhook`
- Events: checkout.session.completed, invoice.paid, invoice.payment_failed, customer.subscription.deleted

### 4. FormGrid
In FormGrid dashboard → your contact form → set email notifications to **ezteach0+support@gmail.com**  
(See SUPPORT-SETUP.md for Gmail filter + AI response instructions.)
