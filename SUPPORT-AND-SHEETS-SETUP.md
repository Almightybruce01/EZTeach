# Support & Contact Form Setup (Professional, Minimal Work)

## Status Check

| Item | Status |
|------|--------|
| **Payment (Stripe)** | ✅ Done — createCheckoutSession, stripeWebhook, config set |
| **Support email** | ✅ ezteach0+support@gmail.com (firebase-config + Cloud Functions) |
| **In-app claims** | ✅ Firestore → onSupportClaimCreated → SendGrid → your email |
| **Contact form (website)** | FormGrid embed on site; see below for email delivery |
| **FormGrid webhook** | ✅ New Cloud Function `formGridWebhook` — forwards to email |

---

## One-Time Setup (Do Once)

### 1. Deploy the new FormGrid webhook

```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only functions
```

### 2. SendGrid (for support emails)

Support emails (in-app claims + contact form) use SendGrid. You need:

1. **SendGrid API key**
   - https://app.sendgrid.com → Settings → API Keys → Create API Key
   - Copy the key (starts with `SG.`)

2. **Verify sender (noreply@ezteach.org)**
   - https://app.sendgrid.com → Settings → Sender Authentication
   - Verify single sender or domain for `noreply@ezteach.org`

3. **Set Firebase config**
   ```bash
   firebase functions:config:set sendgrid.api_key="SG.your_key_here"
   firebase deploy --only functions
   ```

### 3. FormGrid — Connect webhook (optional but recommended)

- Go to **https://formgrid.com** → your EZTeach contact form
- Click **Connect webhook** (or similar)
- **Webhook URL:** `https://us-central1-ezteach-cdf5c.cloudfunctions.net/formGridWebhook`
- Save

Result: Website contact submissions are emailed to **ezteach0+support@gmail.com** and saved in Firestore `contactFormSubmissions`.

### 4. FormGrid — Google Sheets (optional backup)

If you also want submissions in a sheet:

1. Create a blank Google Sheet (e.g. "EZTeach Contact Form")
2. In FormGrid → **Sheets** → connect that sheet
3. New rows appear for each submission (no add-ons needed for this)

### 5. Gmail filter (for support inbox)

1. Gmail → Search options (down arrow) → **To:** `ezteach0+support@gmail.com`
2. Create filter → Apply label **Support**
3. Use Gmail "Help me write" when replying for AI-assisted responses

---

## What Goes Where

| Source | Where it goes |
|--------|----------------|
| **Website contact form** | FormGrid → formGridWebhook → Firestore + email to ezteach0+support@gmail.com |
| **In-app support claims** | Firestore supportClaims → onSupportClaimCreated → email to ezteach0+support@gmail.com |
| **FormGrid Sheets** | Optional — if connected, submissions also appear in the sheet |

All support ends up at **ezteach0+support@gmail.com**. No direct mailto links on the site.

---

## Remaining Steps (Your Checklist)

1. [ ] Run `firebase deploy --only functions` (deploys formGridWebhook)
2. [ ] Get SendGrid API key and verify noreply@ezteach.org
3. [ ] Run `firebase functions:config:set sendgrid.api_key="SG.xxx"` and redeploy
4. [ ] In FormGrid, add webhook URL: `https://us-central1-ezteach-cdf5c.cloudfunctions.net/formGridWebhook`
5. [ ] Create Gmail filter for ezteach0+support@gmail.com → label "Support"
