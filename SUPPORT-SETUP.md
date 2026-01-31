# EZTeach Support Setup

All support goes through **two channels only**—no direct email to your company inbox:

1. **Website:** Contact form (FormGrid) on ezteach.org  
2. **App:** Support claims (Firestore → Cloud Function emails you)

Both send to **ezteach0+support@gmail.com** so you can filter and use AI to help respond.

---

## How it works

| Source       | Where it goes                                |
|--------------|-----------------------------------------------|
| Website form | FormGrid → email notification → your Gmail   |
| In-app claim | Firestore → Cloud Function → SendGrid → your Gmail |

All support emails arrive at **ezteach0+support@gmail.com** (same inbox as ezteach0@gmail.com, easy to filter).

---

## Your setup steps

### 1. FormGrid

1. Go to https://formgrid.com and open your EZTeach contact form.
2. **Notifications** / **Email notifications** → add notification.
3. Set recipient: **ezteach0+support@gmail.com**
4. Save.

### 2. Firebase (already done)

- Cloud Function `onSupportClaimCreated` sends to **ezteach0+support@gmail.com** with subject `[EZTeach Support] New Claim: ...`

### 3. Gmail filter for support

1. Gmail → **Settings** (gear) → **See all settings** → **Filters and Blocked Addresses**.
2. **Create a new filter**.
3. In **To**, enter: `ezteach0+support@gmail.com`
4. **Create filter**.
5. Choose:
   - Apply label: **Support** (create label if needed)
   - Optional: Star it, mark as important
6. **Create filter**.

Result: all support emails go into the **Support** label.

### 4. Using AI to respond

**Option A — Gmail “Help me write” (Gemini)**  
1. Open an email in the Support label.  
2. Click **Reply** → click the sparkle icon (✧) or “Help me write”.  
3. Ask it to draft a response (e.g. “draft a friendly reply to this support request”).  
4. Edit and send.

**Option B — AI extensions**  
Use a Chrome extension (e.g. Grammarly, or any AI assistant) while replying in Gmail.

**Option C — Later: FormGrid webhook + Cloud Function (paid)**  
On FormGrid Business ($29/mo) you can add a webhook to your form. That webhook could trigger a Cloud Function that uses AI to auto-respond. Not required for now.

---

## What was changed in your project

- **Website:** All direct `mailto:` links removed. Contact form is the only way to reach you from the site.
- **support.html:** Text updated to say “use the contact form on the homepage.”
- **index.html:** Contact section updated to point only to the form.
- **privacy.html:** Privacy questions directed to the contact form.
- **iOS app:** “Email Support” changed to “Submit a Claim”; `support@ezteach.org` removed.
- **Firebase:** Support email set to **ezteach0+support@gmail.com**; subject prefix `[EZTeach Support]` added for filtering.
