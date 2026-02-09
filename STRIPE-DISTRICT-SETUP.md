# Stripe & District Billing Setup Guide

## Overview

This guide covers how to set up Stripe for EZTeach subscriptions, configure discount codes, and ensure district billing works correctly so schools are properly tracked and no money is lost.

---

## 1. Stripe Dashboard Setup

### Create Your Stripe Account
1. Go to https://dashboard.stripe.com
2. Create an account or log in
3. Complete identity verification
4. Enable live mode when ready for production

### Create Products

Create these products in Stripe:

#### Individual School Subscription
- **Name**: EZTeach School Subscription
- **Price**: $75/month (or your preferred price)
- **Billing**: Monthly recurring

#### District Subscriptions (Tiered Pricing)
Create a single product with multiple prices:

- **Name**: EZTeach District Subscription

**Price Tiers:**
| Schools | Price/School/Month | Stripe Price ID |
|---------|-------------------|-----------------|
| 1-5     | $60               | price_small_xxx |
| 6-15    | $50               | price_medium_xxx |
| 16-50   | $40               | price_large_xxx |
| 51+     | $30               | price_enterprise_xxx |

---

## 2. Setting Up Discount Codes (Coupons)

### In Stripe Dashboard:

1. Go to **Products** → **Coupons**
2. Click **Create coupon**

### Recommended Coupon Types:

#### Percentage Off
```
Name: WELCOME20
Type: Percentage
Value: 20% off
Duration: Once (first month only)
```

#### Fixed Amount Off
```
Name: SAVE50
Type: Fixed amount
Value: $50 off
Duration: Once
```

#### Free Trial
```
Name: FREETRIAL30
Type: Percentage
Value: 100% off
Duration: Repeating (1 month)
```

#### Partner/Referral Codes
```
Name: PARTNER2024
Type: Percentage
Value: 25% off
Duration: Forever
Redemption limit: 100
```

### Promotion Codes
After creating coupons, create **Promotion Codes**:
1. Go to each coupon
2. Click "Create promotion code"
3. Set the code customers will enter (e.g., "WELCOME20")
4. Set restrictions (min amount, first-time only, etc.)

---

## 3. Website Checkout Integration

### Checkout URL Structure

Your app sends users to your website with this URL format:

```
https://ezteach.org/checkout/district?name=DISTRICT_NAME&schools=SCHOOL_ID1,SCHOOL_ID2&count=2
```

**Parameters:**
- `name`: URL-encoded district name
- `schools`: Comma-separated list of school IDs being paid for
- `count`: Number of schools

### Website Checkout Flow

Create a checkout page at `/checkout/district` that:

1. **Parses URL parameters** to get district info
2. **Displays selected schools** for confirmation
3. **Calculates pricing** based on school count
4. **Creates Stripe Checkout Session** with:
   - Correct price based on tier
   - School IDs in metadata
   - District name in metadata
   - Customer email

### Sample Website Code (Node.js/Express)

```javascript
// /checkout/district route
app.get('/checkout/district', async (req, res) => {
  const { name, schools, count } = req.query;
  
  const schoolIds = schools ? schools.split(',') : [];
  const schoolCount = parseInt(count) || schoolIds.length;
  
  // Calculate tier pricing
  let priceId;
  let pricePerSchool;
  
  if (schoolCount <= 5) {
    priceId = 'price_small_xxx';
    pricePerSchool = 60;
  } else if (schoolCount <= 15) {
    priceId = 'price_medium_xxx';
    pricePerSchool = 50;
  } else if (schoolCount <= 50) {
    priceId = 'price_large_xxx';
    pricePerSchool = 40;
  } else {
    priceId = 'price_enterprise_xxx';
    pricePerSchool = 30;
  }
  
  const totalPrice = pricePerSchool * schoolCount;
  
  res.render('district-checkout', {
    districtName: decodeURIComponent(name),
    schoolIds,
    schoolCount,
    pricePerSchool,
    totalPrice,
    priceId
  });
});

// Create checkout session
app.post('/create-checkout-session', async (req, res) => {
  const { districtName, schoolIds, pricePerSchool, count } = req.body;
  
  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    mode: 'subscription',
    line_items: [{
      price_data: {
        currency: 'usd',
        product: 'prod_district_xxx',
        unit_amount: pricePerSchool * 100, // cents
        recurring: { interval: 'month' }
      },
      quantity: count
    }],
    allow_promotion_codes: true, // Enable discount codes
    metadata: {
      type: 'district',
      districtName: districtName,
      schoolIds: schoolIds.join(','),
      schoolCount: count
    },
    success_url: 'https://ezteach.org/success?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: 'https://ezteach.org/checkout/district'
  });
  
  res.json({ url: session.url });
});
```

---

## 4. Webhook Handler (Critical for Tracking)

### Set Up Webhook in Stripe Dashboard

1. Go to **Developers** → **Webhooks**
2. Click **Add endpoint**
3. Enter your webhook URL: `https://ezteach.org/api/webhooks/stripe`
4. Select events:
   - `checkout.session.completed`
   - `invoice.paid`
   - `invoice.payment_failed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`

### Webhook Handler Code

```javascript
// Firebase Cloud Function
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;
  
  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('Webhook signature verification failed');
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  const db = admin.firestore();
  
  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object;
      const metadata = session.metadata;
      
      if (metadata.type === 'district') {
        // District subscription
        const schoolIds = metadata.schoolIds.split(',');
        const districtName = metadata.districtName;
        
        // Create or update district document
        const districtRef = db.collection('districts').doc();
        await districtRef.set({
          name: districtName,
          schoolIds: schoolIds,
          stripeCustomerId: session.customer,
          stripeSubscriptionId: session.subscription,
          subscriptionActive: true,
          schoolCount: schoolIds.length,
          billedSchoolIds: schoolIds, // CRITICAL: Track which schools are paid for
          subscriptionStartDate: admin.firestore.Timestamp.now(),
          lastPaymentDate: admin.firestore.Timestamp.now()
        });
        
        // Mark each school as covered by district
        const batch = db.batch();
        for (const schoolId of schoolIds) {
          const schoolRef = db.collection('schools').doc(schoolId);
          batch.update(schoolRef, {
            districtId: districtRef.id,
            subscriptionActive: true,
            subscriptionSource: 'district',
            districtBillingActive: true
          });
        }
        await batch.commit();
        
        console.log(`District ${districtName} created with ${schoolIds.length} schools`);
      }
      break;
    }
    
    case 'invoice.paid': {
      const invoice = event.data.object;
      const subscriptionId = invoice.subscription;
      
      // Find district by subscription
      const districtSnap = await db.collection('districts')
        .where('stripeSubscriptionId', '==', subscriptionId)
        .get();
      
      if (!districtSnap.empty) {
        const districtDoc = districtSnap.docs[0];
        await districtDoc.ref.update({
          lastPaymentDate: admin.firestore.Timestamp.now(),
          lastInvoiceId: invoice.id,
          subscriptionActive: true
        });
      }
      break;
    }
    
    case 'invoice.payment_failed': {
      const invoice = event.data.object;
      const subscriptionId = invoice.subscription;
      
      // Mark district as payment failed (don't deactivate immediately)
      const districtSnap = await db.collection('districts')
        .where('stripeSubscriptionId', '==', subscriptionId)
        .get();
      
      if (!districtSnap.empty) {
        await districtSnap.docs[0].ref.update({
          paymentFailed: true,
          lastFailedPaymentDate: admin.firestore.Timestamp.now()
        });
        
        // TODO: Send notification email to district admin
      }
      break;
    }
    
    case 'customer.subscription.deleted': {
      const subscription = event.data.object;
      
      // Deactivate district and all schools
      const districtSnap = await db.collection('districts')
        .where('stripeSubscriptionId', '==', subscription.id)
        .get();
      
      if (!districtSnap.empty) {
        const districtDoc = districtSnap.docs[0];
        const districtData = districtDoc.data();
        
        // Update district
        await districtDoc.ref.update({
          subscriptionActive: false,
          subscriptionEndDate: admin.firestore.Timestamp.now()
        });
        
        // Update all schools
        const batch = db.batch();
        for (const schoolId of districtData.billedSchoolIds) {
          const schoolRef = db.collection('schools').doc(schoolId);
          batch.update(schoolRef, {
            subscriptionActive: false,
            districtBillingActive: false
          });
        }
        await batch.commit();
      }
      break;
    }
  }
  
  res.json({ received: true });
});
```

---

## 5. Ensuring Money Isn't Lost

### Key Tracking Points

1. **Pending Subscriptions**: The app saves pending subscriptions to Firestore before redirecting to Stripe. These expire after 24 hours if not completed.

2. **Billed School IDs**: Always track `billedSchoolIds` separately from `schoolIds`. This ensures:
   - You know exactly which schools the district paid for
   - Schools can be added later (and billed separately)
   - No schools get free access without payment

3. **Webhook Verification**: Always verify webhook signatures to prevent fraud.

4. **Reconciliation**: Run monthly reconciliation:
   ```javascript
   // Check for discrepancies
   const districts = await db.collection('districts').get();
   for (const doc of districts.docs) {
     const data = doc.data();
     if (data.subscriptionActive) {
       const paidCount = data.billedSchoolIds?.length || 0;
       const actualCount = data.schoolIds?.length || 0;
       
       if (actualCount > paidCount) {
         console.warn(`District ${doc.id} has ${actualCount - paidCount} unbilled schools`);
       }
     }
   }
   ```

---

## 6. Website Updates Checklist

Your website at ezteach.org needs:

- [ ] `/checkout/district` - District checkout page
- [ ] `/checkout/school` - Individual school checkout page  
- [ ] `/success` - Payment success confirmation
- [ ] `/api/webhooks/stripe` - Webhook endpoint
- [ ] `/account` - Account management (linked from app)
- [ ] `/subscription` - Subscription management portal

### Create Customer Portal Link

```javascript
// Create portal session for subscription management
const portalSession = await stripe.billingPortal.sessions.create({
  customer: customerId,
  return_url: 'https://ezteach.org/account'
});
// Redirect to portalSession.url
```

---

## 7. Testing

### Test Mode
1. Use Stripe test mode first
2. Test cards:
   - Success: `4242 4242 4242 4242`
   - Decline: `4000 0000 0000 0002`
   - Requires auth: `4000 0025 0000 3155`

### Test Flows
1. Individual school subscription
2. District with 2 schools
3. District with 10 schools (tier change)
4. Adding schools to existing district
5. Removing schools from district
6. Failed payment recovery
7. Discount code application

---

## 8. Going Live Checklist

- [ ] Stripe identity verified
- [ ] Products/prices created in live mode
- [ ] Webhook endpoint configured for live
- [ ] Environment variables updated
- [ ] SSL certificate on website
- [ ] Test complete checkout flow
- [ ] Test webhook handling
- [ ] Monitor first few real transactions
