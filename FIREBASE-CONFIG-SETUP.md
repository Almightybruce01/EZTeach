# Firebase & Stripe Config Setup

**Never commit real keys to git.** Use Firebase config or environment variables.

---

## Step 1 — Get Your Keys

### SendGrid (for emails)
1. Go to **https://app.sendgrid.com** → Settings → API Keys
2. Create API Key (full access or "Mail Send" only)
3. Copy the key — it starts with `SG.`

### Stripe
- **Secret key:** https://dashboard.stripe.com/apikeys (use `sk_live_...` for production)
- **Webhook secret:** https://dashboard.stripe.com/webhooks → select your endpoint → "Signing secret"

---

## Step 2 — Set Firebase Config

Run these in Terminal (replace the values with your real keys):

```bash
cd /Users/brianbruce/Desktop/EZTeach

# SendGrid (required for welcome emails, support, receipts)
firebase functions:config:set sendgrid.api_key="SG.YOUR_ACTUAL_SENDGRID_KEY"

# Stripe (required for subscriptions)
firebase functions:config:set stripe.secret_key="sk_live_YOUR_STRIPE_SECRET_KEY"
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_STRIPE_WEBHOOK_SECRET"

# Support email (optional — where support claims go)
firebase functions:config:set app.support_email="your@email.com"
```

---

## Step 3 — Deploy Functions

```bash
firebase deploy --only functions
```

---

## Step 4 — Verify

1. **SendGrid:** Create a test account in the app → you should get a welcome email.
2. **Stripe:** Go to https://dashboard.stripe.com/webhooks — ensure your endpoint is configured:
   - URL: `https://us-central1-ezteach-cdf5c.cloudfunctions.net/stripeWebhook`
   - Events: `checkout.session.completed`, `invoice.paid`, `invoice.payment_failed`, `customer.subscription.deleted`

---

## View Current Config (to check what’s set)

```bash
firebase functions:config:get
```

---

## Twilio

You mentioned Twilio. EZTeach uses **SendGrid** for email, not Twilio (SMS/voice). If you want SMS notifications later, you’d add Twilio separately. For now, focus on SendGrid and Stripe.
