# Professional Email Setup — EZTeach

## How it works

| Purpose | Email | Where it goes |
|--------|--------|----------------|
| **Sending** (support claims, contact form, receipts) | noreply@ezteach.org | SendGrid sends; you verify once |
| **Receiving** (support, contact form) | ezteach0+support@gmail.com | Your Gmail inbox |

---

## Step 1 — Namecheap: Forward noreply@ezteach.org

1. Go to **https://ap.www.namecheap.com**
2. Click **Domain List**
3. Click **Manage** next to **ezteach.org**
4. Find **Email Forwarding** (or **Mail Settings** / **Forwarding**)
5. Click **Add forwarding address** or **Add**
6. **Email address:** noreply
7. **Forward to:** ezteach0@gmail.com
8. Save

After this, any email to noreply@ezteach.org will arrive in ezteach0@gmail.com.

---

## Step 2 — SendGrid: Verify noreply@ezteach.org

1. Go to **https://app.sendgrid.com** → **Settings** → **Sender Authentication**
2. Click **Verify a Single Sender**
3. Fill in:

   | Field | Value |
   |-------|--------|
   | From Name | EZTeach |
   | From Email Address | noreply@ezteach.org |
   | Reply To | ezteach0@gmail.com |
   | Company Address | Your address |
   | City | Your city |
   | State | Your state |
   | Zip Code | Your zip |
   | Country | United States |
   | Nickname | EZTeach |

4. Click **Create**
5. Check **ezteach0@gmail.com** for the verification email (forwarded from noreply@ezteach.org)
6. Click the verification link

---

## Step 3 — Deploy

```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only functions
```

---

## If Namecheap email forwarding is not available

If your domain uses Netlify DNS and Namecheap forwarding does not work:

1. Go to **https://improvmx.com** (free)
2. Add domain **ezteach.org**
3. Add alias: **noreply** → ezteach0@gmail.com
4. Add the MX records ImprovMX gives you in Netlify (Domain management → DNS)
5. Wait 10–30 minutes, then do Step 2 (SendGrid verification) above
