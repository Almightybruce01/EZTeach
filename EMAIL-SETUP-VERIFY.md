# EZTeach Email Setup — Verification

## Current Email Setup

These Cloud Functions send emails (via SendGrid):

| Trigger | When | Who Gets Email |
|---------|------|----------------|
| **onUserCreated** | Any account created (school, district, teacher, parent) | The new user (welcome) |
| **onStudentCreated** | Student added to school | School admin only; linked parents (if any) |
| **stripeWebhook** | Payment success/fail | School/district admin |
| **onSupportClaimCreated** | User submits support claim | Your support email |
| **formGridWebhook** | Website contact form | Your support email |
| **sendBillingReminders** | 3 days before renewal | School admin |

**Students do not need emails.** No credentials are sent to students. Notifications go to school admin and to parents (when they’re already linked).

---

## Verify Your Setup

### 1. Check Firebase config

```bash
firebase functions:config:get
```

You should see:
- `sendgrid.api_key` — your SendGrid key (starts with `SG.`)
- `stripe.secret_key`
- `stripe.webhook_secret`

If `sendgrid.api_key` is missing or shows `SG.placeholder`, run:

```bash
firebase functions:config:set sendgrid.api_key="SG.YOUR_ACTUAL_KEY"
firebase deploy --only functions
```

### 2. Verify sender in SendGrid

1. Go to https://app.sendgrid.com → Settings → Sender Authentication
2. Confirm `ezteach0@gmail.com` (or your FROM_EMAIL) is verified

### 3. Quick test

1. Create a new test account in the app
2. Check that account’s email for the welcome message

---

## What Was Simplified

- **Removed:** Sending login credentials to students via email
- **Kept:** School admin notification when a student is added
- **Added:** Parent notification when a student is added (if parents are already linked)
- **Merged:** Duplicate `onStudentCreated` functions (password hash + admin email) into one
