# EZTeach – Setup & Production Steps

**Pricing:** $75/mo per school • $750/yr (save ~17%). District tiers: 72/68/64/60 per school/mo.  
**Promo codes:** Complex codes (see §4.3)—**keep private**; don’t publish on the website. Apply at checkout for **yearly only**; one use per school/account.

---

## 1. FormGrid (website contact form)

FormGrid **only** receives contact form submissions. It does **not** send signup, password-reset, or payment emails.

**See `ezteach-website/FORMGRID-STEPS.md`** for setup.

1. Contact form uses the **FormGrid embed** (iframe). Embed URL: `https://share.formgrid.com/embed/KJRfUkF4NMnWlHhQ` — already in `index.html`.
2. **Keep & deploy** your site changes (GitHub → Netlify).
3. **Test** on **https://** or **http://localhost** (not **file://**).
4. In FormGrid (formgrid.dev or formgrid.com), open your form → **Submissions** to see responses.
5. Optional: form **settings** → **Email** / **Sheets** / **Webhook** → e.g. **support@ezteach.org**.

---

## 2. App emails (signup, password reset, payments)

- **Signup / password reset:** Firebase Auth (already in app).
- **Payment confirmations, receipts, subscription emails:** Stripe (+ Cloud Functions).
- **Custom emails** (welcome, billing reminders): SendGrid (or similar) via Cloud Functions.

FormGrid is **not** used for any of these.

---

## 3. Stripe (subscriptions & payments)

### 3.1 Stripe Dashboard

1. **https://dashboard.stripe.com** → sign up / log in.
2. **Products** → **Add product**:
   - **School monthly:** $75/month recurring.
   - **School yearly:** $750/year recurring.
3. Create a **Price** for each (monthly / yearly).
4. Copy each **Price ID** (e.g. `price_xxx`).

### 3.2 Cloud Functions

1. Set config:
   ```bash
   cd /Users/brianbruce/Desktop/EZTeach
   firebase functions:config:set stripe.secret_key="sk_live_xxx"
   firebase functions:config:set stripe.webhook_secret="whsec_xxx"
   ```
2. In **`functions/index.js`**:
   - `createCheckoutSession`: use your **Price IDs** for school monthly/yearly.
   - `createDistrictCheckout`: district pricing uses $75 base and tier logic (72/68/64/60).
3. **Webhook:** Stripe Dashboard → Developers → Webhooks → Add endpoint:
   - URL: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/stripeWebhook`
   - Events: `checkout.session.completed`, `invoice.paid`, `invoice.payment_failed`, `customer.subscription.deleted`.
4. Copy **Signing secret** → `stripe.webhook_secret` in config.
5. Deploy:
   ```bash
   firebase deploy --only functions
   ```

### 3.3 App ↔ Stripe

- **School subscriptions:** App calls `createCheckoutSession` with `priceId` (monthly or yearly). User completes Stripe Checkout; webhook updates Firestore.
- **District subscriptions:** App creates district doc; Cloud Function `onDistrictCreated` links schools and user. Use `createDistrictCheckout` when you wire Stripe for districts.

---

## 4. Firebase (Auth, Firestore, Storage)

### 4.1 Auth

- Firebase Console → **Authentication** → **Sign-in method** → **Email/Password** → Enable.

### 4.2 Firestore & Storage rules

1. Deploy rules:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only storage
   ```
2. Rules in repo: **`firestore.rules`**, **`storage.rules`**. They cover `subReviews`, `recommendedActivities`, `conversations`/`messages`, districts (`ownerUid`), etc.

### 4.3 Promo codes (Firestore)

Use **complex, hard-to-guess** codes. **Keep them private**—don’t post on the website or in public channels.

1. Create **`promoCodes`** collection.
2. Add documents (**document ID = the exact code**, case-sensitive). Example:
   - **100% off yearly** — doc ID: `EZT6X7K2M9QPN4LR`  
     Fields: `{ isActive: true, yearlyOnly: true, discountPercent: 1, description: "100% off yearly" }`
   - **25% off yearly** — doc ID: `EZT4Y9N2QR7LKP3M`  
     Fields: `{ isActive: true, yearlyOnly: true, discountPercent: 0.25, description: "25% off yearly" }`
3. Share codes only via secure channels (email, direct message). App validates via `promoCodes` and records usage in **`promoCodeUsage`** (userId, schoolId when applicable).
4. To rotate codes: add new docs with new IDs, set `isActive: false` on old ones.  
5. **Generate your own:** 14–20 char alphanumeric (e.g. `EZT` + random like `6X7K2M9QPN4LR`). App looks up by **uppercase** string; use consistent casing in Firestore.

---

## 5. District subscriptions (choose schools first)

- **Flow:** District name → **Add schools** (link by 6‑digit code or create new) → Pay.
- **Link existing:** Enter code → lookup → add. If school already has `districtId`, show “Already in another district.”
- **Create new:** “Create new school” → form (name, address, city, state, zip) → school created with generated code → added to list.
- **Payment:** Only after ≥1 school. Cloud Function **`onDistrictCreated`** runs when district doc is created; it links those schools and the owner user. No client-side batch writes to schools.
- **Private schools:** Sign up and pay on their own; they are not added to a district.

---

## 6. Website (ezteach.org)

### 6.1 Local files

- **`ezteach-website/`**: `index.html`, `login.html`, `dashboard.html`, `styles.css`, `app.js`, `firebase-config.js`, `privacy.html`, `support.html`, etc.
- **Pricing:** $75/mo, $750/yr. **Contact form:** FormGrid embed (see §1 and **FORMGRID-STEPS.md**).
- **`firebase-config.js`:** Your Firebase web app config (Console → Project settings → Your apps → Web).

### 6.2 Deploy (GitHub → Netlify)

1. **GitHub:** Create a repo (e.g. `ezteach-website`). Push the contents of **`ezteach-website/`** (not the EZTeach Xcode project).
2. **Netlify:** https://www.netlify.com → Add new site → **Import from Git** → choose repo.
3. **Build settings:**
   - Build command: *(leave empty)*
   - Publish directory: `/` (or root where `index.html` lives).
4. Deploy. Note the Netlify URL (e.g. `xxx.netlify.app`).
5. **Custom domain:** Netlify → Domain settings → Add **ezteach.org** (and `www`). Follow DNS instructions at your registrar (e.g. Namecheap).

### 6.3 Updating the site

- **Option A:** Edit files in **`ezteach-website/`**, then:
  ```bash
  cd ezteach-website
  git add -A && git commit -m "Update site" && git push
  ```
  If Netlify is connected to the repo, it will auto-deploy.
- **Option B:** Netlify CLI: `netlify deploy --prod` from the site directory.

**We can update the files in your project;** you still need to **push to GitHub** (or deploy via Netlify CLI) for the live site to change.

---

## 7. In‑app messaging

- Messaging uses **Firestore** (`conversations`, `messages`). No separate “messaging platform” to configure.
- Ensure **`createdByUserId`** is set when creating a conversation (already in app). Firestore rules use it for delete.

---

## 8. App Store Connect

- **Support URL:** `https://ezteach.org/support.html`
- **Marketing URL:** `https://ezteach.org`
- **Privacy Policy URL:** `https://ezteach.org/privacy.html`
- Replace the App Store badge link in **`index.html`** with your real app URL once live.

---

## 9. Production checklist

- [ ] FormGrid: embed in **`index.html`**; keep & deploy; optional email notifications set.
- [ ] **`firebase-config.js`** has your Firebase web config; Email/Password auth enabled.
- [ ] Stripe: products $75/mo and $750/yr; Price IDs in Cloud Functions; webhook configured; `stripe.secret_key` and `stripe.webhook_secret` set.
- [ ] **`firebase deploy --only functions`** and **`firebase deploy --only firestore:rules`** and **`firebase deploy --only storage`**.
- [ ] Promo codes in **`promoCodes`**; app applies them to yearly only and records usage.
- [ ] District flow: add schools first (link or create), then pay; **`onDistrictCreated`** deployed.
- [ ] Website: $75/mo, $750/yr; FormGrid contact form; **ezteach.org** live via Netlify.
- [ ] App Store Connect: Support, Marketing, Privacy URLs → **ezteach.org**.

---

## Promo codes (reference)

| Code (example—use your own) | Effect   | When        |
|-----------------------------|----------|-------------|
| **EZT6X7K2M9QPN4LR**       | 100% off | Yearly only |
| **EZT4Y9N2QR7LKP3M**       | 25% off  | Yearly only |

- **Keep codes private.** Don’t publish on the website.
- One use per school/account. Applied at checkout for yearly plan.
- Doc ID in `promoCodes` must match the code exactly (case-sensitive).
