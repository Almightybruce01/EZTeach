# EZTeach — Services to Track

Use **Admin-Dashboard.html** (open in browser) to track these. Edits save to your computer.

---

## Services overview

| Service | Cost | What it does |
|--------|------|--------------|
| **Firebase** | Free tier; pay-as-you-go | Auth, Firestore, Storage, Cloud Functions |
| **Stripe** | 2.9% + $0.30 per charge | Subscriptions, payments |
| **Netlify** | Free | Hosts ezteach.org |
| **GitHub** | Free | Code + website repo |
| **Domain (ezteach.org)** | ~$12/year | Namecheap (or your registrar) |
| **FormGrid** | Free tier | Contact form on website |
| **SendGrid** | Free 100 emails/day | Welcome, billing, support emails |
| **Apple Developer** | $99/year | App Store, push, signing |
| **App Store Connect** | Included | App listing, analytics |

---

## Recurring costs (approximate)

| Item | Frequency | Amount |
|------|-----------|--------|
| Domain | Yearly | ~$12 |
| Apple Developer | Yearly | $99 |
| Stripe | Per transaction | 2.9% + $0.30 |
| Firebase | Usage-based | Free tier usually enough at first |
| SendGrid | Free up to 100/day | $0 until upgrade |
| Netlify | Free tier | $0 |
| FormGrid | Free tier | $0 |

---

## When you upgrade

1. **Stripe:** You keep more; fees same. No config change for volume.
2. **Firebase:** Blaze plan if you exceed free limits. Set budget alerts.
3. **SendGrid:** Paid plan for more emails. Set `sendgrid.api_key` in Firebase config.
4. **FormGrid:** Paid if you exceed free submissions.
5. **Netlify:** Pro for more bandwidth/builds. Same deploy flow.

---

## Admin dashboard

Open **Admin-Dashboard.html** (double-click or open in Chrome/Safari) to:
- Track all services and costs
- Edit notes per service
- Update app pricing ($75/mo, $750/yr)
- Use setup checklist
- Log upgrades and changes

Data is stored in your browser (localStorage). Keep a backup of important notes elsewhere if needed.
