# EZTeach Deploy Steps — Copy & Paste Ready

## 1. Install dependencies

```bash
cd /Users/brianbruce/Desktop/EZTeach/functions
npm install
cd /Users/brianbruce/Desktop/EZTeach
```

---

## 2. Verify Firebase config

```bash
firebase functions:config:get
```

You should see `stripe`, `sendgrid`, and `app`. If sendgrid is missing:

```bash
firebase functions:config:set sendgrid.api_key="SG.YOUR_SENDGRID_API_KEY_HERE"
```

---

## 3. Deploy functions

```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only functions
```

---

## 4. Deploy Firestore rules (if needed)

```bash
firebase deploy --only firestore:rules
```

---

# Professional Email Notifications

## What sends emails

| Trigger | When | Who receives |
|---------|------|--------------|
| **onUserCreated** | Account created | New user (welcome) |
| **onStudentCreated** | Student added | School admin, linked parents, student (if has email) |
| **onStudentUpdated** | Student email added later | Student (credentials) |
| **onVideoMeetingCreated** | Meeting scheduled | Host + participants (invitation) |
| **onVideoMeetingUpdated** | Meeting cancelled | Participants |
| **sendMeetingReminders** | 24h & 1h before meeting | Host + participants |
| **onEventCreated** | Event or day off added | School owner + staff |
| **sendDayOffReminders** | Day before a day off (4 PM) | School staff |
| **onAnnouncementCreated** | Announcement posted | School staff |
| **onEmergencyAlertCreated** | Emergency alert sent | School staff + all parents |
| **onAttendanceWritten** | Student marked absent | Linked parents |
| **linkParentToStudent** | Parent links to student | Parent (confirmation) |
| **sendReportCardNotification** | Report card envelope tapped | Linked parents |
| **stripeWebhook** | Payment events | School/district owner |
| **sendBillingReminders** | 3 days before renewal (9 AM) | School owner |
| **onSupportClaimCreated** | Support claim submitted | Support inbox |
| **formGridWebhook** | Website contact form | Support inbox |

## Reminders

- **Meeting reminders**: 24 hours and 1 hour before scheduled video meetings
- **Day-off reminders**: 4 PM the day before a day off
- **Billing reminders**: 9 AM, 3 days before subscription renewal
