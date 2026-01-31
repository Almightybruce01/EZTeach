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
const Stripe = require('stripe');
const sgMail = require('@sendgrid/mail');

admin.initializeApp();

const db = admin.firestore();

// Node.js 20 required (Node 18 decommissioned Oct 2025)
const runtimeOpts = { runtime: 'nodejs20' };

// Initialize Stripe (set with: firebase functions:config:set stripe.secret_key="sk_...")
const stripe = new Stripe(functions.config().stripe?.secret_key || 'sk_test_placeholder', {
  apiVersion: '2023-10-16',
});

// Product IDs from Stripe (School monthly $75/mo, School yearly $750/yr)
const PROD_MONTHLY = 'prod_TsvP71E7nTlzCb';
const PROD_YEARLY = 'prod_TsvTxl5KTc3bcB';

// Initialize SendGrid (set your key with: firebase functions:config:set sendgrid.api_key="SG...")
sgMail.setApiKey(functions.config().sendgrid?.api_key || 'SG.placeholder');

const SUPPORT_EMAIL = functions.config().app?.support_email || 'ezteach0+support@gmail.com';
const FROM_EMAIL = 'ezteach0@gmail.com'; // Must be verified in SendGrid (simplest - no domain forwarding needed)

// =========================================================
// SUBSCRIPTION MANAGEMENT
// =========================================================

/**
 * Create a Stripe checkout session for school subscription
 */
exports.createCheckoutSession = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { schoolId, plan, successUrl, cancelUrl, promoCode } = data;
  const uid = context.auth.uid;

  try {
    // Validate promo code (yearly only, one use per school)
    let discountPercent = 0;
    if (plan === 'yearly' && promoCode) {
      const code = String(promoCode).toUpperCase().trim();
      const promoDoc = await db.collection('promoCodes').doc(code).get();
      if (promoDoc.exists) {
        const d = promoDoc.data();
        if (d.isActive && d.yearlyOnly) {
          const alreadyUsed = await db.collection('promoCodeUsage')
            .where('code', '==', code)
            .where('schoolId', '==', schoolId)
            .limit(1)
            .get();
          if (alreadyUsed.empty) {
            discountPercent = d.discountPercent || 0;
          }
        }
      }
    }

    // Get or create Stripe customer
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data();
    let customerId = userData.stripeCustomerId;

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userData.email,
        metadata: { firebaseUID: uid, schoolId },
      });
      customerId = customer.id;
      await db.collection('users').doc(uid).update({ stripeCustomerId: customerId });
    }

    // Create checkout session ($75/mo or $750/yr)
    const isYearly = plan === 'yearly';
    const lineItem = isYearly
      ? {
          price_data: {
            currency: 'usd',
            product: PROD_YEARLY,
            unit_amount: 75000, // $750
            recurring: { interval: 'year' },
          },
          quantity: 1,
        }
      : {
          price_data: {
            currency: 'usd',
            product: PROD_MONTHLY,
            unit_amount: 7500, // $75
            recurring: { interval: 'month' },
          },
          quantity: 1,
        };

    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      payment_method_types: ['card'],
      line_items: [lineItem],
      mode: 'subscription',
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: { schoolId, userId: uid, promoCode: promoCode || '' },
      subscription_data: {
        metadata: { schoolId, userId: uid },
      },
    });

    return { sessionId: session.id, url: session.url };
  } catch (error) {
    console.error('Error creating checkout session:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * One-time setup: Create promo code documents in Firestore.
 * Call from app or: firebase functions:shell then setupPromoCodes()
 */
exports.setupPromoCodes = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in first');
  }
  const col = db.collection('promoCodes');
  await col.doc('EZT6X7K2M9QPN4LR').set({ isActive: true, yearlyOnly: true, discountPercent: 1, description: '100% off yearly' });
  await col.doc('EZT4Y9N2QR7LKP3M').set({ isActive: true, yearlyOnly: true, discountPercent: 0.25, description: '25% off yearly' });
  return { success: true, message: 'Promo codes created.' };
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
            <p><strong>From:</strong> ${email}</p>
            ${name ? `<p><strong>Name:</strong> ${name}</p>` : ''}
            <p><strong>Message:</strong></p>
            <p style="background: #f5f5f5; padding: 15px; border-radius: 8px;">${String(message).replace(/</g, '&lt;')}</p>
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
  const { schoolId, userId, promoCode } = session.metadata || {};

  if (!schoolId || !userId) {
    console.warn('Missing metadata in checkout session:', session.id);
    return;
  }

  // Record promo code usage (one-time use per school)
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

  // Determine billing interval from the subscription
  const subscription = await stripe.subscriptions.retrieve(session.subscription);
  const interval = subscription?.items?.data?.[0]?.plan?.interval === 'year' ? 12 : 1;
  const endDate = new Date();
  endDate.setMonth(endDate.getMonth() + interval);

  // Update school subscription status
  await db.collection('schools').doc(schoolId).update({
    subscriptionActive: true,
    subscriptionStartDate: admin.firestore.Timestamp.now(),
    subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
    stripeSubscriptionId: session.subscription,
    stripeCustomerId: session.customer,
  });

  // Update user
  await db.collection('users').doc(userId).update({
    subscriptionActive: true,
  });

  // Send confirmation email
  const userDoc = await db.collection('users').doc(userId).get();
  await sendSubscriptionConfirmationEmail(userDoc.data().email, session);
}

async function handleInvoicePaid(invoice) {
  const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
  const schoolId = subscription.metadata.schoolId;

  if (schoolId) {
    const endDate = new Date(subscription.current_period_end * 1000);
    await db.collection('schools').doc(schoolId).update({
      subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
      lastPaymentDate: admin.firestore.Timestamp.now(),
    });

    // Send payment receipt
    const userDoc = await db.collection('users').doc(subscription.metadata.userId).get();
    await sendPaymentReceiptEmail(userDoc.data().email, invoice);
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
  const schoolId = subscription.metadata.schoolId;

  if (schoolId) {
    await db.collection('schools').doc(schoolId).update({
      subscriptionActive: false,
    });
  }
}

// =========================================================
// DISTRICT SUBSCRIPTION
// =========================================================

/**
 * Create district subscription checkout
 */
exports.createDistrictCheckout = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { districtId, numberOfSchools, successUrl, cancelUrl } = data;
  const uid = context.auth.uid;

  try {
    // Calculate pricing ($75 base; volume: 72/68/64/60)
    let pricePerSchool = 75;
    if (numberOfSchools >= 31) pricePerSchool = 60;
    else if (numberOfSchools >= 16) pricePerSchool = 64;
    else if (numberOfSchools >= 6) pricePerSchool = 68;
    else if (numberOfSchools >= 1) pricePerSchool = 72;

    const totalAmount = pricePerSchool * numberOfSchools * 100; // in cents

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

    // Create checkout session with custom amount
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: `EZTeach District Subscription (${numberOfSchools} schools)`,
              description: `$${pricePerSchool}/school/month`,
            },
            unit_amount: totalAmount,
            recurring: {
              interval: 'month',
            },
          },
          quantity: 1,
        },
      ],
      mode: 'subscription',
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: {
        districtId,
        userId: uid,
        numberOfSchools: numberOfSchools.toString(),
        pricePerSchool: pricePerSchool.toString(),
      },
    });

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
 * Send welcome email when account is created
 */
exports.onUserCreated = functions.runWith(runtimeOpts).firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();

    const msg = {
      to: userData.email,
      from: FROM_EMAIL,
      subject: 'Welcome to EZTeach!',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #0a1f44;">Welcome to EZTeach!</h1>
          <p>Hi ${userData.firstName || 'there'},</p>
          <p>Thank you for creating an account with EZTeach. We're excited to have you on board!</p>
          <p>Your account type: <strong>${userData.role}</strong></p>
          ${userData.role === 'school' ? `
            <p>Your school code: <strong>${userData.schoolCode || 'Check your school settings'}</strong></p>
            <p>Share this code with your teachers and staff so they can join your school.</p>
          ` : ''}
          <p>If you have any questions, please don't hesitate to reach out to our support team.</p>
          <p>Best regards,<br>The EZTeach Team</p>
        </div>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log('Welcome email sent to:', userData.email);
    } catch (error) {
      console.error('Error sending welcome email:', error);
    }
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

// =========================================================
// SUPPORT NOTIFICATIONS
// =========================================================

/**
 * Notify support team when new claim is created
 */
exports.onSupportClaimCreated = functions.runWith(runtimeOpts).firestore
  .document('supportClaims/{claimId}')
  .onCreate(async (snap, context) => {
    const claimData = snap.data();

    const msg = {
      to: SUPPORT_EMAIL,
      from: FROM_EMAIL,
      subject: `[EZTeach Support] New Claim: ${claimData.subject}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #0a1f44;">New Support Claim</h1>
          <p><strong>From:</strong> ${claimData.email}</p>
          <p><strong>Category:</strong> ${claimData.category}</p>
          <p><strong>Subject:</strong> ${claimData.subject}</p>
          <p><strong>Message:</strong></p>
          <p style="background: #f5f5f5; padding: 15px; border-radius: 8px;">${claimData.message}</p>
          <p><strong>Claim ID:</strong> ${context.params.claimId}</p>
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
