# App Store Subscription Compliance

## What Changed (Website-First Strategy)

The iOS app has been restructured to comply with Apple's App Store policy:

- **No prices** displayed in the app
- **No "Subscribe", "Buy", "Upgrade", or "Unlock"** buttons
- **No in-app payment** — all subscription management happens on the website
- **Neutral language** — "Manage Account", "View Plans", "Plans available on our website"

## In-App Flow

1. **Account** → Shows account status (Active / Inactive)
2. **Manage Account** → Opens Safari to **https://ezteach.org**
3. Users complete signup, payment, and subscription on your website

## Website Requirements

Your website (ezteach.org) **must** provide:

1. **Sign up / Create account** — with Stripe checkout for subscription
2. **Sign in** — so users can log into the app after creating an account
3. **Subscription management** — view plan, update payment, cancel

Recommended flow on the website:

1. User lands on ezteach.org
2. Clicks "Sign Up" or "Get Started"
3. Creates account + pays via Stripe
4. Returns to app, signs in with same credentials
5. App checks Firestore for `subscriptionActive` → unlocks features

## Key Wording (App Store Safe)

| Use | Avoid |
|-----|-------|
| "Manage Account" | "Subscribe" |
| "View Plans" | "Upgrade" |
| "Plans available on our website" | "Unlock premium" |
| "Some features require an active account" | "Subscribe to unlock" |
| "Sign in to access your account" | "Buy now" |

## Backend (Unchanged)

- Stripe webhooks still update Firestore (`subscriptionActive`, etc.)
- App reads subscription status from Firestore on launch
- No payment logic in the app

## URL Used in App

- **Account management:** https://ezteach.org

Update `accountManagementURL` in `SubscriptionView.swift` and the hardcoded URL in `DistrictSubscriptionView.swift` if your plans/billing live at a different path (e.g. https://ezteach.org/plans).
