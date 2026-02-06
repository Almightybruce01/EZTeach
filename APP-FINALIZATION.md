# EZTeach — App Finalization Guide

## What Was Done

### 1. Video Meetings
- **Platform:** The app uses `https://meet.ezteach.app/{code}` as the meeting URL. You need to host a video conferencing solution at that domain (e.g., Jitsi Meet, Daily.co, or similar).
- **Camera & microphone permissions:** Added to Info.plist (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`). The app will prompt for permission when joining a meeting.
- **Recording:** VideoMeeting model already supports `isRecorded` and `recordingUrl`. Recording is handled by your video platform—configure it on the server/meet.ezteach.app side.
- **Rules:** Teachers/schools schedule meetings. Parents and students join when invited. No ad-hoc student–student or teacher–teacher calling; all meetings are scheduled by a teacher.

### 2. Staff Account Types (No Grade Required)
- **Principal, Assistant Principal, Assistant Teacher, Secretary** — New role options in Create Account.
- All create as "teacher" in Firestore with a `staffType` field (`principal`, `assistant_principal`, `assistant_teacher`, `secretary`).
- No grade assignment required; they join schools like other staff and don’t need to be assigned to a specific grade.

### 3. Subscription & Payment Cleanup
- **Removed:** In-app promo code entry, subscription discount UI, payment method picker (Apple Pay, PayPal, etc.).
- **Reason:** Payments go through Stripe Checkout. Stripe’s hosted page handles payment methods and any promo codes you configure there.
- **Flow:** User taps "Subscribe Now" → app calls `createCheckoutSession` → opens Stripe Checkout URL in Safari → user pays → webhook updates Firestore.

### 4. District Subscription
- Payment method picker removed. Uses Stripe as the single payment path.

---

## Finalize Your App — Checklist

### Before App Store

1. **Firebase**
   - Deploy rules: `firebase deploy --only firestore:rules`
   - Deploy functions: `firebase deploy --only functions`
   - Ensure `stripe.secret_key` and `stripe.webhook_secret` are set in Firebase config.

2. **Stripe**
   - Webhook URL: `https://us-central1-ezteach-cdf5c.firebaseapp.com/.../stripeWebhook` (or your project’s Cloud Functions URL).
   - Events: `checkout.session.completed`, `invoice.paid`, `invoice.payment_failed`, `customer.subscription.deleted`.
   - Products/prices for $75/mo and $750/yr (or update in `functions/index.js`).

3. **Video (meet.ezteach.app)**
   - Set up Jitsi Meet, Daily.co, or another solution at `meet.ezteach.app`.
   - Configure recording if you use it.
   - Ensure your domain is authorized in Firebase Auth if using email links.

4. **Test accounts**
   - Create at least one of each: school, district, teacher, principal, assistant principal, sub, parent.

5. **App Store Connect**
   - Screenshots, description, keywords (see APP-STORE-ASSETS.md).
   - Support URL, Privacy URL, Marketing URL.
   - Provide a test account for App Review.

### Optional: Promo Codes

Promo codes are no longer in the app UI. If you still want them:

- Add coupons in Stripe Dashboard (Stripe Checkout supports `allow_promotion_codes`).
- Or keep the Cloud Function logic and add a "Have a promo code?" link that opens a web page with a custom checkout URL including the code.

---

## Why Finalize?

- **Single payment path:** Stripe Checkout reduces in-app payment logic and keeps PCI scope on Stripe.
- **Cleaner UX:** No redundant payment method selection; Stripe’s page handles it.
- **Staff roles:** Principals, APs, secretaries, and assistant teachers can sign up without grade assignment.
- **Video:** Permissions are declared; you only need to host the actual video service.
