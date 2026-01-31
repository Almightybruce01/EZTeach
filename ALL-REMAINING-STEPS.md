# EZTeach — All Remaining Steps (exact clicks)

Do these in order. Each step tells you exactly where to go and what to do.

---

## 0. Set up Google Sheets first (before connecting FormGrid)

**Do you need a premade table or template?**  
No. Use a **new blank sheet**. Your contact form sends **email** and **message** (FormGrid may add **timestamp**). You can add a header row yourself or leave it blank and let FormGrid add the first row when you connect.

**Steps:**

1. Go to **https://sheets.google.com** (or **Google Drive** → **New** → **Google Sheets**).
2. Create a **new blank spreadsheet**.
3. Name it (e.g. **EZTeach Contact Form**).
4. **Optional — add a header row** so columns are clear:
   - Row 1, cell **A1:** type **Date/Time**
   - Row 1, cell **B1:** type **Email**
   - Row 1, cell **C1:** type **Message**
   (If FormGrid sends different field names, the connection may create its own headers or map to these.)
5. **Add-ons:** You do **not** need any Google Sheets add-ons. FormGrid’s **Sheets** connection uses normal Google sign-in and writes rows directly. No “Form to Sheet” add-on, no paid add-ons.
6. Leave the sheet open or remember its name. You’ll select this sheet when you connect FormGrid in the next section.

**Summary:** New blank sheet → optional header row (Date/Time, Email, Message) → **no add-ons**.

---

## 1. FormGrid — Connect to that sheet

FormGrid shows: **Share link**, **Embed link**, **Connect webhook**, **Sheets**. There is no separate “Integration” or “Notifications” menu.

**Option A — Use Google Sheets (recommended, free)**  
1. In FormGrid, open your EZTeach contact form.  
2. Click **Connect webhook** or **Sheets** (or whatever option says “Google Sheets” / “Connect to Sheets”).  
3. Connect to a Google Sheet (create one if needed).  
4. New form submissions will appear as new rows in that sheet.  
5. Bookmark the sheet or turn on email notifications in Google Sheets (File → Share → “Notify people”) so you get notified of new rows, or just check the sheet when you need to.

**Option B — Use Connect webhook to get emails**  
1. In FormGrid, open your form.  
2. Click **Connect webhook**.  
3. You’ll need a URL that accepts POST requests and then sends you an email. That’s a small Cloud Function (not set up yet). If you want this, we can add a “formGridWebhook” function that receives the submission and emails **ezteach0+support@gmail.com**.  
4. For now, **Option A (Sheets)** is enough to see all contact form submissions.

**Embed link**  
- Your site already uses the embed: `https://share.formgrid.com/embed/KJRfUkF4NMnWlHhQ` in `index.html`. No change needed unless you create a new form.

---

## 2. Gmail — Support filter

1. Go to **https://mail.google.com**, sign in as **ezteach0@gmail.com**.  
2. In the search box, click the **down arrow** (show search options).  
3. In **To**, type: `ezteach0+support@gmail.com`  
4. Click **Create filter**.  
5. Check **Apply the label** → choose **Support** (create the label if it doesn’t exist).  
6. Click **Create filter**.

All support emails (e.g. from in-app claims) will show under the **Support** label.

---

## 3. Firebase Auth — Enable Email/Password

1. Go to **https://console.firebase.google.com**.  
2. Select project **ezteach-cdf5c**.  
3. Left sidebar: **Build** → **Authentication**.  
4. Open the **Sign-in method** tab.  
5. Click **Email/Password**.  
6. Turn **Enable** ON.  
7. Click **Save**.

---

## 4. App Store Connect — Support / Marketing / Privacy URLs

1. Go to **https://appstoreconnect.apple.com**.  
2. **My Apps** → **EZTeach**.  
3. Left sidebar: **App Information**.  
4. Set:
   - **Support URL:** `https://ezteach.org/support.html`  
   - **Marketing URL:** `https://ezteach.org`  
   - **Privacy Policy URL:** `https://ezteach.org/privacy.html`  
5. Click **Save**.

---

## 5. Stripe — Webhook and config

**Is Stripe “finished”?**  
- **In code:** Yes. The app calls `createCheckoutSession`; the function `stripeWebhook` handles `checkout.session.completed`, `invoice.paid`, `invoice.payment_failed`, `customer.subscription.deleted` and updates Firestore and sends emails.  
- **What you must do:** Configure Stripe Dashboard and Firebase so the webhook and keys are set.

**5a. Stripe Dashboard — Webhook**  
1. Go to **https://dashboard.stripe.com/webhooks**.  
2. Click **Add endpoint**.  
3. **Endpoint URL:** `https://us-central1-ezteach-cdf5c.cloudfunctions.net/stripeWebhook`  
4. Under **Select events to listen to**, add:
   - `checkout.session.completed`  
   - `invoice.paid`  
   - `invoice.payment_failed`  
   - `customer.subscription.deleted`  
5. Click **Add endpoint**.  
6. Open the new webhook → **Reveal** signing secret → copy it (starts with `whsec_`).

**5b. Firebase — Stripe keys**  
1. In Stripe Dashboard: **Developers** → **API keys**. Copy the **Secret key** (starts with `sk_live_` or `sk_test_`).  
2. In a terminal:
   ```bash
   cd /Users/brianbruce/Desktop/EZTeach
   firebase functions:config:set stripe.secret_key="sk_xxx"
   firebase functions:config:set stripe.webhook_secret="whsec_xxx"
   ```
   Replace `sk_xxx` and `whsec_xxx` with your real values.  
3. Redeploy:
   ```bash
   firebase deploy --only functions
   ```

**5c. Stripe — Products**  
1. **Dashboard** → **Product catalog**.  
2. You need two products (or two prices):
   - **School monthly:** $75/month (recurring).  
   - **School yearly:** $750/year (recurring).  
3. Your code uses product IDs `prod_TsvP71E7nTlzCb` (monthly) and `prod_TsvTxl5KTc3bcB` (yearly). If those IDs are from your Stripe account, leave the code as is. If you created new products, update those constants in `functions/index.js` (lines 30–31) and redeploy.

---

## 6. Quick checklist

| # | What | Where | Done? |
|---|------|--------|-------|
| 1 | FormGrid: connect Sheets (or webhook later) | formgrid.com → your form → Sheets | |
| 2 | Gmail filter for ezteach0+support@gmail.com | mail.google.com → Create filter | |
| 3 | Firebase Auth: Email/Password enabled | Firebase Console → Authentication | |
| 4 | App Store Connect: Support / Marketing / Privacy URLs | appstoreconnect.apple.com → EZTeach → App Information | |
| 5a | Stripe webhook URL + events + signing secret | dashboard.stripe.com → Webhooks | |
| 5b | Firebase: stripe.secret_key + stripe.webhook_secret + deploy | Terminal | |
| 5c | Stripe products: $75/mo and $750/yr (or update IDs in code) | Stripe → Product catalog | |

---

**Stripe summary:** The payment integration in your app and Cloud Functions is complete. To finish it, you only need: add the webhook in Stripe, set `stripe.secret_key` and `stripe.webhook_secret` in Firebase, deploy functions, and ensure the two subscription products/prices exist in Stripe (or update the product IDs in `functions/index.js`).
