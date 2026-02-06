# Subscription Payment Troubleshooting

## Why "Internal" Error When Paying?

When you tap "Subscribe Now" and see an **internal** or **Internal error** message, it means the `createCheckoutSession` Cloud Function threw an error before returning the Stripe checkout URL. The function catches errors and rethrows them as `HttpsError('internal', error.message)`.

### Most Likely Causes (in order)

1. **Stripe secret key not configured or invalid**
   - The function uses: `functions.config().stripe?.secret_key || 'sk_test_placeholder'`
   - If you haven't set it, Stripe API calls will fail.

   **Fix:** Run:
   ```bash
   firebase functions:config:set stripe.secret_key="sk_test_YOUR_ACTUAL_KEY"
   ```
   Then redeploy: `firebase deploy --only functions`

   Get your key from: https://dashboard.stripe.com/test/apikeys

2. **Stripe product IDs don't exist in your account**
   - The code uses: `prod_TsvP71E7nTlzCb` (monthly) and `prod_TsvTxl5KTc3bcB` (yearly)
   - These might be from a template and not exist in **your** Stripe account.

   **Fix:** In Stripe Dashboard → Products, create products for:
   - School Monthly: $75/month recurring
   - School Yearly: $750/year recurring
   
   Then update `functions/index.js` with your real product IDs (lines 30–31).

3. **User document missing email**
   - `createCheckoutSession` calls `stripe.customers.create({ email: userData.email })`
   - If the user's Firestore document has no `email` field, Stripe will reject the request.

   **Fix:** Ensure users have `email` in their `/users/{uid}` document (usually set at signup).

4. **Webhook secret (for after payment)**
   - The webhook that activates subscriptions when payment completes needs:
   ```bash
   firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
   ```
   - Without this, the webhook won't verify Stripe events (but this doesn't cause the "internal" error at checkout—only subscription not activating after payment).

### Not Related to App Store

Running from Xcode on a physical device works fine for subscriptions. The "internal" error happens **before** Stripe Checkout opens—it's a server-side (Cloud Function) error, not an iOS or App Store issue.

### How to See the Real Error

1. **Firebase Console:** Functions → Logs → look for errors when you tap Subscribe.
2. **Or** temporarily improve the iOS error display in `SubscriptionView.swift`—the `error.localizedDescription` might show more detail if the Functions error includes it.
3. **Stripe Dashboard:** Developers → Logs — check for failed API requests.
