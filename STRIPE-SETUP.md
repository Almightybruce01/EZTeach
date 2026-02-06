# Stripe Setup for EZTeach

## How do you want to accept payments?

**Choose: Prebuilt checkout form**

EZTeach uses Stripe Checkout—a Stripe-hosted page. When users tap "Subscribe Now," the app opens a Stripe checkout URL in the browser. That is the **Prebuilt checkout form** option.

---

## Firebase Functions Config (required)

Run these in your terminal (from the EZTeach project folder):

### 1. Stripe secret key (required)

**Do not share or paste your secret key anywhere.** Run this locally:

```bash
firebase functions:config:set stripe.secret_key="sk_live_YOUR_SECRET_KEY_HERE"
```

- Use `sk_live_...` for live payments, or `sk_test_...` for testing
- Get it from: https://dashboard.stripe.com/apikeys

### 2. Stripe webhook secret (required)

```bash
firebase functions:config:set stripe.webhook_secret="whsec_0HPIzYtYKS9m7eJVpg7CheLs1ANcdahB"
```

### 3. Deploy functions

```bash
firebase deploy --only functions
```

---

## What you shared

| Item | Value | Where it goes |
|------|-------|----------------|
| **Webhook signing secret** | whsec_0HPIzYtYKS9m7eJVpg7CheLs1ANcdahB | `stripe.webhook_secret` (see above) |
| **Publishable key** | pk_live_51SudB8... | Not used in current setup (server-side flow only) |
| **Secret key** | sk_live_... | `stripe.secret_key` — set via config, never commit |

---

## Live vs test mode

- **pk_live_** / **sk_live_** = real charges
- **pk_test_** / **sk_test_** = test mode (use test card 4242 4242 4242 4242)

Use **test mode** while developing. Switch to **live** when you’re ready for real payments.

---

## Code changes made

1. **Product IDs removed** – Uses `product_data` so no products need to be created in Stripe.
2. **User email check** – Returns a clear error if the user account has no email.
3. **Webhook** – Already correctly wired for `checkout.session.completed`, `invoice.paid`, etc.
