# Email-Based Multi-Tenant Authentication

**Spec ID:** email-auth-multitenant  
**Status:** Planning  
**Priority:** High 🔥  
**Target:** Phase C (Frontend/Backend Integration)

---

## Overview

Migrate authentication from username-based to email-based login for the multi-tenant system. Email provides global uniqueness across all organizations, eliminating ambiguity and simplifying the login flow.

### Current State
- Login uses `username` field
- Usernames are org-scoped (potential ambiguity with same username in different orgs)
- No email validation or unique constraint on email field

### Target State
- Login uses `email` field (globally unique)
- Email becomes primary identifier for authentication
- Username becomes optional display name (not used for login)
- Eliminates org selection step in login flow
- Auto-fetches organizationId from email lookup

---

## Requirements

### Functional Requirements

#### 1. Email Uniqueness (Database Level)
- [ ] Add global unique index on `email` field
- [ ] Email must be globally unique across ALL organizations
- [ ] Enforce at database level (MongoDB unique index)
- [ ] Enforce at application level (validation before insert/update)

#### 2. Login Flow
- [ ] User enters: `email` + `password` (no organization selector needed)
- [ ] Backend queries: `users.findOne({ email })`
- [ ] Single database lookup returns: `userId`, `organizationId`, `email`, `role`, `hashedPassword`
- [ ] Verify password against stored hash
- [ ] Return JWT with `{ userId, organizationId, role, email }`
- [ ] Frontend extracts organizationId from JWT
- [ ] User auto-redirected to their organization's dashboard

#### 3. User Creation
- [ ] Admin creates user with: `name`, `email`, `password`, `role`
- [ ] Validate email format before insert
- [ ] Check email is globally unique (across all orgs)
- [ ] Hash password before storage
- [ ] Auto-assign organizationId from creating admin's org
- [ ] Return error if email already exists (even in different org)

#### 4. Email Validation
- [ ] Valid email format check (RFC 5322 compliant)
- [ ] Case-insensitive email storage (convert to lowercase)
- [ ] Trim whitespace from email
- [ ] Reject disposable/temporary email addresses (optional: use service like disposable-email-domains)

#### 5. Password Reset Flow
- [ ] User enters email
- [ ] System finds user by email
- [ ] Send password reset link (includes JWT token)
- [ ] User clicks link → enters new password
- [ ] Update password in database
- [ ] Auto-login user (redirect to dashboard)

### Non-Functional Requirements

- **Performance:** Email lookup must be indexed (O(log n))
- **Security:** No email enumeration (don't reveal if email exists)
- **Backward Compatibility:** Migrate existing usernames to emails (migration script required)
- **Data Integrity:** No duplicate emails across system
- **UX:** Simple 2-field login form (email + password)

---

## Technical Design

### Database Schema Changes

#### User Model (`server/models/User.js`)

**Current:**
```javascript
{
  username: { type: String, required: true, unique: true },
  email: String,
  password: String,
  role: String,
  organizationId: ObjectId,
  ...
}
```

**Target:**
```javascript
{
  email: { 
    type: String, 
    required: true, 
    unique: true,          // ← Global unique constraint
    lowercase: true,        // ← Auto-lowercase
    trim: true,             // ← Auto-trim whitespace
    match: /.+\@.+\..+/     // ← Email format validation
  },
  username: String,         // ← Optional (for display only, not login)
  password: String,
  role: String,            // super_admin | admin | member
  organizationId: ObjectId,
  emailVerified: Boolean,   // ← NEW (optional enhancement)
  createdAt: Date,
  updatedAt: Date
}

// Indexes
db.users.createIndex({ email: 1 }, { unique: true })
db.users.createIndex({ organizationId: 1, email: 1 })
```

### API Changes

#### Authentication Endpoints

**POST /api/v1/auth/login**

**Before:**
```json
{
  "username": "john_doe",
  "password": "SecurePass@123"
}
```

**After:**
```json
{
  "email": "john@company.com",
  "password": "SecurePass@123"
}
```

**Response (same structure, different data source):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "64a5e7f8c9d2b3a1e4f5g6h7",
      "name": "John Doe",
      "email": "john@company.com",
      "role": "member",
      "organizationId": "64a5e7f8c9d2b3a1e4f5g6h1"
    },
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**Error Response (No email enumeration):**
```json
{
  "success": false,
  "message": "Invalid email or password"  // ← Generic message
}
```

---

**POST /api/v1/auth/users** (Create User)

**Before:**
```json
{
  "name": "Jane Smith",
  "username": "jane_smith",        // ← Username required
  "password": "StrongPass@456",
  "role": "member"
}
```

**After:**
```json
{
  "name": "Jane Smith",
  "email": "jane@company.com",     // ← Email required (globally unique)
  "password": "StrongPass@456",
  "role": "member"
  // username optional (not used for login)
}
```

**Error Case (Email Already Exists):**
```json
{
  "success": false,
  "message": "Email already registered",
  "code": "EMAIL_EXISTS"
}
```

---

**POST /api/v1/auth/forgot-password** (NEW)

```json
{
  "email": "john@company.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password reset link sent to email"
}
```

---

**POST /api/v1/auth/reset-password** (NEW)

```json
{
  "token": "jwt-reset-token",
  "newPassword": "NewPass@789"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password reset successfully",
  "data": {
    "token": "jwt-auth-token",
    "user": { ... }
  }
}
```

---

### Frontend Changes

#### Login Screen (`lib/presentation/screens/login_screen.dart`)

**Form Fields:**
```dart
// Before
TextFormField(label: "Username")
TextFormField(label: "Password")

// After
TextFormField(label: "Email", keyboardType: TextInputType.emailAddress)
TextFormField(label: "Password", obscureText: true)
```

**Validation:**
```dart
// Email validation
if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    .hasMatch(email)) {
  showError("Invalid email format");
}
```

**API Call:**
```dart
// Before
await apiClient.login(username: username, password: password)

// After
await apiClient.login(email: email, password: password)
```

---

## Implementation Tasks

### Phase 1: Backend Preparation (3-4 hours)

- [ ] **Task 1.1:** Update User model schema
  - Add email validation rules
  - Add global unique index
  - Make email required
  - Keep username optional

- [ ] **Task 1.2:** Create migration script
  - Convert existing usernames to emails
  - Handle email collisions (append organization name if needed)
  - Verify all users have valid emails post-migration
  - Create backup before running

- [ ] **Task 1.3:** Update authController.js
  - Change login to query by email instead of username
  - Update user creation to require email
  - Add email validation (format + uniqueness)
  - Return generic error for security (no email enumeration)

- [ ] **Task 1.4:** Add password reset endpoints
  - POST /auth/forgot-password
  - POST /auth/reset-password
  - Generate short-lived reset tokens (15 min expiry)

- [ ] **Task 1.5:** Update test accounts
  - Modify `create-test-accounts.js` to use emails
  - Example: testmember1@ith.com, testadminorg@ith.com
  - Update existing test documentation

- [ ] **Task 1.6:** Update API documentation
  - Update docs/API_REFERENCE.md
  - Change login endpoint docs
  - Add forgot-password/reset-password docs
  - Update error codes

### Phase 2: Frontend Changes (2-3 hours)

- [ ] **Task 2.1:** Update login screen UI
  - Change username field to email field
  - Add email format validation
  - Update placeholder text
  - Update keyboard type to email

- [ ] **Task 2.2:** Update auth provider
  - Change login method signature
  - Update password reset flow
  - Handle email-based responses

- [ ] **Task 2.3:** Update API client
  - Change login endpoint call parameters
  - Add forgot-password method
  - Add reset-password method

- [ ] **Task 2.4:** Update user creation screen
  - Change username field to email field
  - Add email validation
  - Validate email is globally unique

- [ ] **Task 2.5:** Add forgot password screen (NEW)
  - Email input field
  - Submit button
  - Success/error messages
  - Link back to login

- [ ] **Task 2.6:** Add reset password screen (NEW)
  - Parse reset token from URL/deep link
  - New password input
  - Confirm password input
  - Submit button

### Phase 3: Testing & Validation (2-3 hours)

- [ ] **Task 3.1:** Run migration script
  - Backup production database
  - Test on staging first
  - Verify all users have emails
  - Verify no duplicates

- [ ] **Task 3.2:** Test login flow
  - Login with email + password
  - Test with uppercase/lowercase emails
  - Test with email + spaces
  - Verify organizationId auto-fetched
  - Verify JWT contains correct org context

- [ ] **Task 3.3:** Test error cases
  - Invalid email format
  - Non-existent email
  - Wrong password
  - Email already exists (during user creation)
  - Verify no email enumeration

- [ ] **Task 3.4:** Test password reset flow
  - Request password reset
  - Check email received
  - Click reset link
  - Enter new password
  - Auto-login after reset

- [ ] **Task 3.5:** Test user creation
  - Create user with email
  - Verify email is globally unique
  - Test duplicate email rejection
  - Test email validation

- [ ] **Task 3.6:** Cross-org testing
  - Create 2 organizations
  - Create user A in Org1 (email: john@test.com)
  - Create user B in Org2 (email: john@test.com)
  - Verify second creation rejected (email already exists)
  - This proves global uniqueness is working ✅

### Phase 4: Documentation & Deployment (1-2 hours)

- [ ] **Task 4.1:** Update documentation
  - Update ROLES_AND_PERMISSIONS.md
  - Update USER_GUIDE.md (new login flow)
  - Update API_REFERENCE.md (new endpoints)
  - Update TECHNICAL_DOCUMENTATION.md

- [ ] **Task 4.2:** Update test scripts
  - Update test-integration.js
  - Update test-super-admin.js
  - Update test-multi-tenant.js

- [ ] **Task 4.3:** Deploy
  - Deploy to staging
  - Run full test suite
  - Deploy to production
  - Monitor for errors (24 hours)

- [ ] **Task 4.4:** Update admin guides
  - How to reset user passwords
  - How to find users by email
  - How to handle email collisions

---

## Database Migration Script

**File:** `server/scripts/migrate-username-to-email.js`

**Logic:**
```
For each user:
  If user already has email → skip
  If user.email is empty:
    If username@organizationSlug.com exists elsewhere → 
      Generate: username+organizationId@taskmanager.internal
    Else →
      Use: username@organizationSlug.com
  
  Set email to lowercase
  Trim whitespace
  Validate email format
  
  If email already exists in database →
    STOP and report conflict (manual resolution needed)
  
  Save user with new email

Create unique index on email

Report:
  - Total users processed
  - Emails auto-generated
  - Conflicts found (if any)
  - Success rate
```

---

## Security Considerations

### Email Enumeration Prevention
**❌ Bad:** "Email not found in system"
```json
{ "success": false, "message": "Email does not exist" }
```

**✅ Good:** Generic message
```json
{ "success": false, "message": "Invalid email or password" }
```

This prevents attackers from enumerating valid emails in the system.

### Password Reset Security
- Reset tokens expire after 15 minutes
- One-time use (delete token after use)
- Include user ID and email in token payload
- Verify token signature matches
- Force re-authentication after reset

### Email Verification (Optional Future Enhancement)
- Send verification email on signup
- User must verify email before first login
- Prevents typos and fake emails
- Reduces spam/test accounts

---

## Edge Cases & Error Handling

### Edge Case 1: Duplicate Email During Migration
**Scenario:** Two users have username "john" in different orgs during migration
```
User 1: john@org1.com
User 2: john@org2.com (but already used by User 1)

Solution:
User 2 becomes: john+62a5e7f8c9d2b3a1e4f5g6h2@taskmanager.internal
(username + userId hash)
```

### Edge Case 2: User Changes Organization
**Scenario:** User leaves Org A and joins Org B with same email
```
Current: Cannot happen (email is globally unique)
Solution: User must be deleted from Org A first, then added to Org B
(Or support "transfer" logic in future)
```

### Edge Case 3: Email Contains Organization Name
**Scenario:** User email is "john@companyA.com" but works for CompanyB
```
Solution: Email belongs to person, not organization
- Email is globally unique identifier
- organizationId is separate field
- User can only belong to one org at a time
```

### Edge Case 4: Invalid Email Format During Migration
**Scenario:** Legacy user has "john" as email (no @)
```
Solution: Generate: john+organizationSlug@taskmanager.internal
Admin can manually update user's email later
```

---

## Testing Strategy

### Unit Tests (Backend)
```javascript
// authController.js tests
✓ Login with valid email + password
✓ Login with invalid email + password
✓ Login with non-existent email
✓ Login with uppercase email → auto-lowercase
✓ Create user with duplicate email → reject
✓ Create user with invalid email format → reject
✓ Password reset flow → token generation + expiry
```

### Integration Tests (Frontend + Backend)
```
✓ Complete login flow with email
✓ Logout and re-login
✓ Forgotten password flow
✓ Create account flow
✓ Cross-organization email uniqueness
✓ Session persistence after email-based login
```

### Manual Testing
```
✓ Login screen displays email field (not username)
✓ Keyboard type is email
✓ Email validation shows on blur
✓ Forgot password link works
✓ Reset password email arrives
✓ Reset password link opens app
✓ New password works for login
✓ Old password doesn't work after reset
```

---

## Rollback Plan

**If issues arise:**

1. **Restore database from backup** (pre-migration state)
2. **Revert backend code** to username-based auth
3. **Revert frontend** to username field
4. **Verify login works** with old credentials
5. **Investigate issues** before re-attempting

**Communication:**
- Notify users of temporary login issue
- Provide estimated time to resolution
- Option to use forgotten password flow as interim workaround

---

## Success Criteria

- [ ] ✅ All users can login with email + password
- [ ] ✅ Email is globally unique across all organizations
- [ ] ✅ No email enumeration possible (generic error messages)
- [ ] ✅ Password reset flow works end-to-end
- [ ] ✅ Existing users successfully migrated
- [ ] ✅ No data loss during migration
- [ ] ✅ API tests pass (9/9 from integration suite)
- [ ] ✅ Frontend login screen shows email field only
- [ ] ✅ No username field in login flow
- [ ] ✅ OrganizationId auto-fetched and stored in JWT
- [ ] ✅ Users correctly routed to their organization's dashboard
- [ ] ✅ Performance: Email lookup completes in <100ms

---

## Timeline

| Phase | Tasks | Estimated Time | Dependencies |
|-------|-------|-----------------|--------------|
| **Phase 1** | Backend: Schema, Migration, API | 3-4 hours | None |
| **Phase 2** | Frontend: UI, Provider, Screens | 2-3 hours | Phase 1 complete |
| **Phase 3** | Testing & Validation | 2-3 hours | Phase 1 + 2 complete |
| **Phase 4** | Docs & Deployment | 1-2 hours | Phase 1-3 complete |
| **TOTAL** | | **8-12 hours** | |

---

## References

- Current User Model: `backend/models/User.js`
- Current Login Controller: `backend/controllers/authController.js`
- Current Auth Routes: `backend/routes/authRoutes.js`
- Frontend Auth: `frontend/lib/state/auth_provider.dart`
- Frontend Login: `frontend/lib/presentation/screens/login_screen.dart`

---

**Spec Status:** ✅ Ready for Implementation  
**Last Updated:** 2026-07-23  
**Created By:** Architecture Review
