# EZTeach — Complete Setup, Compliance & Growth Guide

Everything in one place: payments, compliance (schools/legal), infrastructure, and how to promote & get schools to adopt EZTeach.

---

## PART 1: Money Flow (Stripe + Bank)

### How money works (simple)
1. Schools pay inside your app
2. Stripe processes the payment
3. Stripe deposits money into your bank

- You do NOT hold money in the app
- Stripe is your payment processor + compliance layer

### Stripe Setup (Correct Choices)

**Business type**
- If no LLC yet → Unregistered business
- If LLC → Registered business  
✔️ You can change this later

**Service category (IMPORTANT)**
- ✅ Software as a Service (SaaS) – business use
- ❌ Not electronic download

**Statement descriptor**
- EZTEACH

**Customer support**
- Real phone number (yours is fine)
- Real address (home is acceptable)

### Bank Account (Strong Recommendation)

Open a separate account for EZTeach.

Best options (low fees, Stripe‑friendly):
- Bluevine Business Checking (top pick)
- Novo
- Chase Business Checking
- Capital One Business

If you don't have an LLC yet:
- Use personal checking temporarily
- Switch later (Stripe allows this)

### Test vs Live Mode
- Stay in **TEST MODE** until:
  - Subscriptions work
  - Promo codes apply correctly
- Then switch to **LIVE MODE**

---

## PART 2: Email & SMS (Required for Schools)

### Email (SendGrid — REQUIRED)

Schools expect:
- Welcome emails
- Billing receipts
- Account notices

Steps:
1. Create SendGrid account
2. Verify sender email
3. Create API key
4. Add to Firebase Functions: `firebase functions:config:set sendgrid.api_key="SG.your_key"`
5. Deploy: `firebase deploy --only functions`

Without this → app works but looks unprofessional

### SMS (Twilio — Optional but powerful)

Use for:
- School alerts
- Emergency notifications
- Attendance notices

Steps:
1. Create Twilio account
2. Buy phone number
3. Generate API keys
4. Connect via Firebase Functions

---

## PART 3: Legal & School Compliance (CRITICAL)

Schools will not adopt unless this is covered.

### 1. FERPA (MANDATORY – US Schools)

FERPA protects student education records.

You MUST:
- Store student data securely (Firebase already does)
- Only allow access based on role (your rules already do this)
- Never sell student data
- Allow schools to request deletion

**Action items:**
- Add Privacy Policy stating FERPA compliance
- Add Terms of Service

### 2. COPPA (If under age 13 users exist)

If parents/students under 13 use the app:
- Schools act as the parent consent authority
- You do NOT collect data directly from children

**Action items:**
- State: "EZTeach is used by schools, not children directly"
- Add COPPA clause to Privacy Policy

### 3. Data Hosting Disclosure

Schools will ask: "Where is our data stored?"

**Answer:**
- Google Firebase (US regions)
- Encrypted at rest + in transit

Add this to: Website, Privacy Policy, Sales deck

### 4. Security Checklist (Schools Love This)

You already meet most of this:
- Authentication (Firebase Auth)
- Role‑based access
- Encrypted data
- Audit logs (Firestore timestamps)

Optional upgrade later: SOC 2 (only when you scale big)

---

## PART 4: Required Documents (DO THESE NOW)

You must have:
1. Privacy Policy
2. Terms of Service
3. FERPA Compliance Statement
4. Data Processing Agreement (DPA)

Generate via: Termly, Iubenda, or have them drafted.

---

## PART 5: Promo Codes & Pricing (READY)

You already have:
- 100% free yearly code
- 25% off yearly code

Best use:
- Give free year to first 10–25 schools
- Convert to paid year 2

---

## PART 6: How to Get Schools to Actually Use It

### Target Decision Makers

Sell to:
- Principals
- School administrators
- District tech coordinators

NOT to teachers (they don't buy).

### Outreach Strategy (WORKS)

**Step 1: Pilot Schools**
- Offer free year
- 1–3 schools first
- Get testimonials

**Step 2: Cold Email**

Subject: "Free school management system for [School Name]"

Body: We're offering a free pilot for schools to manage grades, attendance, communication, and subs in one platform. No contracts. FERPA‑compliant.

**Step 3: What Schools Care About**

Lead with:
- FERPA compliance
- Saves admin time
- Replaces multiple tools
- Parent transparency

NOT: "AI", "Startup", "Cool features"

**Step 4: Onboarding Flow**

When a school signs up:
1. Create school account
2. Upload logo
3. Add teachers
4. Import students
5. Invite parents

You already support this structurally.

---

## PART 7: App Store & Distribution

- Education category
- Privacy disclosures (done)
- No ads for kids
- No tracking

---

## FINAL CHECKLIST (Print This)

**Required to launch:**
- [ ] Stripe connected to bank
- [ ] SendGrid email working
- [ ] Privacy Policy + Terms
- [ ] FERPA statement
- [ ] App in Test → Live

**Required to grow:**
- [ ] Pilot schools
- [ ] Testimonials
- [ ] School onboarding guide
- [ ] Website landing page

---

*You're past the hard part technically. What remains is compliance docs, trust, and distribution.*
