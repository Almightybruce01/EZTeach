# EZTeach — Test Account Info (Create New Accounts)

**Use these to create fresh test accounts. Distinct from real schools (e.g. Lincoln).**

---

## 1. School Account
| Field | Value |
|-------|-------|
| Role | School |
| First Name | Test |
| Last Name | Admin |
| School Name | Fae Streets Academy |
| Address | 100 Fae Streets Lane |
| City | Testville |
| State | IL |
| Zip | 62701 |
| Grade From | K |
| Grade To | 5 |
| School Code | 987654 |
| Email | test.faestreets.ezteach@gmail.com |
| Password | EZTeachTest2026! |

---

## 2. Teacher Account
| Field | Value |
|-------|-------|
| Role | Teacher |
| First Name | Crusty |
| Last Name | Rab |
| Phone | 555-0101 |
| Email | test.crustyrab.ezteach@gmail.com |
| Password | EZTeachTest2026! |

**After signup:** Switch School → Add school by code `987654` (Fae Streets Academy).

---

## 3. Substitute Account
| Field | Value |
|-------|-------|
| Role | Sub |
| First Name | Test |
| Last Name | Subbie |
| Phone | 555-0102 |
| Email | test.sub.ezteach@gmail.com |
| Password | EZTeachTest2026! |

**After signup:** Switch School → Add school by code `987654`.

---

## 4. Parent Account
| Field | Value |
|-------|-------|
| Role | Parent |
| First Name | Test |
| Last Name | Parent |
| Phone | 555-0103 |
| Email | test.parent.ezteach@gmail.com |
| Password | EZTeachTest2026! |

**After signup:** My Children → Select school (search "Fae" or "Testville") → Enter Student Code.

---

## 5. District Account
| Field | Value |
|-------|-------|
| Role | District |
| District Name | Testville District |
| Address | 200 District Plaza |
| City | Testville |
| State | IL |
| Zip | 62701 |
| First Name | Test |
| Last Name | District |
| Phone | 555-0104 |
| Number of Schools | 2 |
| Email | test.district.ezteach@gmail.com |
| Password | EZTeachTest2026! |

**After signup:** Add schools by code or create new schools.

---

## 6. District-Created School (when district creates a new school)
| Field | Value |
|-------|-------|
| School Name | Maple Grove Elementary |
| Address | 300 Maple Grove Dr |
| City | Testville |
| State | IL |
| Zip | 62702 |
| 6-Digit School Code | 456789 |
| Admin First Name | School |
| Admin Last Name | Admin |
| Admin Email | test.maplegrove.ezteach@gmail.com |
| Admin Password | EZTeachTest2026! |

Same as creating a school: name, address, city, state, zip, school code, and admin email/password.

---

## Setup Flow for Full Test

1. **Create School** (test.faestreets.ezteach@gmail.com)  
   - School Code: 987654  
   - Add teacher Crusty Rab, add 1–2 students  

2. **Create Teacher** (test.crustyrab.ezteach@gmail.com)  
   - Switch School → Add 987654  

3. **Create Sub** (test.sub.ezteach@gmail.com)  
   - Switch School → Add 987654  

4. **Create Student** (from School account)  
   - Get Student Code  

5. **Create Parent** (test.parent.ezteach@gmail.com)  
   - My Children → Search "Fae Streets" or "Testville" → Pick school → Enter Student Code  

6. **Create District** (test.district.ezteach@gmail.com)  
   - Add address, city, state, zip  
   - Add school 987654 by code OR create new school (with email, password, address)  

---

## App Review Test Account (for Apple)

- **Email:** test.faestreets.ezteach@gmail.com  
- **Password:** EZTeachTest2026!

Ensure the account has sample data: teachers, students, events, announcements.
