# EZTeach — Changes Summary (Complete App Polish)

---

## Latest: Bell Schedule & Teacher Class Schedule

### Bell Schedule (Time-Slot Grid)
- **5 or 10 minute slots** from school start to end
- **School start/end** configurable (default 07:00–15:30)
- **Period types:** Breakfast, Intercom/Good Morning, Homeroom, Class, Lunch (with grade: K, 1–8), Dismissal, etc.
- **Quick-add buttons:** Breakfast, Intercom, Grade Lunches (K–5), Dismissal Bell
- **Time grid view** shows all events in slot layout
- **School and district only** can edit (Firestore rules updated)

### Teacher Class Schedule Tab
- Renamed "Schedule" → **"Class Schedule"**
- Shows **daily bell schedule** in time-slot grid (same as main Bell Schedule view)
- Shows **teacher's classes** list below
- Loads from teacher's schoolId

---

## What Was Done

### 1. Bell Schedule — Fixed
- **Firestore rules:** Corrected create rule for `bellSchedules` — was using `resource.data` for create (invalid); now uses `request.resource.data.schoolId == activeSchool()` for create.
- Schools can create and manage bell schedules; teachers/subs/parents can read.

### 2. Homepage & Teacher Profile — Files & Photos
- **EditHomepageView (School):**
  - PhotosPicker to choose logo from photo library
  - Upload to Firebase Storage (`schoolLogos/{schoolId}/`)
  - Still supports pasting image URL
- **EditTeacherProfileView (Teacher):**
  - PhotosPicker for profile photo
  - Upload to Storage (`teacherPhotos/{userId}/`)
  - Added `teacherUserId` and `currentPhotoUrl` params; TeacherPortalView passes them
- **AddAnnouncementView:**
  - PhotosPicker for optional image attachment
  - Upload to Storage (`documents/{schoolId}/`)
  - Announcement model: new `attachmentUrl` field; ContentView & ParentPortalView display it

### 3. Side Menu — Empty Views & Links
- **NeedSchoolSheetView:** New sheet when user has no school context; shows “Join a school first” and “Switch Schools” button.
- All school-dependent menu items now show this when `schoolId` is empty:
  - Messages, Documents, Analytics, Bell Schedule
  - Sub Requests, My Availability
  - Lesson Plans, Homework, Behavior, Activities
  - Bus Tracking, Lunch Menu, Emergency Alerts
  - Video Meetings, Attendance Analytics, Sub Ranking
- **Parent schoolId:** If parent has no `activeSchoolId`, `loadUserData` fetches first linked student’s `schoolId` from `parentStudentLinks`.

### 4. Special / Mixed Classes
- **SchoolClass.ClassType:** Added `mixed = "mixed"` with display name “Mixed / Special”.
- Existing: Regular, DLP (Dual Language), Cross-Categorical, Inclusion, Other.
- EditClassView already uses class type picker; Mixed is now available.

### 5. Color Coordination
- **EZTeachColors:** `cardStroke` changed from `Color.gray.opacity(0.2)` to `Color.primary.opacity(0.15)` for better contrast in dark mode.

### 6. MainContainerView — Homepage Edit Data
- Loads `schoolLogoUrl` and `welcomeMessage` from Firestore when school is selected.
- Passes these into `EditHomepageView` so current values appear when editing.

### 7. Storage Rules
- Added `teacherPhotos/{teacherId}/{fileName}` — read for authenticated users; write/delete only when `request.auth.uid == teacherId` (teacher’s own photos).

---

## Deploy Steps

```bash
cd /Users/brianbruce/Desktop/EZTeach
firebase deploy --only firestore:rules
firebase deploy --only storage
```

---

## What Cannot Be Fixed (Or Needs Manual Setup)

1. **Simulator / Xcode build:** Build failures in this environment were due to sandbox/permissions. Build and run in Xcode locally.
2. **PhotosUI:** System framework; included by default. If build errors occur, add PhotosUI to the target in Xcode.
3. **Bell Schedule display:** If still empty after school creates a schedule, confirm the school creates at least one schedule and that `schoolId` is set on the user.
4. **Parent portal query:** ParentPortalView announcements query uses `teachersOnly == false`. Ensure the Firestore index exists if it fails (schoolId, teachersOnly, createdAt).

---

## Files Modified

- `firestore.rules` — bell schedule create rule
- `storage.rules` — teacher photos path
- `EZTeach/SchoolClass.swift` — mixed class type
- `EZTeach/Announcement.swift` — attachmentUrl
- `EZTeach/EZTeachColors.swift` — cardStroke
- `EZTeach/MainContainerView.swift` — school customization loading, EditHomepageView params
- `EZTeach/EditHomepageView.swift` — PhotosPicker, Storage upload
- `EZTeach/EditTeacherProfileView.swift` — PhotosPicker, Storage upload, teacherUserId
- `EZTeach/AddAnnouncementView.swift` — PhotosPicker, attachment upload
- `EZTeach/TeacherPortalView.swift` — photoUrl state, EditTeacherProfileView params
- `EZTeach/ContentView.swift` — announcement attachment display, loadAnnouncements attachmentUrl
- `EZTeach/Views/Parent/ParentPortalView.swift` — Announcement attachmentUrl
- `EZTeach/SideMenuView.swift` — NeedSchoolSheetView for empty schoolId, parent schoolId fallback

## Files Created

- `EZTeach/NeedSchoolSheetView.swift` — empty-state sheet for school-dependent features
