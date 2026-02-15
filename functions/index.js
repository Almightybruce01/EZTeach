/**
 * EZTeach Cloud Functions
 * 
 * Deploy with: firebase deploy --only functions
 * 
 * Required environment variables (set with firebase functions:config:set):
 * - stripe.secret_key
 * - sendgrid.api_key
 * - app.support_email
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const Stripe = require('stripe');
const sgMail = require('@sendgrid/mail');
const bcrypt = require('bcryptjs');

const STUDENT_CODE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
function generateStudentCode() {
  const bytes = crypto.randomBytes(8);
  return Array.from(bytes).map(b => STUDENT_CODE_CHARS[b % 36]).join('');
}

admin.initializeApp();

const db = admin.firestore();

// Node.js 20 required (Node 18 decommissioned Oct 2025)
const runtimeOpts = { runtime: 'nodejs20' };

// Initialize Stripe (set with: firebase functions:config:set stripe.secret_key="sk_...")
const stripe = new Stripe(functions.config().stripe?.secret_key || 'sk_test_placeholder', {
  apiVersion: '2023-10-16',
});

// Initialize SendGrid (set your key with: firebase functions:config:set sendgrid.api_key="SG...")
sgMail.setApiKey(functions.config().sendgrid?.api_key || 'SG.placeholder');

const SUPPORT_EMAIL = functions.config().app?.support_email || 'ezteach0+support@gmail.com';
const FROM_EMAIL = 'ezteach0@gmail.com'; // Must be verified in SendGrid (simplest - no domain forwarding needed)

// =========================================================
// STRIPE PRODUCT + PRICE IDS (created via setup-stripe-products.js)
// =========================================================
const STRIPE_PRICES = {
  S:   { productId: 'prod_TwHgFHUN60Wwq0', monthlyPriceId: 'price_1SyP7JFOg1Vq3X9Hap8wHqma', yearlyPriceId: 'price_1SyP7JFOg1Vq3X9HdrsB1EZJ', monthlyAmount: 12900, yearlyAmount: 129000, cap: 200, label: 'Tier S — 0–200 Students' },
  M1:  { productId: 'prod_TwHg08l3Zfh8Z0', monthlyPriceId: 'price_1SyP7JFOg1Vq3X9Hg1odwtkr', yearlyPriceId: 'price_1SyP7JFOg1Vq3X9HFkelThTZ', monthlyAmount: 22900, yearlyAmount: 229000, cap: 500, label: 'Tier M1 — 201–500 Students' },
  M2:  { productId: 'prod_TwHgmS1ijdE3MB', monthlyPriceId: 'price_1SyP7KFOg1Vq3X9HNu1IUWQS', yearlyPriceId: 'price_1SyP7KFOg1Vq3X9HcCqjm6Qv', monthlyAmount: 37900, yearlyAmount: 379000, cap: 1200, label: 'Tier M2 — 501–1,200 Students' },
  L:   { productId: 'prod_TwHgdE35MZI7gV', monthlyPriceId: 'price_1SyP7KFOg1Vq3X9HZVs191mz', yearlyPriceId: 'price_1SyP7LFOg1Vq3X9HUNLqwkHH', monthlyAmount: 54900, yearlyAmount: 549000, cap: 2500, label: 'Tier L — 1,201–2,500 Students' },
  XL:  { productId: 'prod_TwHg170sLcCuLF', monthlyPriceId: 'price_1SyP7LFOg1Vq3X9H0QLKJh6w', yearlyPriceId: 'price_1SyP7LFOg1Vq3X9HUIMuIsFd', monthlyAmount: 74900, yearlyAmount: 749000, cap: 4500, label: 'Tier XL — 2,501–4,500 Students' },
  ENT: { productId: 'prod_TwHgk848BL4WH7', monthlyPriceId: 'price_1SyP7LFOg1Vq3X9H3LUnz5e5', yearlyPriceId: 'price_1SyP7MFOg1Vq3X9Hu9a3GIg0', monthlyAmount: 99900, yearlyAmount: 999000, cap: 7500, label: 'Enterprise — 4,501–7,500 Students' },
};

// Per-student OVERAGE pricing — applies when a school/district exceeds the
// max tier cap (ENT = 7,500 students). Rate depends on total enrollment.
const OVERAGE_PRICES = {
  tier_7500:  { priceId: 'price_1SyP7NFOg1Vq3X9H15EcKfBL', perStudent: 12 },  // 7,501–15,000
  tier_15k:   { priceId: 'price_1SyP7NFOg1Vq3X9HmqKmc1QC', perStudent: 11 },  // 15,001–30,000
  tier_30k:   { priceId: 'price_1SyP7NFOg1Vq3X9HBcSqVNxo', perStudent: 10 },  // 30,001–60,000
  tier_60k:   { priceId: 'price_1SyP7NFOg1Vq3X9HGf6gqRDq', perStudent: 9  },  // 60,001–100,000
  tier_100k:  { priceId: 'price_1SyP7NFOg1Vq3X9HELvYfYlG', perStudent: 8  },  // 100,000+
};

function getOveragePriceId(totalStudents) {
  if (totalStudents > 100000) return OVERAGE_PRICES.tier_100k;
  if (totalStudents > 60000)  return OVERAGE_PRICES.tier_60k;
  if (totalStudents > 30000)  return OVERAGE_PRICES.tier_30k;
  if (totalStudents > 15000)  return OVERAGE_PRICES.tier_15k;
  return OVERAGE_PRICES.tier_7500;
}

// District pricing: districts pick a school tier (S/M1/M2/L/XL/ENT) per school.
// If total students exceed 7,500 (ENT cap), overage per-student pricing applies.

// =========================================================
// SUBSCRIPTION MANAGEMENT
// =========================================================

/**
 * Create a Stripe checkout session for school subscription.
 * Uses pre-created Stripe Price IDs (proper products in Stripe dashboard).
 * Supports monthly or yearly billing.
 */
exports.createCheckoutSession = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { schoolId, plan, successUrl, cancelUrl, couponCode } = data;
  const uid = context.auth.uid;

  try {
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data();
    if (!userData || !userData.email) {
      throw new functions.https.HttpsError('failed-precondition', 'User account missing email.');
    }

    // Get or create Stripe customer
    let customerId = userData.stripeCustomerId;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userData.email,
        metadata: { firebaseUID: uid, schoolId },
      });
      customerId = customer.id;
      await db.collection('users').doc(uid).update({ stripeCustomerId: customerId });
    }

    // Look up the school's current tier
    const schoolDoc = await db.collection('schools').doc(schoolId).get();
    const schoolData = schoolDoc.exists ? schoolDoc.data() : {};

    // Prevent double-charging: if district already covers this school
    if (schoolData.subscriptionActive === true && schoolData.districtCovered === true) {
      throw new functions.https.HttpsError(
        'already-exists',
        'This school is already covered by a district subscription. No additional payment is needed.'
      );
    }

    // Prevent double-charging: if school already has an active subscription
    if (schoolData.subscriptionActive === true) {
      throw new functions.https.HttpsError(
        'already-exists',
        'This school already has an active subscription.'
      );
    }

    const planTier = schoolData.planTier || 'S';
    const tierInfo = STRIPE_PRICES[planTier] || STRIPE_PRICES['S'];

    const isYearly = plan === 'yearly';
    const priceId = isYearly ? tierInfo.yearlyPriceId : tierInfo.monthlyPriceId;

    const sessionParams = {
      customer: customerId,
      payment_method_types: ['card'],
      line_items: [{ price: priceId, quantity: 1 }],
      mode: 'subscription',
      success_url: successUrl || 'https://ezteach.org/subscription-success.html',
      cancel_url: cancelUrl || 'https://ezteach.org/subscription-cancel.html',
      metadata: { schoolId, userId: uid, tier: planTier, billing: isYearly ? 'yearly' : 'monthly' },
      subscription_data: {
        metadata: { schoolId, userId: uid, tier: planTier },
      },
      allow_promotion_codes: true,
    };

    // Apply specific coupon if provided
    if (couponCode) {
      try {
        const promoCodes = await stripe.promotionCodes.list({ code: couponCode, active: true, limit: 1 });
        if (promoCodes.data.length > 0) {
          sessionParams.discounts = [{ promotion_code: promoCodes.data[0].id }];
          delete sessionParams.allow_promotion_codes; // can't use both
        }
      } catch (_) {
        console.warn('Invalid coupon code:', couponCode);
      }
    }

    const session = await stripe.checkout.sessions.create(sessionParams);
    return { sessionId: session.id, url: session.url };
  } catch (error) {
    console.error('Error creating checkout session:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * One-time setup: Create promo code documents in Firestore.
 * Restricted to admin UID. Set: firebase functions:config:set app.admin_uid="YOUR_UID"
 */
exports.setupPromoCodes = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in first');
  }
  const adminUid = functions.config().app?.admin_uid;
  if (adminUid && context.auth.uid !== adminUid) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }
  const col = db.collection('promoCodes');
  await col.doc('EZT6X7K2M9QPN4LR').set({ isActive: true, yearlyOnly: true, discountPercent: 1, description: '100% off yearly' });
  await col.doc('EZT4Y9N2QR7LKP3M').set({ isActive: true, yearlyOnly: true, discountPercent: 0.25, description: '25% off yearly' });
  return { success: true, message: 'Promo codes created.' };
});

/**
 * Create Stripe discount coupons and promotion codes.
 * Creates 4 codes for monthly AND yearly, 25% and 100%:
 *
 *   EZT-M25-7KP9X4  → 25% off monthly (forever)
 *   EZT-Y25-3NQ8W2  → 25% off yearly  (forever)
 *   EZT-M100-R5J6T8 → 100% off monthly (forever)
 *   EZT-Y100-V2L4M9 → 100% off yearly  (forever)
 *
 * Codes are complex to prevent guessing. Restricted to admin UID.
 * Deletes any old codes named "EZTeach*" first.
 */
exports.setupStripeCoupons = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in first');
  }
  const adminUid = functions.config().app?.admin_uid;
  if (adminUid && context.auth.uid !== adminUid) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const results = [];

  try {
    // 1. Delete old promotion codes (deactivate them)
    const oldCodes = ['EZTEACH25', 'EZTEACHFREE'];
    for (const code of oldCodes) {
      try {
        const existing = await stripe.promotionCodes.list({ code, limit: 1 });
        for (const pc of existing.data) {
          await stripe.promotionCodes.update(pc.id, { active: false });
          console.log('Deactivated old promo code:', code);
        }
      } catch (_) { /* ignore if not found */ }
    }

    // 2. Create 25% off monthly coupon
    const coupon25m = await stripe.coupons.create({
      percent_off: 25,
      duration: 'forever',
      name: 'EZTeach 25% Off — Monthly',
    });
    const promo25m = await stripe.promotionCodes.create({
      coupon: coupon25m.id,
      code: 'EZT-M25-7KP9X4',
      active: true,
      max_redemptions: 50,
    });
    results.push({ code: 'EZT-M25-7KP9X4', type: '25% monthly', promoId: promo25m.id });

    // 3. Create 25% off yearly coupon
    const coupon25y = await stripe.coupons.create({
      percent_off: 25,
      duration: 'forever',
      name: 'EZTeach 25% Off — Yearly',
    });
    const promo25y = await stripe.promotionCodes.create({
      coupon: coupon25y.id,
      code: 'EZT-Y25-3NQ8W2',
      active: true,
      max_redemptions: 50,
    });
    results.push({ code: 'EZT-Y25-3NQ8W2', type: '25% yearly', promoId: promo25y.id });

    // 4. Create 100% off monthly coupon
    const coupon100m = await stripe.coupons.create({
      percent_off: 100,
      duration: 'forever',
      name: 'EZTeach 100% Off — Monthly (Complimentary)',
    });
    const promo100m = await stripe.promotionCodes.create({
      coupon: coupon100m.id,
      code: 'EZT-M100-R5J6T8',
      active: true,
      max_redemptions: 10,
    });
    results.push({ code: 'EZT-M100-R5J6T8', type: '100% monthly', promoId: promo100m.id });

    // 5. Create 100% off yearly coupon
    const coupon100y = await stripe.coupons.create({
      percent_off: 100,
      duration: 'forever',
      name: 'EZTeach 100% Off — Yearly (Complimentary)',
    });
    const promo100y = await stripe.promotionCodes.create({
      coupon: coupon100y.id,
      code: 'EZT-Y100-V2L4M9',
      active: true,
      max_redemptions: 10,
    });
    results.push({ code: 'EZT-Y100-V2L4M9', type: '100% yearly', promoId: promo100y.id });

    return { success: true, codes: results };
  } catch (error) {
    console.error('Error creating Stripe coupons:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Handle Stripe webhook events
 */
exports.stripeWebhook = functions.runWith(runtimeOpts).https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe?.webhook_secret;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object;
      await handleSubscriptionCreated(session);
      break;
    }
    case 'invoice.paid': {
      const invoice = event.data.object;
      await handleInvoicePaid(invoice);
      break;
    }
    case 'invoice.payment_failed': {
      const invoice = event.data.object;
      await handlePaymentFailed(invoice);
      break;
    }
    case 'customer.subscription.deleted': {
      const subscription = event.data.object;
      await handleSubscriptionCancelled(subscription);
      break;
    }
    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({ received: true });
});

/**
 * FormGrid contact form webhook — forwards submissions to support email
 * In FormGrid: Connect webhook → URL: https://us-central1-ezteach-cdf5c.cloudfunctions.net/formGridWebhook
 */
exports.formGridWebhook = functions.runWith(runtimeOpts).https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method not allowed');
  }
  const webhookSecret = functions.config().formgrid?.webhook_secret;
  if (webhookSecret) {
    const provided = req.headers['x-webhook-secret'] || req.query?.secret || '';
    if (provided !== webhookSecret) {
      return res.status(401).send('Unauthorized');
    }
  }
  const data = req.body || {};
  const email = data.email || data.Email || data.from || 'unknown';
  const message = data.message || data.Message || data.body || JSON.stringify(data);
  const name = data.name || data.Name || '';

  try {
    // Store for backup
    await db.collection('contactFormSubmissions').add({
      email,
      message,
      name: name || undefined,
      source: 'website',
      createdAt: admin.firestore.Timestamp.now(),
    });
  } catch (e) {
    console.warn('Contact form store:', e.message);
  }

  const apiKey = functions.config().sendgrid?.api_key;
  if (apiKey && apiKey !== 'SG.placeholder') {
    try {
      await sgMail.send({
        to: SUPPORT_EMAIL,
        from: FROM_EMAIL,
        subject: `[EZTeach Support] Contact form: ${name ? name + ' — ' : ''}${String(message).slice(0, 50)}...`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #0a1f44;">New Contact Form Submission</h1>
            <p><strong>From:</strong> ${escapeHtml(email)}</p>
            ${name ? `<p><strong>Name:</strong> ${escapeHtml(name)}</p>` : ''}
            <p><strong>Message:</strong></p>
            <p style="background: #f5f5f5; padding: 15px; border-radius: 8px;">${escapeHtml(String(message))}</p>
          </div>
        `,
      });
    } catch (err) {
      console.error('FormGrid webhook email:', err);
    }
  }
  res.status(200).json({ received: true });
});

async function handleSubscriptionCreated(session) {
  const { schoolId, userId, promoCode, districtId, numberOfSchools, pricePerSchool } = session.metadata || {};

  // District subscription: cover ALL schools with their selected tiers
  if (districtId) {
    const districtDoc = await db.collection('districts').doc(districtId).get();
    if (!districtDoc.exists) {
      console.warn('District not found:', districtId);
      return;
    }
    const districtData = districtDoc.data();
    const schoolIds = districtData.schoolIds || [];

    const subscription = await stripe.subscriptions.retrieve(session.subscription);
    const interval = subscription?.items?.data?.[0]?.plan?.interval === 'year' ? 12 : 1;
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + interval);

    // Parse school→tier mapping from metadata (format: "schoolId1:S,schoolId2:M1,...")
    const tierMap = {};
    const schoolTiersStr = session.metadata?.schoolTiers || '';
    if (schoolTiersStr) {
      schoolTiersStr.split(',').forEach(entry => {
        const [sid, tier] = entry.split(':');
        if (sid && tier) tierMap[sid] = tier;
      });
    }

    const batch = db.batch();
    batch.update(db.collection('districts').doc(districtId), {
      subscriptionActive: true,
      stripeSubscriptionId: session.subscription,
      stripeCustomerId: session.customer,
      subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
    });

    for (const sid of schoolIds) {
      const tier = tierMap[sid] || 'S';
      const tierInfo = STRIPE_PRICES[tier] || STRIPE_PRICES['S'];
      batch.update(db.collection('schools').doc(sid), {
        districtId,
        districtCovered: true,
        subscriptionActive: true,
        subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
        planTier: tier,
        studentCap: tierInfo.cap,
        priceMonthly: tierInfo.monthlyAmount / 100,
      });
    }

    await batch.commit();
    console.log('District subscription activated:', districtId, schoolIds.length, 'schools covered with tiers');
    if (userId) {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        await sendSubscriptionConfirmationEmail(userDoc.data().email, session);
      }
    }
    return;
  }

  // School subscription (single school)
  if (!schoolId || !userId) {
    console.warn('Missing metadata in checkout session:', session.id);
    return;
  }

  if (promoCode) {
    const code = String(promoCode).toUpperCase().trim();
    if (code) {
      await db.collection('promoCodeUsage').add({
        code,
        userId,
        schoolId,
        usedAt: admin.firestore.Timestamp.now(),
      });
    }
  }

  const subscription = await stripe.subscriptions.retrieve(session.subscription);
  const interval = subscription?.items?.data?.[0]?.plan?.interval === 'year' ? 12 : 1;
  const endDate = new Date();
  endDate.setMonth(endDate.getMonth() + interval);

  const updateData = {
    subscriptionActive: true,
    isActive: true,
    subscriptionStartDate: admin.firestore.Timestamp.now(),
    subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
    stripeSubscriptionId: session.subscription,
    stripeCustomerId: session.customer,
  };
  // Persist tier from metadata if present
  const tier = session.metadata?.tier;
  if (tier) {
    const TIERS = { S: {cap:200,price:129}, M1: {cap:500,price:229}, M2: {cap:1200,price:379}, L: {cap:2500,price:549}, XL: {cap:4500,price:749}, ENT: {cap:7500,price:999} };
    const t = TIERS[tier];
    if (t) {
      updateData.planTier = tier;
      updateData.priceMonthly = t.price;
      updateData.studentCap = t.cap;
    }
  }
  await db.collection('schools').doc(schoolId).update(updateData);

  await db.collection('users').doc(userId).update({
    subscriptionActive: true,
  });

  const userDoc = await db.collection('users').doc(userId).get();
  await sendSubscriptionConfirmationEmail(userDoc.data().email, session);
}

async function handleInvoicePaid(invoice) {
  const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
  const meta = subscription.metadata || {};
  const districtId = meta.districtId;
  const schoolId = meta.schoolId;

  const endDate = new Date(subscription.current_period_end * 1000);

  if (districtId) {
    const districtDoc = await db.collection('districts').doc(districtId).get();
    if (districtDoc.exists) {
      const schoolIds = districtDoc.data().schoolIds || [];
      const batch = db.batch();
      batch.update(db.collection('districts').doc(districtId), {
        subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
        lastPaymentDate: admin.firestore.Timestamp.now(),
      });
      for (const sid of schoolIds) {
        batch.update(db.collection('schools').doc(sid), {
          subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
        });
      }
      await batch.commit();
    }
    if (meta.userId) {
      const userDoc = await db.collection('users').doc(meta.userId).get();
      if (userDoc.exists) await sendPaymentReceiptEmail(userDoc.data().email, invoice);
    }
    return;
  }

  if (schoolId) {
    await db.collection('schools').doc(schoolId).update({
      subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
      lastPaymentDate: admin.firestore.Timestamp.now(),
    });

    if (meta.userId) {
      const userDoc = await db.collection('users').doc(meta.userId).get();
      if (userDoc.exists) await sendPaymentReceiptEmail(userDoc.data().email, invoice);
    }
  }
}

async function handlePaymentFailed(invoice) {
  const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
  const userId = subscription.metadata.userId;

  if (userId) {
    const userDoc = await db.collection('users').doc(userId).get();
    await sendPaymentFailedEmail(userDoc.data().email, invoice);
  }
}

async function handleSubscriptionCancelled(subscription) {
  const meta = subscription.metadata || {};
  const districtId = meta.districtId;
  const schoolId = meta.schoolId;
  const userId = meta.userId;

  if (districtId) {
    const districtDoc = await db.collection('districts').doc(districtId).get();
    if (districtDoc.exists) {
      const districtData = districtDoc.data();
      const schoolIds = districtData.schoolIds || [];
      const batch = db.batch();
      batch.update(db.collection('districts').doc(districtId), { subscriptionActive: false });
      for (const sid of schoolIds) {
        batch.update(db.collection('schools').doc(sid), {
          subscriptionActive: false,
          districtCovered: false,
        });
      }
      await batch.commit();
      if (userId) {
        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists) {
          const email = userDoc.data().email;
          if (email) {
            await sendSubscriptionCancelledEmail(email, districtData.name || 'Your district');
          }
        }
      }
    }
    return;
  }

  if (schoolId) {
    const schoolDoc = await db.collection('schools').doc(schoolId).get();
    const schoolName = schoolDoc.exists ? schoolDoc.data().name || 'Your school' : 'Your school';
    await db.collection('schools').doc(schoolId).update({ subscriptionActive: false });
    if (userId) {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        const email = userDoc.data().email;
        if (email) await sendSubscriptionCancelledEmail(email, schoolName);
      }
    }
  }
}

async function sendSubscriptionCancelledEmail(email, orgName) {
  const msg = {
    to: email,
    from: FROM_EMAIL,
    subject: 'EZTeach Subscription Cancelled',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #0a1f44;">Subscription Cancelled</h1>
        <p>Your EZTeach subscription for <strong>${orgName}</strong> has been cancelled.</p>
        <p>You can resubscribe at any time through our website to restore access.</p>
        <p>If you have questions, please contact our support team.</p>
        <p>Best regards,<br>The EZTeach Team</p>
      </div>
    `,
  };
  try {
    await sgMail.send(msg);
  } catch (e) {
    console.error('Error sending subscription cancelled email:', e);
  }
}

// =========================================================
// DISTRICT SUBSCRIPTION
// =========================================================

/**
 * Create district subscription checkout
 */
/**
 * Create a district Stripe checkout session.
 * Districts pick a school tier (S/M1/M2/L/XL/ENT) for each school.
 * If total students exceed the max tier cap (7,500), overage per-student pricing applies.
 *
 * Expected data.schools: [{ schoolId, tier }]
 * Expected data.billing: "monthly" | "yearly"
 * Optional data.overageStudents: number of students above 7,500 cap
 * Optional data.totalStudents: total student count across all schools
 */
exports.createDistrictCheckout = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { districtId, schools, billing, overageStudents, totalStudents, successUrl, cancelUrl, couponCode } = data;
  const uid = context.auth.uid;
  const isYearly = billing === 'yearly';

  try {
    if (!Array.isArray(schools) || schools.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Must include at least one school with a tier.');
    }

    // Build line items — one per school using school tier prices
    const lineItems = schools.map(({ schoolId, tier }) => {
      const tierInfo = STRIPE_PRICES[tier];
      if (!tierInfo) throw new functions.https.HttpsError('invalid-argument', `Unknown tier: ${tier}`);
      const priceId = isYearly ? tierInfo.yearlyPriceId : tierInfo.monthlyPriceId;
      return { price: priceId, quantity: 1 };
    });

    // Add overage line item if students exceed max tier cap (7,500)
    const overage = parseInt(overageStudents, 10) || 0;
    if (overage > 0) {
      const total = parseInt(totalStudents, 10) || overage;
      const overageInfo = getOveragePriceId(total);
      lineItems.push({ price: overageInfo.priceId, quantity: overage });
    }

    // Get or create Stripe customer
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data();
    let customerId = userData.stripeCustomerId;

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userData.email,
        metadata: { firebaseUID: uid, districtId },
      });
      customerId = customer.id;
      await db.collection('users').doc(uid).update({ stripeCustomerId: customerId });
    }

    // Serialize school→tier mapping for metadata
    const tierMap = schools.map(s => `${s.schoolId}:${s.tier}`).join(',');

    const sessionParams = {
      customer: customerId,
      payment_method_types: ['card'],
      line_items: lineItems,
      mode: 'subscription',
      success_url: successUrl || 'https://ezteach.org/subscription-success.html',
      cancel_url: cancelUrl || 'https://ezteach.org/subscription-cancel.html',
      metadata: {
        districtId,
        userId: uid,
        billing: billing || 'monthly',
        schoolTiers: tierMap,
        numberOfSchools: schools.length.toString(),
        overageStudents: overage.toString(),
        totalStudents: (totalStudents || 0).toString(),
      },
      subscription_data: {
        metadata: { districtId, userId: uid },
      },
      allow_promotion_codes: true,
    };

    // Apply specific coupon if provided
    if (couponCode) {
      try {
        const promoCodes = await stripe.promotionCodes.list({ code: couponCode, active: true, limit: 1 });
        if (promoCodes.data.length > 0) {
          sessionParams.discounts = [{ promotion_code: promoCodes.data[0].id }];
          delete sessionParams.allow_promotion_codes;
        }
      } catch (_) {
        console.warn('Invalid coupon for district checkout:', couponCode);
      }
    }

    const session = await stripe.checkout.sessions.create(sessionParams);
    return { sessionId: session.id, url: session.url };
  } catch (error) {
    console.error('Error creating district checkout:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * When a district doc is created, link its schools and owner user.
 * Client only creates the district; this trigger does school + user updates.
 */
exports.onDistrictCreated = functions.runWith(runtimeOpts).firestore
  .document('districts/{districtId}')
  .onCreate(async (snap, context) => {
    const districtId = context.params.districtId;
    const d = snap.data();
    const uid = d.ownerUid;
    const schoolIds = d.schoolIds || [];
    const nextBilling = (d.subscriptionEndDate && d.subscriptionEndDate.toDate)
      ? d.subscriptionEndDate.toDate()
      : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    const batch = db.batch();

    for (const schoolId of schoolIds) {
      const schoolRef = db.collection('schools').doc(schoolId);
      batch.update(schoolRef, {
        districtId,
        districtCovered: true,
        subscriptionActive: true,
        subscriptionEndDate: admin.firestore.Timestamp.fromDate(nextBilling),
      });
    }

    const userRef = db.collection('users').doc(uid);
    batch.update(userRef, {
      districtId,
      isDistrictAdmin: true,
    });

    await batch.commit();
    console.log('District subscription linked:', districtId, schoolIds.length, 'schools');
  });

// =========================================================
// EMAIL NOTIFICATIONS
// =========================================================

/**
 * Send welcome email when any account is created
 */
exports.onUserCreated = functions.runWith(runtimeOpts).firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const email = userData.email;
    if (!email || typeof email !== 'string') {
      console.warn('onUserCreated: no email for user', context.params.userId);
      return;
    }

    const name = userData.fullName || userData.firstName || userData.name || 'there';
    const role = userData.role || 'user';
    let roleSpecificHtml = '';

    if (role === 'school' && userData.activeSchoolId) {
      const schoolSnap = await db.collection('schools').doc(userData.activeSchoolId).get();
      const schoolCode = schoolSnap.exists ? (schoolSnap.data().schoolCode || '') : '';
      roleSpecificHtml = `
        <p>Your school code: <strong>${schoolCode || 'Check your school settings in the app'}</strong></p>
        <p>Share this code with your teachers and staff so they can join your school.</p>
      `;
    }

    const msg = {
      to: email,
      from: FROM_EMAIL,
      subject: 'Welcome to EZTeach!',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #0a1f44;">Welcome to EZTeach!</h1>
          <p>Hi ${name},</p>
          <p>Thank you for creating an account with EZTeach. We're excited to have you on board!</p>
          <p>Your account type: <strong>${role}</strong></p>
          ${roleSpecificHtml}
          <p>If you have any questions, please don't hesitate to reach out to our support team.</p>
          <p>Best regards,<br>The EZTeach Team</p>
        </div>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log('Welcome email sent to:', email);
    } catch (error) {
      console.error('Error sending welcome email:', error);
    }
  });

/**
 * On student created: set password hash, email student if they have email, notify school admin and parents.
 */
exports.onStudentCreated = functions.runWith(runtimeOpts).firestore
  .document('students/{studentId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const ref = snap.ref;
    const firstName = data.firstName || '';
    const lastName = data.lastName || '';
    const fullName = `${firstName} ${lastName}`.trim() || 'Student';
    const studentCode = data.studentCode || '';
    const studentEmail = data.email || '';
    const schoolId = data.schoolId || '';
    const parentIds = data.parentIds || [];

    const code = (studentCode || '').toString().toUpperCase().trim();
    const defaultPassword = code + '!';

    const updates = {};
    if (code && code !== studentCode) {
      updates.studentCode = code;
    }
    if (!data.passwordHash) {
      updates.passwordHash = bcrypt.hashSync(defaultPassword, 10);
    }
    if (Object.keys(updates).length > 0) {
      await ref.update(updates);
    }

    // 2. If student has email, send them their login credentials
    if (studentEmail && typeof studentEmail === 'string' && studentEmail.includes('@')) {
      const defaultPassword = code + '!';
      const msg = {
        to: studentEmail,
        from: FROM_EMAIL,
        subject: 'Welcome to EZTeach - Your Student Login',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #0a1f44;">Welcome to EZTeach!</h1>
            <p>Hi ${fullName},</p>
            <p>Your student account has been created. Here are your login details:</p>
            <p><strong>Student ID:</strong> ${code}</p>
            <p><strong>Default password:</strong> ${code}!</p>
            <p>Sign in to the EZTeach app with Student Login. Enter your Student ID and password (default is Student ID + !).</p>
            <p>If you have any questions, please ask your teacher or school administrator.</p>
            <p>Best regards,<br>The EZTeach Team</p>
          </div>
        `,
      };
      try {
        await sgMail.send(msg);
        console.log('Student credentials email sent to:', studentEmail);
      } catch (e) {
        console.error('Error sending student credentials email:', e);
      }
    }

    // 3. Notify school admin
    if (!schoolId) return;
    const schoolSnap = await db.collection('schools').doc(schoolId).get();
    if (!schoolSnap.exists) return;
    const schoolData = schoolSnap.data();
    const ownerUid = schoolData.ownerUid;
    if (!ownerUid) return;
    const userSnap = await db.collection('users').doc(ownerUid).get();
    if (!userSnap.exists) return;
    const adminEmail = userSnap.data().email;
    if (!adminEmail) return;

    const adminMsg = {
      to: adminEmail,
      from: FROM_EMAIL,
      subject: `EZTeach: New student added - ${fullName}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #0a1f44;">New Student Added</h1>
          <p>A new student has been added to your school:</p>
          <p><strong>Name:</strong> ${fullName}</p>
          <p><strong>Student ID:</strong> ${code}</p>
          <p><strong>Default password:</strong> ${code}!</p>
          <p>Students sign in with Student Login using Student ID and password. You can view and manage this student in the EZTeach app.</p>
          <p>Best regards,<br>The EZTeach Team</p>
        </div>
      `,
    };
    try {
      await sgMail.send(adminMsg);
      console.log('School admin notified of new student:', adminEmail);
    } catch (e) {
      console.error('Error notifying school admin:', e);
    }

    // 4. Notify linked parents (if any exist at creation)
    for (const parentUid of parentIds) {
      const parentSnap = await db.collection('users').doc(parentUid).get();
      if (!parentSnap.exists) continue;
      const parentEmail = parentSnap.data().email;
      if (!parentEmail) continue;
      const parentMsg = {
        to: parentEmail,
        from: FROM_EMAIL,
        subject: `EZTeach: ${fullName} has been added to school`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #0a1f44;">Student Added</h1>
            <p>${fullName} has been added to the school roster.</p>
          <p><strong>Student ID:</strong> ${code}</p>
          <p><strong>Default password:</strong> ${code}!</p>
          <p>Students sign in with Student Login. You can view their grades in the EZTeach app.</p>
            <p>You can view their grades and info in the EZTeach app.</p>
            <p>Best regards,<br>The EZTeach Team</p>
          </div>
        `,
      };
      try {
        await sgMail.send(parentMsg);
        console.log('Parent notified of new student:', parentEmail);
      } catch (e) {
        console.error('Error notifying parent:', e);
      }
    }
  });

/**
 * When a student's email is added or changed after creation, send them their login credentials.
 */
exports.onStudentUpdated = functions.runWith(runtimeOpts).firestore
  .document('students/{studentId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const prevEmail = (before.email || '').trim().toLowerCase();
    const newEmail = (after.email || '').trim().toLowerCase();
    if (!newEmail || !newEmail.includes('@') || prevEmail === newEmail) return;

    const firstName = after.firstName || '';
    const lastName = after.lastName || '';
    const fullName = `${firstName} ${lastName}`.trim() || 'Student';
    const studentCode = (after.studentCode || '').toString().toUpperCase().trim();

    const msg = {
      to: newEmail,
      from: FROM_EMAIL,
      subject: 'EZTeach - Your Student Login',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #0a1f44;">Welcome to EZTeach!</h1>
          <p>Hi ${fullName},</p>
          <p>Your student account has been set up. Here are your login details:</p>
          <p><strong>Student ID:</strong> ${studentCode}</p>
          <p><strong>Default password:</strong> ${studentCode}!</p>
          <p>Sign in to the EZTeach app with Student Login using Student ID and password.</p>
          <p>If you have any questions, please ask your teacher or school administrator.</p>
          <p>Best regards,<br>The EZTeach Team</p>
        </div>
      `,
    };
    try {
      await sgMail.send(msg);
      console.log('Student credentials email sent (on update) to:', newEmail);
    } catch (e) {
      console.error('Error sending student credentials email:', e);
    }
  });

/**
 * When a video meeting is scheduled, email the host and all participants.
 */
exports.onVideoMeetingCreated = functions.runWith(runtimeOpts).firestore
  .document('videoMeetings/{meetingId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if ((data.status || '') !== 'scheduled') return;

    const title = data.title || 'Video Meeting';
    const scheduledAt = data.scheduledAt?.toDate?.() || new Date();
    const meetingUrl = data.meetingUrl || '';
    const meetingCode = data.meetingCode || '';
    const duration = data.duration || 30;
    const hostId = data.hostId || '';
    const participantIds = data.participantIds || [];

    const dateStr = scheduledAt.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' });
    const timeStr = scheduledAt.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });

    const sendMeetingEmail = async (toEmail, recipientName, isHost) => {
      const msg = {
        to: toEmail,
        from: FROM_EMAIL,
        subject: isHost ? `EZTeach: Meeting scheduled - ${title}` : `EZTeach: You're invited - ${title}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #0a1f44;">${isHost ? 'Meeting Scheduled' : 'Meeting Invitation'}</h1>
            <p>Hi ${recipientName},</p>
            <p>${isHost ? 'You have scheduled' : 'You have been invited to'} a video meeting:</p>
            <p><strong>${title}</strong></p>
            <p><strong>When:</strong> ${dateStr} at ${timeStr}</p>
            <p><strong>Duration:</strong> ${duration} minutes</p>
            ${meetingCode ? `<p><strong>Meeting Code:</strong> ${meetingCode}</p>` : ''}
            ${meetingUrl ? `<p><a href="${meetingUrl}" style="color: #0a1f44;">Join Meeting</a></p>` : ''}
            <p>Please show up a few minutes early. Open the EZTeach app to join when it's time.</p>
            <p>Best regards,<br>The EZTeach Team</p>
          </div>
        `,
      };
      try {
        await sgMail.send(msg);
        console.log('Meeting email sent to:', toEmail);
      } catch (e) {
        console.error('Error sending meeting email:', e);
      }
    };

    if (hostId) {
      const hostSnap = await db.collection('users').doc(hostId).get();
      if (hostSnap.exists) {
        const hostData = hostSnap.data();
        const hostEmail = hostData.email;
        const hostName = hostData.fullName || hostData.firstName || 'Host';
        if (hostEmail) await sendMeetingEmail(hostEmail, hostName, true);
      }
    }

    for (const pid of participantIds) {
      const userSnap = await db.collection('users').doc(pid).get();
      if (!userSnap.exists) continue;
      const userData = userSnap.data();
      const email = userData.email;
      const name = userData.fullName || userData.firstName || 'there';
      if (email) await sendMeetingEmail(email, name, false);
    }
  });

/**
 * When an event or day off is added to the calendar, notify school staff.
 */
exports.onEventCreated = functions.runWith(runtimeOpts).firestore
  .document('events/{eventId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const schoolId = data.schoolId || '';
    const title = data.title || 'Event';
    const type = data.type || 'event';
    const teachersOnly = data.teachersOnly === true;

    let dateStr = 'Soon';
    const ts = data.date || data.startDate;
    if (ts && ts.toDate) {
      dateStr = ts.toDate().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' });
    } else if (typeof ts === 'string') {
      dateStr = ts;
    }

    const isDayOff = type === 'dayOff';
    const subject = isDayOff ? `EZTeach: Day Off - ${title}` : `EZTeach: New Event - ${title}`;

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #0a1f44;">${isDayOff ? 'Day Off' : 'New Calendar Event'}</h1>
        <p>A new ${isDayOff ? 'day off' : 'event'} has been added to the school calendar:</p>
        <p><strong>${title}</strong></p>
        <p><strong>Date:</strong> ${dateStr}</p>
        ${teachersOnly ? '<p><em>Teachers and school accounts only</em></p>' : ''}
        <p>View the calendar in the EZTeach app for details.</p>
        <p>Best regards,<br>The EZTeach Team</p>
      </div>
    `;

    const emailsToNotify = new Set();

    if (schoolId) {
      const schoolSnap = await db.collection('schools').doc(schoolId).get();
      if (schoolSnap.exists) {
        const ownerUid = schoolSnap.data().ownerUid;
        if (ownerUid) {
          const ownerSnap = await db.collection('users').doc(ownerUid).get();
          if (ownerSnap.exists) {
            const e = ownerSnap.data().email;
            if (e) emailsToNotify.add(e);
          }
        }
      }

      const staffSnap = await db.collection('users').where('activeSchoolId', '==', schoolId).get();
      staffSnap.docs.forEach(doc => {
        const ud = doc.data();
        const role = ud.role || '';
        if (teachersOnly && role !== 'school' && role !== 'teacher') return;
        const e = ud.email;
        if (e) emailsToNotify.add(e);
      });
    }

    for (const email of emailsToNotify) {
      try {
        await sgMail.send({ to: email, from: FROM_EMAIL, subject, html });
        console.log('Event email sent to:', email);
      } catch (e) {
        console.error('Error sending event email:', e);
      }
    }
  });

/**
 * When an announcement is posted, notify school staff and optionally parents.
 */
exports.onAnnouncementCreated = functions.runWith(runtimeOpts).firestore
  .document('announcements/{announcementId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const schoolId = data.schoolId || '';
    const title = data.title || 'New Announcement';
    const body = (data.body || '').slice(0, 500);

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #0a1f44;">New Announcement</h1>
        <p><strong>${title}</strong></p>
        <p>${body}</p>
        <p>View in the EZTeach app for full details.</p>
        <p>Best regards,<br>The EZTeach Team</p>
      </div>
    `;

    const emailsToNotify = new Set();
    if (schoolId) {
      const schoolSnap = await db.collection('schools').doc(schoolId).get();
      if (schoolSnap.exists) {
        const ownerUid = schoolSnap.data().ownerUid;
        if (ownerUid) {
          const u = await db.collection('users').doc(ownerUid).get();
          if (u.exists && u.data().email) emailsToNotify.add(u.data().email);
        }
      }
      const staffSnap = await db.collection('users').where('activeSchoolId', '==', schoolId).get();
      staffSnap.docs.forEach(doc => {
        const e = doc.data().email;
        if (e) emailsToNotify.add(e);
      });
    }
    for (const email of emailsToNotify) {
      try {
        await sgMail.send({ to: email, from: FROM_EMAIL, subject: `EZTeach: ${title}`, html });
      } catch (e) { console.error('Announcement email error:', e); }
    }
  });

/**
 * When an emergency alert is created, notify school staff and parents.
 */
exports.onEmergencyAlertCreated = functions.runWith(runtimeOpts).firestore
  .document('emergencyAlerts/{alertId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const schoolId = data.schoolId || '';
    const title = data.title || 'EMERGENCY ALERT';
    const message = data.message || '';

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #c00;">⚠ ${title}</h1>
        <p style="font-size: 16px;">${message}</p>
        <p>Please check the EZTeach app immediately for updates.</p>
        <p>Best regards,<br>The EZTeach Team</p>
      </div>
    `;

    const emailsToNotify = new Set();
    if (schoolId) {
      const schoolSnap = await db.collection('schools').doc(schoolId).get();
      if (schoolSnap.exists) {
        const ownerUid = schoolSnap.data().ownerUid;
        if (ownerUid) {
          const u = await db.collection('users').doc(ownerUid).get();
          if (u.exists && u.data().email) emailsToNotify.add(u.data().email);
        }
      }
      const staffSnap = await db.collection('users').where('activeSchoolId', '==', schoolId).get();
      staffSnap.docs.forEach(doc => { const e = doc.data().email; if (e) emailsToNotify.add(e); });

      const studentsSnap = await db.collection('students').where('schoolId', '==', schoolId).get();
      for (const s of studentsSnap.docs) {
        const parentIds = s.data().parentIds || [];
        for (const pid of parentIds) {
          const u = await db.collection('users').doc(pid).get();
          if (u.exists && u.data().email) emailsToNotify.add(u.data().email);
        }
      }
    }
    for (const email of emailsToNotify) {
      try {
        await sgMail.send({ to: email, from: FROM_EMAIL, subject: `[URGENT] EZTeach: ${title}`, html });
      } catch (e) { console.error('Emergency alert email error:', e); }
    }
  });

/**
 * When attendance is marked absent, notify linked parents.
 */
exports.onAttendanceWritten = functions.runWith(runtimeOpts).firestore
  .document('attendance/{attendanceId}')
  .onWrite(async (change, context) => {
    const snap = change.after.exists ? change.after : change.before;
    if (!snap.exists) return;
    const data = snap.data();
    if ((data.status || '') !== 'absent') return;

    const studentId = data.studentId || '';
    const studentName = data.studentName || 'Your child';
    const dateVal = data.date?.toDate?.() || new Date();
    const dateStr = dateVal.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });

    const studentDoc = await db.collection('students').doc(studentId).get();
    if (!studentDoc.exists) return;
    const parentIds = studentDoc.data().parentIds || [];

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #0a1f44;">Attendance Notice</h1>
        <p>${studentName} was marked <strong>absent</strong> on ${dateStr}.</p>
        <p>If this is an error or you have questions, please contact the school.</p>
        <p>Best regards,<br>The EZTeach Team</p>
      </div>
    `;

    for (const pid of parentIds) {
      const u = await db.collection('users').doc(pid).get();
      if (!u.exists) continue;
      const email = u.data().email;
      if (!email) continue;
      try {
        await sgMail.send({ to: email, from: FROM_EMAIL, subject: `EZTeach: ${studentName} marked absent`, html });
      } catch (e) { console.error('Attendance email error:', e); }
    }
  });

/**
 * When a video meeting is cancelled, notify participants.
 */
exports.onVideoMeetingUpdated = functions.runWith(runtimeOpts).firestore
  .document('videoMeetings/{meetingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if ((before.status || '') === 'cancelled') return;
    if ((after.status || '') !== 'cancelled') return;

    const title = after.title || 'Video Meeting';
    const hostId = after.hostId || '';
    const participantIds = after.participantIds || [];

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #0a1f44;">Meeting Cancelled</h1>
        <p>The meeting <strong>${title}</strong> has been cancelled.</p>
        <p>Check the EZTeach app for any rescheduled dates.</p>
        <p>Best regards,<br>The EZTeach Team</p>
      </div>
    `;

    const notify = async (uid) => {
      const u = await db.collection('users').doc(uid).get();
      if (u.exists && u.data().email) {
        try {
          await sgMail.send({ to: u.data().email, from: FROM_EMAIL, subject: `EZTeach: Meeting cancelled - ${title}`, html });
        } catch (e) { console.error('Meeting cancelled email error:', e); }
      }
    };

    for (const pid of participantIds) await notify(pid);
  });

/**
 * Meeting reminders: 24 hours and 1 hour before scheduled meetings.
 */
exports.sendMeetingReminders = functions.runWith(runtimeOpts).pubsub
  .schedule('0 * * * *') // Every hour
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const now = new Date();
    const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const in1h = new Date(now.getTime() + 60 * 60 * 1000);
    const window = 35 * 60 * 1000; // 35 min window

    const meetingsSnap = await db.collection('videoMeetings')
      .where('status', '==', 'scheduled')
      .get();

    for (const doc of meetingsSnap.docs) {
      const data = doc.data();
      const scheduledAt = data.scheduledAt?.toDate?.();
      if (!scheduledAt || scheduledAt < now) continue;

      const diff = scheduledAt.getTime() - now.getTime();
      let reminderType = null;
      if (diff >= 23 * 60 * 60 * 1000 && diff <= 25 * 60 * 60 * 1000) reminderType = '24h';
      else if (diff >= 55 * 60 * 1000 && diff <= 65 * 60 * 1000) reminderType = '1h';

      if (!reminderType) continue;

      const key = `${doc.id}_${reminderType}`;
      const reminderSent = await db.collection('meetingRemindersSent').doc(key).get();
      if (reminderSent.exists) continue;

      const title = data.title || 'Video Meeting';
      const meetingUrl = data.meetingUrl || '';
      const dateStr = scheduledAt.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' });
      const timeStr = scheduledAt.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });

      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #0a1f44;">Meeting Reminder</h1>
          <p>Your video meeting <strong>${title}</strong> is ${reminderType === '24h' ? 'in 24 hours' : 'in 1 hour'}.</p>
          <p><strong>When:</strong> ${dateStr} at ${timeStr}</p>
          ${meetingUrl ? `<p><a href="${meetingUrl}">Join Meeting</a></p>` : ''}
          <p>Open the EZTeach app to join when it's time.</p>
          <p>Best regards,<br>The EZTeach Team</p>
        </div>
      `;

      const sendTo = async (uid) => {
        const u = await db.collection('users').doc(uid).get();
        if (u.exists && u.data().email) {
          try {
            await sgMail.send({
              to: u.data().email,
              from: FROM_EMAIL,
              subject: `EZTeach Reminder: ${title} ${reminderType === '24h' ? '(24h)' : '(1h)'}`,
              html,
            });
          } catch (e) { console.error('Meeting reminder error:', e); }
        }
      };

      const hostId = data.hostId || '';
      const participantIds = data.participantIds || [];
      if (hostId) await sendTo(hostId);
      for (const pid of participantIds) await sendTo(pid);

      await db.collection('meetingRemindersSent').doc(key).set({ sentAt: admin.firestore.Timestamp.now() });
    }
    return null;
  });

/**
 * Day-off reminder: notify staff the day before a day off.
 */
exports.sendDayOffReminders = functions.runWith(runtimeOpts).pubsub
  .schedule('0 16 * * *') // 4 PM daily
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStart = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate());
    const tomorrowEnd = new Date(tomorrowStart.getTime() + 24 * 60 * 60 * 1000);

    const eventsSnap = await db.collection('events')
      .where('type', '==', 'dayOff')
      .get();

    for (const doc of eventsSnap.docs) {
      const data = doc.data();
      const ts = data.date || data.startDate;
      let eventDate;
      if (ts && ts.toDate) eventDate = ts.toDate();
      else if (typeof ts === 'string') eventDate = new Date(ts);
      else continue;

      const eventDayStart = new Date(eventDate.getFullYear(), eventDate.getMonth(), eventDate.getDate());
      if (eventDayStart < tomorrowStart || eventDayStart >= tomorrowEnd) continue;

      const key = `${doc.id}_${eventDayStart.getTime()}`;
      const reminderSent = await db.collection('dayOffRemindersSent').doc(key).get();
      if (reminderSent.exists) continue;

      const title = data.title || 'Day Off';
      const schoolId = data.schoolId || '';
      if (!schoolId) continue;

      const emailsToNotify = new Set();
      const staffSnap = await db.collection('users').where('activeSchoolId', '==', schoolId).get();
      staffSnap.docs.forEach(d => { const e = d.data().email; if (e) emailsToNotify.add(e); });

      const schoolSnap = await db.collection('schools').doc(schoolId).get();
      if (schoolSnap.exists) {
        const ownerUid = schoolSnap.data().ownerUid;
        if (ownerUid) {
          const u = await db.collection('users').doc(ownerUid).get();
          if (u.exists && u.data().email) emailsToNotify.add(u.data().email);
        }
      }

      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #0a1f44;">Reminder: Day Off Tomorrow</h1>
          <p><strong>${title}</strong> is tomorrow.</p>
          <p>Enjoy your day off!</p>
          <p>Best regards,<br>The EZTeach Team</p>
        </div>
      `;

      for (const email of emailsToNotify) {
        try {
          await sgMail.send({ to: email, from: FROM_EMAIL, subject: `EZTeach Reminder: ${title} tomorrow`, html });
        } catch (e) { console.error('Day off reminder error:', e); }
      }

      await db.collection('dayOffRemindersSent').doc(key).set({ sentAt: admin.firestore.Timestamp.now() });
    }
    return null;
  });

/**
 * Send billing reminder 3 days before subscription ends
 */
exports.sendBillingReminders = functions.runWith(runtimeOpts).pubsub
  .schedule('0 9 * * *') // Run daily at 9 AM
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const now = new Date();
    const threeDaysFromNow = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

    const schoolsSnapshot = await db.collection('schools')
      .where('subscriptionActive', '==', true)
      .where('subscriptionEndDate', '<=', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
      .where('subscriptionEndDate', '>=', admin.firestore.Timestamp.now())
      .get();

    for (const schoolDoc of schoolsSnapshot.docs) {
      const schoolData = schoolDoc.data();
      const userDoc = await db.collection('users').doc(schoolData.ownerUid).get();
      const userData = userDoc.data();

      const endDate = schoolData.subscriptionEndDate.toDate();
      const formattedDate = endDate.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });

      const msg = {
        to: userData.email,
        from: FROM_EMAIL,
        subject: 'EZTeach Subscription Renewal Reminder',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #0a1f44;">Subscription Renewal Reminder</h1>
            <p>Hi,</p>
            <p>This is a friendly reminder that your EZTeach subscription for <strong>${schoolData.name}</strong> will renew on <strong>${formattedDate}</strong>.</p>
            <p>Amount: <strong>$75.00/month</strong></p>
            <p>Your subscription will automatically renew unless cancelled.</p>
            <p>If you have any questions, please contact our support team.</p>
            <p>Best regards,<br>The EZTeach Team</p>
          </div>
        `,
      };

      try {
        await sgMail.send(msg);
        console.log('Billing reminder sent to:', userData.email);
      } catch (error) {
        console.error('Error sending billing reminder:', error);
      }
    }

    return null;
  });

async function sendSubscriptionConfirmationEmail(email, session) {
  const msg = {
    to: email,
    from: FROM_EMAIL,
    subject: 'EZTeach Subscription Confirmed!',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #0a1f44;">Subscription Confirmed!</h1>
        <p>Thank you for subscribing to EZTeach Pro!</p>
        <p>Your subscription is now active. You have full access to all EZTeach features.</p>
        <p>Amount charged: <strong>$${(session.amount_total / 100).toFixed(2)}</strong></p>
        <p>If you have any questions, please contact our support team.</p>
        <p>Best regards,<br>The EZTeach Team</p>
      </div>
    `,
  };

  await sgMail.send(msg);
}

async function sendPaymentReceiptEmail(email, invoice) {
  const msg = {
    to: email,
    from: FROM_EMAIL,
    subject: 'EZTeach Payment Receipt',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #0a1f44;">Payment Receipt</h1>
        <p>Thank you for your payment!</p>
        <p>Amount: <strong>$${(invoice.amount_paid / 100).toFixed(2)}</strong></p>
        <p>Invoice ID: ${invoice.id}</p>
        <p>Your subscription has been renewed.</p>
        <p>Best regards,<br>The EZTeach Team</p>
      </div>
    `,
  };

  await sgMail.send(msg);
}

async function sendPaymentFailedEmail(email, invoice) {
  const msg = {
    to: email,
    from: FROM_EMAIL,
    subject: 'EZTeach Payment Failed - Action Required',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #ef4444;">Payment Failed</h1>
        <p>We were unable to process your payment for EZTeach.</p>
        <p>Amount: <strong>$${(invoice.amount_due / 100).toFixed(2)}</strong></p>
        <p>Please update your payment method to continue using EZTeach without interruption.</p>
        <p>If you believe this is an error, please contact our support team.</p>
        <p>Best regards,<br>The EZTeach Team</p>
      </div>
    `,
  };

  await sgMail.send(msg);
}

/**
 * Callable: Send report card notification emails to a student's linked parents.
 * Call from app when teacher/parent views report card and taps "Email to parents".
 */
exports.sendReportCardNotification = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');

  const { studentId, studentName, overallGPA } = data || {};
  if (!studentId || !studentName) {
    throw new functions.https.HttpsError('invalid-argument', 'studentId and studentName required');
  }

  const studentDoc = await db.collection('students').doc(studentId).get();
  if (!studentDoc.exists) throw new functions.https.HttpsError('not-found', 'Student not found');

  const studentData = studentDoc.data();
  const parentIds = studentData.parentIds || [];
  if (parentIds.length === 0) {
    return { success: true, sent: 0, message: 'No linked parents' };
  }

  const gpaStr = typeof overallGPA === 'number' ? `${overallGPA.toFixed(1)}%` : 'N/A';
  let sent = 0;

  for (const uid of parentIds) {
    const userSnap = await db.collection('users').doc(uid).get();
    if (!userSnap.exists) continue;
    const email = userSnap.data().email;
    if (!email) continue;

    const name = userSnap.data().fullName || userSnap.data().firstName || 'Parent';
    const msg = {
      to: email,
      from: FROM_EMAIL,
      subject: `EZTeach: Report Card Available - ${studentName}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #0a1f44;">Report Card Available</h1>
          <p>Hi ${name},</p>
          <p>The report card for <strong>${studentName}</strong> is now available.</p>
          <p>Overall average: <strong>${gpaStr}</strong></p>
          <p>View the full report card in the EZTeach app under your student's profile.</p>
          <p>If you have questions, please contact your child's teacher.</p>
          <p>Best regards,<br>The EZTeach Team</p>
        </div>
      `,
    };
    try {
      await sgMail.send(msg);
      sent++;
    } catch (e) {
      console.error('Error sending report card email:', e);
    }
  }

  return { success: true, sent };
});

// =========================================================
// SUPPORT NOTIFICATIONS
// =========================================================

/**
 * Notify support team when new claim is created
 */
function escapeHtml(s) {
  if (typeof s !== 'string') return '';
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

exports.onSupportClaimCreated = functions.runWith(runtimeOpts).firestore
  .document('supportClaims/{claimId}')
  .onCreate(async (snap, context) => {
    const claimData = snap.data();

    const msg = {
      to: SUPPORT_EMAIL,
      from: FROM_EMAIL,
      subject: `[EZTeach Support] New Claim: ${String(claimData.subject || '').slice(0, 100)}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #0a1f44;">New Support Claim</h1>
          <p><strong>From:</strong> ${escapeHtml(claimData.email || '')}</p>
          <p><strong>Category:</strong> ${escapeHtml(claimData.category || '')}</p>
          <p><strong>Subject:</strong> ${escapeHtml(claimData.subject || '')}</p>
          <p><strong>Message:</strong></p>
          <p style="background: #f5f5f5; padding: 15px; border-radius: 8px;">${escapeHtml(claimData.message || '')}</p>
          <p><strong>Claim ID:</strong> ${escapeHtml(context.params.claimId)}</p>
        </div>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log('Support notification sent for claim:', context.params.claimId);
    } catch (error) {
      console.error('Error sending support notification:', error);
    }
  });

// =========================================================
// SECURITY & DATA INTEGRITY
// =========================================================

/**
 * Validate subscription before allowing certain operations
 */
exports.validateSubscription = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { schoolId } = data;

  const schoolDoc = await db.collection('schools').doc(schoolId).get();

  if (!schoolDoc.exists) {
    return { valid: false, reason: 'School not found' };
  }

  const schoolData = schoolDoc.data();

  // Check direct subscription
  if (schoolData.subscriptionActive && schoolData.subscriptionEndDate) {
    const endDate = schoolData.subscriptionEndDate.toDate();
    if (endDate > new Date()) {
      return { valid: true, source: 'direct' };
    }
  }

  // Check district coverage
  if (schoolData.districtCovered && schoolData.districtId) {
    const districtDoc = await db.collection('districts').doc(schoolData.districtId).get();
    if (districtDoc.exists) {
      const districtData = districtDoc.data();
      if (districtData.subscriptionActive && districtData.subscriptionEndDate) {
        const endDate = districtData.subscriptionEndDate.toDate();
        if (endDate > new Date()) {
          return { valid: true, source: 'district' };
        }
      }
    }
  }

  return { valid: false, reason: 'No active subscription' };
});

/**
 * Get schools for Funday Friday dashboard (no auth required).
 * Secured by ?key=SECRET. Set funday.secret in Firebase config.
 * Usage: GET https://...cloudfunctions.net/getFundayFridaySchools?key=YOUR_SECRET
 */
exports.getFundayFridaySchools = functions.runWith(runtimeOpts).https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'GET');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(204).send('');
  }
  const secret = functions.config().funday?.secret;
  if (secret && req.query?.key !== secret) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  try {
    const schoolsSnap = await db.collection('schools').get();
    const schools = schoolsSnap.docs.map(d => {
      const data = d.data();
      return { id: d.id, name: data.name || 'Unnamed', city: data.city || '' };
    });
    const picksSnap = await db.collection('fundayFridayPicks').orderBy('createdAt', 'desc').limit(50).get();
    const pickedIds = new Set();
    const history = [];
    picksSnap.docs.forEach(d => {
      const d_ = d.data();
      (d_.schoolIds || []).forEach(id => pickedIds.add(id));
      const dt = d_.createdAt?.toDate?.();
      history.push({
        date: dt ? dt.toLocaleDateString() : '',
        schoolName: (d_.schoolNames || [])[0] || d_.schoolName || 'School',
        schoolCity: d_.schoolCity || ''
      });
    });
    return res.json({ schools, pickedIds: [...pickedIds], history });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'Server error' });
  }
});

/**
 * Look up a student by code for parent linking. Parent must provide schoolId + studentCode.
 * Returns student info only if school has active subscription.
 */
exports.lookupStudentForParentLink = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const userDoc = await db.collection('users').doc(context.auth.uid).get();
  const role = userDoc.data()?.role;
  if (role !== 'parent') throw new functions.https.HttpsError('permission-denied', 'Parent accounts only');

  const { schoolId, studentCode } = data || {};
  if (!schoolId || !studentCode || String(studentCode).length !== 8) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid school and 8-character student code required');
  }

  const code = String(studentCode).toUpperCase().trim();

  const schoolDoc = await db.collection('schools').doc(schoolId).get();
  if (!schoolDoc.exists) throw new functions.https.HttpsError('not-found', 'School not found');

  const schoolData = schoolDoc.data();
  const subActive = schoolData.subscriptionActive === true;
  if (!subActive) {
    throw new functions.https.HttpsError('failed-precondition', 'This school has not activated their subscription yet. Parents cannot link until the school subscribes. Ask the school administrator to complete their subscription.');
  }

  const studentsSnap = await db.collection('students')
    .where('schoolId', '==', schoolId)
    .where('studentCode', '==', code)
    .limit(1)
    .get();

  if (studentsSnap.empty) {
    throw new functions.https.HttpsError('not-found', 'No student found with this code at this school. Please check and try again.');
  }

  const doc = studentsSnap.docs[0];
  const d = doc.data();
  return {
    id: doc.id,
    firstName: d.firstName || '',
    lastName: d.lastName || '',
    gradeLevel: d.gradeLevel ?? 0,
    studentCode: d.studentCode || code
  };
});

/**
 * Link parent to student. Call after lookupStudentForParentLink confirms student exists.
 */
exports.linkParentToStudent = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const uid = context.auth.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const role = userDoc.data()?.role;
  if (role !== 'parent') throw new functions.https.HttpsError('permission-denied', 'Parent accounts only');

  const { studentId, relationship, isPrimaryContact, canPickup, emergencyContact } = data || {};
  if (!studentId) throw new functions.https.HttpsError('invalid-argument', 'Student ID required');

  const studentDoc = await db.collection('students').doc(studentId).get();
  if (!studentDoc.exists) throw new functions.https.HttpsError('not-found', 'Student not found');

  const studentData = studentDoc.data();
  const schoolId = studentData.schoolId;

  const schoolDoc = await db.collection('schools').doc(schoolId).get();
  if (!schoolDoc.exists) throw new functions.https.HttpsError('not-found', 'School not found');
  if (schoolDoc.data().subscriptionActive !== true) {
    throw new functions.https.HttpsError('failed-precondition', 'This school has not activated their subscription yet.');
  }

  const batch = db.batch();

  const studentRef = db.collection('students').doc(studentId);
  batch.update(studentRef, { parentIds: admin.firestore.FieldValue.arrayUnion(uid) });

  const linkRef = db.collection('parentStudentLinks').doc();
  batch.set(linkRef, {
    parentUserId: uid,
    studentId,
    schoolId,
    relationship: relationship || 'guardian',
    isPrimaryContact: !!isPrimaryContact,
    canPickup: canPickup !== false,
    emergencyContact: !!emergencyContact,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  const parentQuery = await db.collection('parents').where('userId', '==', uid).limit(1).get();
  if (!parentQuery.empty) {
    batch.update(parentQuery.docs[0].ref, {
      childrenIds: admin.firestore.FieldValue.arrayUnion(studentId),
      schoolIds: admin.firestore.FieldValue.arrayUnion(schoolId)
    });
  }

  const userRef = db.collection('users').doc(uid);
  batch.update(userRef, {
    activeSchoolId: schoolId,
    joinedSchools: admin.firestore.FieldValue.arrayUnion({ id: schoolId, name: schoolDoc.data().name || '', city: schoolDoc.data().city || '' })
  });

  await batch.commit();

  const parentEmail = userDoc.data().email;
  const studentName = `${studentData.firstName || ''} ${studentData.lastName || ''}`.trim() || 'Student';
  const parentName = userDoc.data().fullName || userDoc.data().firstName || 'Parent';
  if (parentEmail) {
    try {
      await sgMail.send({
        to: parentEmail,
        from: FROM_EMAIL,
        subject: `EZTeach: You're now linked to ${studentName}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #0a1f44;">Account Linked</h1>
            <p>Hi ${parentName},</p>
            <p>You have successfully linked your account to <strong>${studentName}</strong>.</p>
            <p>You can now view grades, attendance, and school info in the EZTeach app.</p>
            <p>Best regards,<br>The EZTeach Team</p>
          </div>
        `,
      });
    } catch (e) {
      console.error('Parent linked email error:', e);
    }
  }

  return { success: true };
});

/**
 * District adds a school (by code). For existing districts.
 * Sets districtId on school, adds schoolId to district.
 */
exports.districtAddSchool = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const uid = context.auth.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const districtId = userDoc.data()?.districtId;
  if (!districtId) throw new functions.https.HttpsError('failed-precondition', 'No district associated');

  const districtDoc = await db.collection('districts').doc(districtId).get();
  if (!districtDoc.exists) throw new functions.https.HttpsError('not-found', 'District not found');
  if (districtDoc.data().ownerUid !== uid) throw new functions.https.HttpsError('permission-denied', 'Not district owner');

  const code = String(data?.schoolCode || '').trim();
  if (code.length !== 6) throw new functions.https.HttpsError('invalid-argument', '6-digit school code required');

  const schoolsSnap = await db.collection('schools').where('schoolCode', '==', code).limit(1).get();
  if (schoolsSnap.empty) throw new functions.https.HttpsError('not-found', 'No school with this code');

  const schoolDoc = schoolsSnap.docs[0];
  const schoolId = schoolDoc.id;
  const schoolData = schoolDoc.data();

  if (schoolData.districtId && schoolData.districtId !== districtId) {
    throw new functions.https.HttpsError('failed-precondition', 'School is already in another district');
  }

  const districtData = districtDoc.data();
  const schoolIds = districtData.schoolIds || [];
  if (schoolIds.includes(schoolId)) {
    return { success: true, message: 'Already in district' };
  }

  const nextBilling = (districtData.subscriptionEndDate && districtData.subscriptionEndDate.toDate)
    ? districtData.subscriptionEndDate.toDate()
    : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  const batch = db.batch();
  batch.update(db.collection('schools').doc(schoolId), {
    districtId,
    districtCovered: true,
    subscriptionActive: true,
    subscriptionEndDate: admin.firestore.Timestamp.fromDate(nextBilling)
  });
  batch.update(db.collection('districts').doc(districtId), {
    schoolIds: admin.firestore.FieldValue.arrayUnion(schoolId)
  });
  await batch.commit();
  return { success: true };
});

/**
 * District adds a school by ID (e.g. when district just created the school).
 */
exports.districtAddSchoolById = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const uid = context.auth.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const districtId = userDoc.data()?.districtId;
  if (!districtId) throw new functions.https.HttpsError('failed-precondition', 'No district');

  const districtDoc = await db.collection('districts').doc(districtId).get();
  if (!districtDoc.exists) throw new functions.https.HttpsError('not-found', 'District not found');
  if (districtDoc.data().ownerUid !== uid) throw new functions.https.HttpsError('permission-denied', 'Not district owner');

  const schoolId = data?.schoolId;
  if (!schoolId) throw new functions.https.HttpsError('invalid-argument', 'schoolId required');

  const schoolDoc = await db.collection('schools').doc(schoolId).get();
  if (!schoolDoc.exists) throw new functions.https.HttpsError('not-found', 'School not found');
  const schoolData = schoolDoc.data();
  if (schoolData.districtId && schoolData.districtId !== districtId) {
    throw new functions.https.HttpsError('failed-precondition', 'School already in another district');
  }

  const districtData = districtDoc.data();
  const schoolIds = districtData.schoolIds || [];
  if (schoolIds.includes(schoolId)) return { success: true };

  const nextBilling = (districtData.subscriptionEndDate && districtData.subscriptionEndDate.toDate)
    ? districtData.subscriptionEndDate.toDate()
    : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  const batch = db.batch();
  batch.update(db.collection('schools').doc(schoolId), {
    districtId,
    districtCovered: true,
    subscriptionActive: true,
    subscriptionEndDate: admin.firestore.Timestamp.fromDate(nextBilling)
  });
  batch.update(db.collection('districts').doc(districtId), {
    schoolIds: admin.firestore.FieldValue.arrayUnion(schoolId)
  });
  await batch.commit();
  return { success: true };
});

/**
 * District removes a school. Clears districtId from school, removes from district.
 */
exports.districtRemoveSchool = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const uid = context.auth.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const districtId = userDoc.data()?.districtId;
  if (!districtId) throw new functions.https.HttpsError('failed-precondition', 'No district associated');

  const districtDoc = await db.collection('districts').doc(districtId).get();
  if (!districtDoc.exists) throw new functions.https.HttpsError('not-found', 'District not found');
  if (districtDoc.data().ownerUid !== uid) throw new functions.https.HttpsError('permission-denied', 'Not district owner');

  const schoolId = data?.schoolId;
  if (!schoolId) throw new functions.https.HttpsError('invalid-argument', 'schoolId required');

  const schoolDoc = await db.collection('schools').doc(schoolId).get();
  if (!schoolDoc.exists) throw new functions.https.HttpsError('not-found', 'School not found');
  if (schoolDoc.data().districtId !== districtId) throw new functions.https.HttpsError('permission-denied', 'School not in this district');

  const batch = db.batch();
  batch.update(db.collection('schools').doc(schoolId), {
    districtId: admin.firestore.FieldValue.delete(),
    districtCovered: admin.firestore.FieldValue.delete(),
    subscriptionActive: false
  });
  batch.update(db.collection('districts').doc(districtId), {
    schoolIds: admin.firestore.FieldValue.arrayRemove(schoolId)
  });
  await batch.commit();
  return { success: true };
});

/**
 * School leaves district. School owner only.
 */
exports.schoolLeaveDistrict = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const uid = context.auth.uid;
  const schoolId = data?.schoolId;
  if (!schoolId) throw new functions.https.HttpsError('invalid-argument', 'schoolId required');

  const schoolDoc = await db.collection('schools').doc(schoolId).get();
  if (!schoolDoc.exists) throw new functions.https.HttpsError('not-found', 'School not found');
  if (schoolDoc.data().ownerUid !== uid) throw new functions.https.HttpsError('permission-denied', 'Not school owner');

  const districtId = schoolDoc.data().districtId;
  if (!districtId) return { success: true, message: 'Not in a district' };

  const batch = db.batch();
  batch.update(db.collection('schools').doc(schoolId), {
    districtId: admin.firestore.FieldValue.delete(),
    districtCovered: admin.firestore.FieldValue.delete(),
    subscriptionActive: false
  });
  batch.update(db.collection('districts').doc(districtId), {
    schoolIds: admin.firestore.FieldValue.arrayRemove(schoolId)
  });
  await batch.commit();
  return { success: true };
});

/**
 * Parent unlinks a child. Reversible.
 */
exports.unlinkParentFromStudent = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const uid = context.auth.uid;
  const studentId = data?.studentId;
  if (!studentId) throw new functions.https.HttpsError('invalid-argument', 'studentId required');

  const userDoc = await db.collection('users').doc(uid).get();
  if (userDoc.data()?.role !== 'parent') throw new functions.https.HttpsError('permission-denied', 'Parent only');

  const studentDoc = await db.collection('students').doc(studentId).get();
  if (!studentDoc.exists) throw new functions.https.HttpsError('not-found', 'Student not found');

  const parentIds = studentDoc.data().parentIds || [];
  if (!parentIds.includes(uid)) return { success: true, message: 'Not linked' };

  const batch = db.batch();
  batch.update(db.collection('students').doc(studentId), {
    parentIds: admin.firestore.FieldValue.arrayRemove(uid)
  });

  const linksSnap = await db.collection('parentStudentLinks')
    .where('parentUserId', '==', uid)
    .where('studentId', '==', studentId)
    .get();
  linksSnap.docs.forEach(d => batch.delete(d.ref));

  const parentQuery = await db.collection('parents').where('userId', '==', uid).limit(1).get();
  if (!parentQuery.empty) {
    batch.update(parentQuery.docs[0].ref, {
      childrenIds: admin.firestore.FieldValue.arrayRemove(studentId),
      schoolIds: admin.firestore.FieldValue.arrayRemove(studentDoc.data().schoolId)
    });
  }

  await batch.commit();
  return { success: true };
});

/**
 * Search schools for parent school pick. Callable by signed-in users.
 * Returns schools matching searchText (name, city, or schoolCode).
 */
exports.searchSchools = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const searchText = String(data?.searchText || '').toLowerCase().trim();
  if (searchText.length < 2) return [];
  const all = await db.collection('schools').get();
  const results = [];
  all.docs.forEach(d => {
    const data_ = d.data();
    const name = (data_.name || '').toLowerCase();
    const city = (data_.city || '').toLowerCase();
    const code = String(data_.schoolCode || '');
    if (name.includes(searchText) || city.includes(searchText) || code.includes(searchText)) {
      results.push({
        id: d.id,
        name: data_.name || 'School',
        city: data_.city || '',
        schoolCode: code
      });
    }
  });
  return results.slice(0, 25);
});

/**
 * Save Funday Friday pick (no auth, secured by key).
 * POST with ?key=SECRET, body: { schoolId, schoolName, schoolCity, prizes: [...] }
 */
exports.saveFundayFridayPick = functions.runWith(runtimeOpts).https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(204).send('');
  }
  const secret = functions.config().funday?.secret;
  if (secret && req.query?.key !== secret) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  try {
    const { schoolId, schoolName, schoolCity, prizes, chosenPrize } = req.body || {};
    if (!schoolId || !schoolName || !Array.isArray(prizes)) {
      return res.status(400).json({ error: 'Missing schoolId, schoolName, or prizes' });
    }
    await db.collection('fundayFridayPicks').add({
      schoolId,
      schoolName: schoolName || '',
      schoolCity: schoolCity || '',
      schoolIds: [schoolId],
      schoolNames: [schoolName],
      prizes: prizes.slice(0, 6),
      chosenPrize: chosenPrize || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return res.json({ success: true });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'Server error' });
  }
});

// =========================================================
// STUDENT AUTH & PASSWORD
// =========================================================

/**
 * Create student: USER FIRST (Auth + users doc), then STUDENT (students doc).
 * This ensures students are full users like teachers/parents. Only path for student creation.
 */
exports.createStudent = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const callerUid = context.auth.uid;
  const userDoc = await db.collection('users').doc(callerUid).get();
  const userData = userDoc.data() || {};
  const role = userData.role || '';
  const activeSchool = userData.activeSchoolId || '';
  const districtId = userData.districtId;

  const schoolId = (data.schoolId || '').trim();
  if (!schoolId) throw new functions.https.HttpsError('invalid-argument', 'schoolId required');

  const isSchoolAdmin = role === 'school' && activeSchool === schoolId;
  const isTeacher = role === 'teacher' && activeSchool === schoolId;
  const isDistrict = role === 'district' && districtId;
  const isDistrictAdmin = isDistrict && await isDistrictAdminForSchool(callerUid, schoolId);
  if (!isSchoolAdmin && !isTeacher && !isDistrictAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only school staff or district admins can create students');
  }

  // ---- Cap enforcement ----
  const schoolDoc = await db.collection('schools').doc(schoolId).get();
  if (schoolDoc.exists) {
    const sd = schoolDoc.data();
    const studentCount = sd.studentCount || 0;
    const studentCap   = sd.studentCap   || 200;
    if (studentCount >= studentCap) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        `Student limit reached (${studentCount}/${studentCap}). Upgrade your plan to add more students.`
      );
    }
  }

  const firstName = (data.firstName || '').trim();
  const lastName = (data.lastName || '').trim();
  const middleName = (data.middleName || '').trim();
  const gradeLevel = parseInt(data.gradeLevel, 10) || 0;
  const notes = (data.notes || '').trim();
  const emailRaw = (data.email || '').trim().toLowerCase();
  const email = emailRaw && emailRaw.includes('@') ? emailRaw : null;
  let dateOfBirth = null;
  if (data.dateOfBirth) {
    const dob = data.dateOfBirth;
    const sec = dob._seconds ?? dob.seconds;
    if (typeof sec === 'number') dateOfBirth = admin.firestore.Timestamp.fromMillis(sec * 1000);
  }

  let studentCode;
  for (let attempt = 0; attempt < 20; attempt++) {
    const candidate = generateStudentCode();
    const snap = await db.collection('students').where('studentCode', '==', candidate).limit(1).get();
    if (snap.empty) {
      studentCode = candidate;
      break;
    }
    if (attempt === 19) throw new functions.https.HttpsError('internal', 'Could not generate unique Student ID. Try again.');
  }

  const defaultPassword = studentCode + '!';
  const studentAuthEmail = studentCode + '@students.ezteach.app';

  // STEP 1: Create USER (Firebase Auth + users document) - USER FIRST
  let authUid;
  try {
    const userRecord = await admin.auth().createUser({
      email: studentAuthEmail,
      password: defaultPassword,
      emailVerified: true,
      displayName: `${firstName} ${lastName}`.trim()
    });
    authUid = userRecord.uid;
  } catch (e) {
    if (e.code === 'auth/email-already-exists') {
      throw new functions.https.HttpsError('already-exists', 'Student ID already exists. Try again.');
    }
    console.error('createStudent Auth error:', e);
    throw new functions.https.HttpsError('internal', 'Could not create student account. Please try again.');
  }

  let schoolName = '';
  try {
    const schoolSnap = await db.collection('schools').doc(schoolId).get();
    schoolName = schoolSnap.exists ? (schoolSnap.data().name || '') : '';
  } catch (_) {}
  await db.collection('users').doc(authUid).set({
    role: 'student',
    email: studentAuthEmail,
    firstName,
    lastName,
    activeSchoolId: schoolId,
    studentId: authUid,
    joinedSchools: [{ id: schoolId, name: schoolName, city: '' }]
  });

  // STEP 2: Create STUDENT (students document) - from user info
  let dobString = 'nodob';
  if (dateOfBirth && typeof dateOfBirth.toDate === 'function') {
    const d = dateOfBirth.toDate();
    dobString = d.toISOString().slice(0, 10).replace(/-/g, '');
  }
  const duplicateKey = `${firstName.toLowerCase()}_${middleName.toLowerCase()}_${lastName.toLowerCase()}_${dobString}`;

  const studentRef = db.collection('students').doc(authUid);
  const studentData = {
    firstName,
    middleName,
    lastName,
    schoolId,
    studentCode,
    gradeLevel,
    notes,
    parentIds: [],
    duplicateKey,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };
  if (dateOfBirth) studentData.dateOfBirth = dateOfBirth;
  if (email) studentData.email = email;

  await studentRef.set(studentData);

  // Increment the school's studentCount atomically
  await db.collection('schools').doc(schoolId).update({
    studentCount: admin.firestore.FieldValue.increment(1)
  });

  const snap = await studentRef.get();
  const d = snap.data();
  return {
    id: authUid,
    firstName: d.firstName,
    middleName: d.middleName,
    lastName: d.lastName,
    schoolId: d.schoolId,
    studentCode: d.studentCode,
    gradeLevel: d.gradeLevel,
    notes: d.notes,
    parentIds: d.parentIds || [],
    createdAt: d.createdAt,
    email: d.email || null,
    dateOfBirth: d.dateOfBirth || null,
    passwordChangedAt: null
  };
});

/**
 * Student login: validates studentCode + password, returns custom token.
 * studentCode is the 8-char Student ID (case-insensitive). Password is case-sensitive.
 */
exports.studentLogin = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  const { studentCode, password } = data || {};
  if (!studentCode || !password) {
    throw new functions.https.HttpsError('invalid-argument', 'Student ID and password required');
  }
  const code = String(studentCode).toUpperCase().trim();
  const pwd = String(password || '').trim();
  let studentsSnap;
  try {
    studentsSnap = await db.collection('students').where('studentCode', '==', code).limit(1).get();
  } catch (e) {
    console.error('studentLogin Firestore error:', e);
    throw new functions.https.HttpsError('internal', 'Unable to look up student. Please try again.');
  }
  if (studentsSnap.empty) {
    throw new functions.https.HttpsError('not-found', 'Student account not found. Check your Student ID.');
  }
  const studentDoc = studentsSnap.docs[0];
  const studentData = studentDoc.data();
  const storedCode = (studentData.studentCode || '').toString().toUpperCase().trim();
  const defaultPassword = storedCode + '!';
  let hash = studentData.passwordHash;
  if (!hash) {
    hash = bcrypt.hashSync(defaultPassword, 10);
    await studentDoc.ref.update({ passwordHash: hash });
  }
  let valid = bcrypt.compareSync(pwd, hash);
  if (!valid) {
    if (pwd === defaultPassword) {
      hash = bcrypt.hashSync(defaultPassword, 10);
      await studentDoc.ref.update({ passwordHash: hash });
      valid = true;
    }
  }
  if (!valid) {
    throw new functions.https.HttpsError('unauthenticated', 'Incorrect password. Default is Student ID + ! (e.g. ' + storedCode + '!)');
  }
  const authEmail = storedCode + '@students.ezteach.app';
  const studentId = studentDoc.id;
  try {
    await admin.auth().getUser(studentId);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      try {
        await admin.auth().createUser({
          uid: studentId,
          email: authEmail,
          emailVerified: true,
          password: defaultPassword
        });
      } catch (createErr) {
        console.error('studentLogin migrate to Auth failed:', createErr);
      }
    }
  }
  let schoolName = '';
  try {
    const schoolSnap = await db.collection('schools').doc(studentData.schoolId || '').get();
    schoolName = schoolSnap.exists ? (schoolSnap.data().name || '') : '';
  } catch (_) {}
  const usersSnap = await db.collection('users').doc(studentId).get();
  if (!usersSnap.exists) {
    try {
      await db.collection('users').doc(studentId).set({
        role: 'student',
        email: authEmail,
        firstName: studentData.firstName || '',
        lastName: studentData.lastName || '',
        activeSchoolId: studentData.schoolId || '',
        studentId,
        joinedSchools: [{ id: studentData.schoolId || '', name: schoolName, city: '' }]
      });
    } catch (ue) {
      console.error('studentLogin create users doc failed:', ue);
    }
  }
  let customToken;
  try {
    customToken = await admin.auth().createCustomToken(studentId, { role: 'student' });
  } catch (e) {
    console.error('studentLogin createCustomToken error:', e);
    throw new functions.https.HttpsError('internal', 'Unable to complete sign in. Please try again.');
  }
  return { token: customToken };
});

/**
 * Get current user's student profile. Bypasses Firestore rules - use when direct read fails.
 * Callable only by the student themselves (uid must match students doc).
 */
exports.getMyStudentProfile = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const uid = context.auth.uid;
  const studentSnap = await db.collection('students').doc(uid).get();
  if (!studentSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Student profile not found');
  }
  const d = studentSnap.data();
  let schoolName = '';
  try {
    const schoolSnap = await db.collection('schools').doc(d.schoolId || '').get();
    schoolName = schoolSnap.exists ? (schoolSnap.data().name || '') : '';
  } catch (_) {}
  const createdAt = d.createdAt;
  const dob = d.dateOfBirth;
  return {
    id: uid,
    firstName: d.firstName || '',
    middleName: d.middleName || '',
    lastName: d.lastName || '',
    schoolId: d.schoolId || '',
    studentCode: (d.studentCode || '').toString().toUpperCase(),
    gradeLevel: d.gradeLevel || 0,
    notes: d.notes || '',
    parentIds: d.parentIds || [],
    createdAt: createdAt || null,
    email: d.email || null,
    dateOfBirth: dob || null,
    passwordChangedAt: d.passwordChangedAt || null,
    schoolName
  };
});

/**
 * Ensure student has users document. Backfills legacy students (User created from Student).
 */
exports.ensureStudentUserDoc = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const uid = context.auth.uid;
  const userSnap = await db.collection('users').doc(uid).get();
  if (userSnap.exists && (userSnap.data()?.role || '') === 'student') {
    return { success: true };
  }
  const studentSnap = await db.collection('students').doc(uid).get();
  if (!studentSnap.exists) {
    return { success: false };
  }
  const d = studentSnap.data();
  let schoolName = '';
  try {
    const schoolSnap = await db.collection('schools').doc(d.schoolId || '').get();
    schoolName = schoolSnap.exists ? (schoolSnap.data().name || '') : '';
  } catch (_) {}
  const authEmail = (d.studentCode || '').toString().toUpperCase().trim() + '@students.ezteach.app';
  await db.collection('users').doc(uid).set({
    role: 'student',
    email: authEmail,
    firstName: d.firstName || '',
    lastName: d.lastName || '',
    activeSchoolId: d.schoolId || '',
    studentId: uid,
    joinedSchools: [{ id: d.schoolId || '', name: schoolName, city: '' }]
  }, { merge: true });
  return { success: true };
});

/**
 * Change student password - school/teacher/district only
 */
exports.changeStudentPassword = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const { studentId, newPassword } = data || {};
  if (!studentId || !newPassword || newPassword.length < 6) {
    throw new functions.https.HttpsError('invalid-argument', 'Student ID and new password (6+ chars) required');
  }
  const uid = context.auth.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const userData = userDoc.data() || {};
  const role = userData.role || '';
  const activeSchool = userData.activeSchoolId;
  const studentDoc = await db.collection('students').doc(studentId).get();
  if (!studentDoc.exists) throw new functions.https.HttpsError('not-found', 'Student not found');
  const studentData = studentDoc.data();
  const studentSchoolId = studentData.schoolId;
  const isDistrict = role === 'district';
  const isSchoolAdmin = role === 'school' && activeSchool === studentSchoolId;
  const isTeacher = role === 'teacher' && activeSchool === studentSchoolId;
  const isParentLinked = role === 'parent' && (studentData.parentIds || []).includes(uid);
  const canEdit = isSchoolAdmin || isTeacher || (isDistrict && await isDistrictAdminForSchool(uid, studentSchoolId)) || isParentLinked;
  if (!canEdit) {
    throw new functions.https.HttpsError('permission-denied', 'Only school staff, district admins, or linked parents can change student passwords');
  }
  const code = (studentData.studentCode || '').toString().toUpperCase().trim();
  const authEmail = code + '@students.ezteach.app';
  try {
    await admin.auth().getUser(studentId);
    await admin.auth().updateUser(studentId, { password: newPassword });
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      try {
        await admin.auth().createUser({ uid: studentId, email: authEmail, emailVerified: true, password: newPassword });
      } catch (createErr) {
        const hash = bcrypt.hashSync(newPassword, 10);
        await studentDoc.ref.update({ passwordHash: hash, passwordChangedAt: admin.firestore.FieldValue.serverTimestamp() });
      }
    } else {
      throw new functions.https.HttpsError('internal', 'Could not update password');
    }
  }
  await studentDoc.ref.update({ passwordChangedAt: admin.firestore.FieldValue.serverTimestamp() });
  return { success: true };
});

/**
 * Reset student password to default (Student ID + !). School/teacher/district only.
 * Use when a student cannot log in and needs their password reset to default.
 */
exports.resetStudentToDefaultPassword = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const { studentId } = data || {};
  if (!studentId) throw new functions.https.HttpsError('invalid-argument', 'studentId required');
  const uid = context.auth.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const userData = userDoc.data() || {};
  const role = userData.role || '';
  const activeSchool = userData.activeSchoolId;
  const studentDoc = await db.collection('students').doc(studentId).get();
  if (!studentDoc.exists) throw new functions.https.HttpsError('not-found', 'Student not found');
  const studentData = studentDoc.data();
  const studentSchoolId = studentData.schoolId;
  const isSchoolAdmin = role === 'school' && activeSchool === studentSchoolId;
  const isTeacher = role === 'teacher' && activeSchool === studentSchoolId;
  const canEdit = isSchoolAdmin || isTeacher || (role === 'district' && await isDistrictAdminForSchool(uid, studentSchoolId));
  if (!canEdit) {
    throw new functions.https.HttpsError('permission-denied', 'Only school staff or district admins can reset passwords');
  }
  const code = (studentData.studentCode || '').toString().toUpperCase().trim();
  const defaultPassword = code + '!';
  const authEmail = code + '@students.ezteach.app';
  try {
    await admin.auth().getUser(studentId);
    await admin.auth().updateUser(studentId, { password: defaultPassword });
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      try {
        await admin.auth().createUser({ uid: studentId, email: authEmail, emailVerified: true, password: defaultPassword });
      } catch (createErr) {
        const hash = bcrypt.hashSync(defaultPassword, 10);
        await studentDoc.ref.update({ passwordHash: hash, passwordChangedAt: null });
      }
    } else {
      throw new functions.https.HttpsError('internal', 'Could not reset password');
    }
  }
  await studentDoc.ref.update({ passwordChangedAt: null });
  return { success: true, studentCode: code, message: `Password reset. Student can sign in with Student ID: ${code} and password: ${code}!` };
});

async function isDistrictAdminForSchool(uid, schoolId) {
  const userDoc = await db.collection('users').doc(uid).get();
  const userData = userDoc.data() || {};
  const districtId = userData.districtId;
  if (!districtId) return false;
  const districtDoc = await db.collection('districts').doc(districtId).get();
  if (!districtDoc.exists) return false;
  const districtData = districtDoc.data();
  if (districtData.ownerUid !== uid) return false;
  const schoolIds = districtData.schoolIds || [];
  return schoolIds.includes(schoolId);
}

/**
 * Clean up orphaned data periodically
 */
exports.cleanupOrphanedData = functions.runWith(runtimeOpts).pubsub
  .schedule('0 3 * * 0') // Run weekly on Sunday at 3 AM
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('Starting orphaned data cleanup...');

    // This would clean up:
    // - Messages in deleted conversations
    // - Attendance records for deleted students
    // - Documents for deleted schools
    // etc.

    // Implementation would depend on your specific cleanup needs

    console.log('Orphaned data cleanup complete');
    return null;
  });

// =========================================================
// STUDENT COUNT TRIGGERS (belt-and-suspenders — runs in addition to
// the increment inside createStudent to catch direct Firestore writes)
// =========================================================

/**
 * When a student document is deleted, decrement the school's studentCount.
 */
exports.onStudentDeleted = functions.firestore
  .document('students/{studentId}')
  .onDelete(async (snap) => {
    const data = snap.data();
    const schoolId = data.schoolId;
    if (!schoolId) return;
    try {
      await db.collection('schools').doc(schoolId).update({
        studentCount: admin.firestore.FieldValue.increment(-1)
      });
    } catch (e) {
      console.error('onStudentDeleted counter update failed:', e.message);
    }
  });

// =========================================================
// TIER-AWARE STRIPE CHECKOUT
// =========================================================

/**
 * Create a tiered Stripe checkout session (upgrade/change tier).
 * Uses real Stripe Price IDs. Supports monthly + yearly billing.
 */
exports.createTieredCheckout = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');

  let { schoolId, tier, billing, successUrl, cancelUrl, couponCode } = data;
  const uid = context.auth.uid;

  const tierInfo = STRIPE_PRICES[tier];
  if (!tierInfo) throw new functions.https.HttpsError('invalid-argument', `Unknown tier: ${tier}`);

  const userDoc = await db.collection('users').doc(uid).get();
  const userData = userDoc.data() || {};
  if (!userData.email) {
    throw new functions.https.HttpsError('failed-precondition', 'User account missing email.');
  }

  // Resolve schoolId from user doc if not provided or placeholder
  if (!schoolId || schoolId === '__FROM_USER__') {
    schoolId = userData.schoolId;
    if (!schoolId) {
      throw new functions.https.HttpsError('failed-precondition', 'No school linked to your account. Set up your school in the app first.');
    }
  }

  // Get or create Stripe customer
  let customerId = userData.stripeCustomerId;
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: userData.email,
      metadata: { firebaseUID: uid, schoolId },
    });
    customerId = customer.id;
    await db.collection('users').doc(uid).update({ stripeCustomerId: customerId });
  }

  const isYearly = billing === 'yearly';
  const priceId = isYearly ? tierInfo.yearlyPriceId : tierInfo.monthlyPriceId;

  const sessionParams = {
    customer: customerId,
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    mode: 'subscription',
    success_url: successUrl || 'https://ezteach.org/subscription-success.html',
    cancel_url: cancelUrl || 'https://ezteach.org/subscription-cancel.html',
    metadata: { schoolId, userId: uid, tier, billing: isYearly ? 'yearly' : 'monthly' },
    subscription_data: {
      metadata: { schoolId, userId: uid, tier },
    },
    allow_promotion_codes: true,
  };

  // Apply specific coupon if provided
  if (couponCode) {
    try {
      const promoCodes = await stripe.promotionCodes.list({ code: couponCode, active: true, limit: 1 });
      if (promoCodes.data.length > 0) {
        sessionParams.discounts = [{ promotion_code: promoCodes.data[0].id }];
        delete sessionParams.allow_promotion_codes;
      }
    } catch (_) {
      console.warn('Invalid coupon/promo code:', couponCode);
    }
  }

  const session = await stripe.checkout.sessions.create(sessionParams);

  // Update the school's tier in Firestore
  await db.collection('schools').doc(schoolId).update({
    planTier: tier,
    priceMonthly: tierInfo.monthlyAmount / 100,
    studentCap: tierInfo.cap,
  });

  return { sessionId: session.id, url: session.url };
});

// =========================================================
// STRIPE DISCOUNT CODES SETUP
// =========================================================

/**
 * One-time setup: create Stripe coupons for 25% and 100% off.
 * Call once via admin. Coupon IDs: EZTEACH25 and EZTEACH100.
 */
exports.setupStripeCoupons = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in first');
  const adminUid = functions.config().app?.admin_uid;
  if (adminUid && context.auth.uid !== adminUid) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const results = [];

  // 25% off coupon
  try {
    const coupon25 = await stripe.coupons.create({
      id: 'EZTEACH25',
      percent_off: 25,
      duration: 'forever',
      name: 'EZTeach 25% Off',
    });
    const promo25 = await stripe.promotionCodes.create({
      coupon: coupon25.id,
      code: 'EZTEACH25',
      active: true,
    });
    results.push({ coupon: 'EZTEACH25', promoId: promo25.id, status: 'created' });
  } catch (e) {
    results.push({ coupon: 'EZTEACH25', status: 'error', message: e.message });
  }

  // 100% off coupon
  try {
    const coupon100 = await stripe.coupons.create({
      id: 'EZTEACH100',
      percent_off: 100,
      duration: 'forever',
      name: 'EZTeach 100% Off',
    });
    const promo100 = await stripe.promotionCodes.create({
      coupon: coupon100.id,
      code: 'EZTEACH100',
      active: true,
    });
    results.push({ coupon: 'EZTEACH100', promoId: promo100.id, status: 'created' });
  } catch (e) {
    results.push({ coupon: 'EZTEACH100', status: 'error', message: e.message });
  }

  return { success: true, coupons: results };
});

// =========================================================
// DELETE SCHOOL ACCOUNT (student/teacher/staff)
// =========================================================

/**
 * Delete a school account (student, teacher, or staff).
 * Also decrements studentCount when deleting a student.
 */
exports.deleteSchoolAccount = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');

  const callerUid = context.auth.uid;
  const userDoc = await db.collection('users').doc(callerUid).get();
  const userData = userDoc.data() || {};
  const role = userData.role || '';
  const activeSchool = userData.activeSchoolId || '';

  const { accountId, accountType, schoolId } = data;
  if (!accountId || !accountType || !schoolId) {
    throw new functions.https.HttpsError('invalid-argument', 'accountId, accountType, and schoolId required');
  }

  // Only school admins or district admins can delete accounts
  const isSchoolAdmin = role === 'school' && activeSchool === schoolId;
  const isDistrict = role === 'district' && userData.districtId;
  const isDistrictAdmin = isDistrict && await isDistrictAdminForSchool(callerUid, schoolId);
  if (!isSchoolAdmin && !isDistrictAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only school or district admins can delete accounts');
  }

  const batch = db.batch();

  if (accountType === 'student') {
    // Delete student document
    batch.delete(db.collection('students').doc(accountId));
    // Delete user document
    batch.delete(db.collection('users').doc(accountId));
    // Decrement studentCount
    batch.update(db.collection('schools').doc(schoolId), {
      studentCount: admin.firestore.FieldValue.increment(-1)
    });
  } else if (accountType === 'teacher') {
    batch.delete(db.collection('teachers').doc(accountId));
  } else if (accountType === 'staff') {
    batch.delete(db.collection('users').doc(accountId));
  }

  await batch.commit();

  // Try to delete the Auth user (only for students with auth accounts)
  if (accountType === 'student') {
    try { await admin.auth().deleteUser(accountId); } catch (_) {}
  }

  return { success: true, deletedId: accountId };
});

// ================= DELETE OWN ACCOUNT (Apple 5.1.1(v) compliance) =================
exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const uid = context.auth.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const role = userDoc.exists ? userDoc.data().role : null;

  const batch = db.batch();

  // Delete user document
  if (userDoc.exists) {
    batch.delete(db.collection('users').doc(uid));
  }

  // Delete role-specific documents
  if (role === 'teacher' || role === 'sub') {
    const col = role === 'teacher' ? 'teachers' : 'subs';
    const snap = await db.collection(col).where('userId', '==', uid).get();
    snap.docs.forEach(doc => batch.delete(doc.ref));
  }

  if (role === 'parent') {
    const snap = await db.collection('parents').where('userId', '==', uid).get();
    snap.docs.forEach(doc => batch.delete(doc.ref));
    // Remove parent links
    const links = await db.collection('parentStudentLinks').where('parentUserId', '==', uid).get();
    links.docs.forEach(doc => batch.delete(doc.ref));
  }

  // Delete conversations where user is only participant
  const convos = await db.collection('conversations').where('participantIds', 'array-contains', uid).get();
  convos.docs.forEach(doc => {
    const pids = doc.data().participantIds || [];
    if (pids.length <= 2) {
      batch.delete(doc.ref);
    }
  });

  // Delete lesson plans created by user
  const lessons = await db.collection('lessonPlans').where('teacherId', '==', uid).get();
  lessons.docs.forEach(doc => batch.delete(doc.ref));

  // Delete support claims
  const claims = await db.collection('supportClaims').where('userId', '==', uid).get();
  claims.docs.forEach(doc => batch.delete(doc.ref));

  await batch.commit();

  // Delete Firebase Auth account
  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    console.log('Auth delete error (user may delete from client):', e.message);
  }

  return { success: true, deletedUserId: uid };
});
