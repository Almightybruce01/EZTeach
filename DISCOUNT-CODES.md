# EZTeach Active Promo Codes

**Keep these codes private. Share only via secure channels (email, DM). Do not post publicly.**

| Code | Discount | Applies To |
|------|----------|------------|
| **EZT6X7K2M9QPN4LR** | 100% off | Yearly subscription only |
| **EZT4Y9N2QR7LKP3M** | 25% off | Yearly subscription only |

**Usage:**
- One use per school/account
- Apply at checkout when selecting the yearly plan
- Stored in Firestore `promoCodes` collection
- Usage tracked in `promoCodeUsage` collection

**To add/rotate codes:** Create new documents in Firestore `promoCodes` with document ID = exact code (uppercase). Set `isActive: false` on old codes to disable.
