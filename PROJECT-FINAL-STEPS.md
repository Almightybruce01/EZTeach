# EZTeach — Project Final Steps

---

## Complete Setup Commands

Run these in Terminal in order:

```bash
cd /Users/brianbruce/Desktop/EZTeach

# 1. SendGrid (replace with your actual key from SendGrid — starts with SG.)
firebase functions:config:set sendgrid.api_key="SG.YOUR_FULL_KEY_HERE"

# 2. Stripe
firebase functions:config:set stripe.secret_key="sk_live_YOUR_STRIPE_SECRET_KEY_HERE"
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET_HERE"

# 3. Deploy
firebase deploy --only functions
```

---

## Step-by-Step

### Step 1 — Get SendGrid API Key

1. Go to **https://app.sendgrid.com** → Settings → API Keys
2. Click **Create API Key**
3. Name: `EZTeach Cloud Functions`
4. Permissions: **Mail Send** (Restricted Access)
5. Create & copy the key (starts with `SG.`) — you only see it once

### Step 2 — Verify Sender in SendGrid

1. Settings → Sender Authentication → Verify a Single Sender
2. Add and verify `ezteach0@gmail.com` (or your sender email)

### Step 3 — Run Config Commands

Use the commands in the box above. Replace `SG.YOUR_FULL_KEY_HERE` with your key.

### Step 4 — Deploy

```bash
firebase deploy --only functions
```

### Step 5 — Verify

- Create a test account in the app → you should get a welcome email
- Check `firebase functions:config:get` to confirm config is set

---

## Where SendGrid Is Used

The SendGrid API key is used by **Firebase Cloud Functions** (`functions/index.js`) for:

| Email Type | When Sent |
|------------|-----------|
| Welcome email | When any account is created (school, district, teacher, parent) |
| Student credentials | When a student with email is created |
| School admin notification | When a new student is added |
| Subscription confirmation | After Stripe payment succeeds |
| Payment receipt | After each invoice is paid |
| Payment failed | When Stripe payment fails |
| Billing reminder | 3 days before subscription renewal |
| Support claims | When user submits a claim in the app |
| Contact form | When someone submits the website contact form |

**Connection:** `firebase functions:config:get` → `sendgrid.api_key` → passed to `sgMail.setApiKey()` in `functions/index.js` line 31.

**From address:** `ezteach0@gmail.com` — must be verified in SendGrid.

---

## Step 1 — Create SendGrid API Key

1. Go to **https://app.sendgrid.com**
2. Sign in
3. Click **Settings** (gear) in the left sidebar
4. Click **API Keys**
5. Click **Create API Key**
6. **Name:** `EZTeach Cloud Functions`
7. **Permissions:**  
   - Choose **Restricted Access**  
   - Turn ON **Mail Send** (full access)
8. Click **Create & View**
9. **Copy the key immediately** — it starts with `SG.` and is about 69 characters. You cannot view it again later.
10. Store it somewhere safe (password manager, notes) until you run the config command.

---

## Step 2 — Verify Sender in SendGrid

The app sends from `ezteach0@gmail.com`. This address must be verified in SendGrid.

1. In SendGrid: **Settings** → **Sender Authentication**
2. Click **Verify a Single Sender**
3. Fill in:
   - **From Name:** EZTeach
   - **From Email:** ezteach0@gmail.com (or your real sender email)
   - **Reply To:** same or support@ezteach.org
   - **Company address:** your address
4. Click **Create**
5. Check that inbox and click the verification link

---

## Step 3 — Run Firebase Config Commands

Open Terminal and run (replace `SG.YOUR_KEY` with the key you copied):

```bash
cd /Users/brianbruce/Desktop/EZTeach

# SendGrid
firebase functions:config:set sendgrid.api_key="SG.YOUR_FULL_KEY_HERE"

# Stripe
firebase functions:config:set stripe.secret_key="sk_live_YOUR_STRIPE_SECRET_KEY_HERE"
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET_HERE"

# Optional: where support claims are sent
firebase functions:config:set app.support_email="ezteach0+support@gmail.com"
```

---

## Step 4 — Deploy Functions

```bash
firebase deploy --only functions
```

---

## Step 5 — Verify

1. **Welcome email:** Create a new test account in the app → you should receive a welcome email.
2. **Stripe webhook:** In Stripe Dashboard → Webhooks, confirm the endpoint URL is:
   - `https://us-central1-ezteach-cdf5c.cloudfunctions.net/stripeWebhook`
3. **Config check:**
   ```bash
   firebase functions:config:get
   ```
   You should see `sendgrid`, `stripe`, and `app` entries.

---

## Summary Checklist

- [ ] SendGrid API key created and copied
- [ ] Sender email verified in SendGrid
- [ ] `firebase functions:config:set sendgrid.api_key="SG.xxx"` run
- [ ] `firebase functions:config:set stripe.secret_key="sk_live_xxx"` run
- [ ] `firebase functions:config:set stripe.webhook_secret="whsec_xxx"` run
- [ ] `firebase deploy --only functions` run
- [ ] Test: create account → welcome email received
