# Frontend Testing Plan

**Backend Status**: ✅ Running on http://localhost:5000 (13/13 terminal tests passed)
**Frontend Status**: ⏳ Ready for testing

---

## Part 1: MANUAL EMULATOR/CHROME TESTS (Required - ~45 min)

### 🔴 Critical Priority (20 min) - Test First!

#### Test 1: Bug #3 - Delete Button Logic
**Scenario**: Org admin should NOT see delete button for themselves
- Login: `testadminorg@ith.com` / `Test123!`
- Navigate to: Team Management screen
- ✅ PASS: Delete button visible for members (`testmember1`, `testmember2`)
- ✅ PASS: NO delete button for `testadminorg` (self)
- ❌ FAIL: If delete button appears for org admin themselves

#### Test 2: Bug #1 - Password Change Endpoint
**Scenario**: Password change should work (PUT not PATCH)
- Login: `testmember1@ith.com` / `Test123!`
- Navigate to: Profile → Change Password
- Old: `Test123!`, New: `NewPass123!`
- ✅ PASS: No 404 error, success message shown
- ✅ PASS: Can login with new password
- ❌ FAIL: 404 error or password not changed

#### Test 3: Fix #5 - Pagination UI
**Scenario**: Lists should show pagination controls
- Login as admin: `testadminorg@ith.com` / `Test123!`
- Navigate to: Pending Submissions
- ✅ PASS: Max 20 items per page
- ✅ PASS: Page navigation visible (if >20 submissions)
- ✅ PASS: Can navigate between pages
- ❌ FAIL: Shows all items without pagination

#### Test 4: Fix #1 - Multi-Tenant Isolation
**Scenario**: Users only see their organization's data
- Login: `testmember1@ith.com` / `Test123!`
- Navigate to: Task List
- ✅ PASS: Only see tasks from "ith" organization
- ✅ PASS: No tasks from other organizations visible
- ❌ FAIL: Can see tasks from other orgs

#### Test 5: Fix #8 - Input Validation
**Scenario**: Weak passwords should be rejected
- Login as admin: `testadminorg@ith.com` / `Test123!`
- Navigate to: Add User
- Try password: `weak`
- ✅ PASS: Error message: "Must be at least 8 characters"
- ✅ PASS: Cannot submit form
- ❌ FAIL: Weak password accepted

---

### 🟡 Standard Priority (25 min) - Test After Critical

#### Authentication Flow (5 min)
1. **Valid Login**
   - Use: `testmember1@ith.com` / `Test123!`
   - ✅ Login successful, redirects to dashboard

2. **Invalid Login**
   - Use: `wrong@email.com` / `wrongpass`
   - ✅ Error message shown, stays on login screen

3. **Logout**
   - Click logout button
   - ✅ Redirects to login screen
   - ✅ Cannot access protected screens without re-login

#### Task Management (8 min)
4. **View Task List** (Member)
   - Login as member
   - ✅ See assigned tasks
   - ✅ Task cards show: title, description, status, priority, due date

5. **Task Detail** (Member)
   - Click on a task
   - ✅ Full details visible
   - ✅ Can view task chat/messages
   - ✅ Can submit work (if not already submitted)

6. **Create Task** (Admin)
   - Login as admin
   - Create new task with all fields
   - ✅ Task created successfully
   - ✅ Can assign to team members

7. **Update Task** (Admin)
   - Edit existing task
   - ✅ Changes saved
   - ✅ Members see updated task

#### Submission Workflow (7 min)
8. **Submit Work** (Member)
   - Login as member
   - Open assigned task
   - Submit work with description
   - ✅ Submission created, status "pending"

9. **Review Submission** (Admin)
   - Login as admin
   - View pending submissions
   - Approve one submission
   - ✅ Status changes to "approved"

10. **Reject Submission** (Admin)
    - Reject a submission with feedback
    - ✅ Status "rejected", feedback visible to member

#### Real-Time Features (5 min)
11. **Task Chat Messages**
    - Open task detail
    - Send message
    - ✅ Message appears in chat
    - (Optional: Test with 2 browsers for real-time)

12. **Live Updates**
    - Admin assigns new task
    - ✅ Member sees notification (if FCM working)
    - ✅ Task list updates

---

## Part 2: TERMINAL TESTS (Automated - ~5 min)

### Frontend Compilation & Build Tests

#### Test 1: Dependencies Installation
```bash
cd frontend
flutter pub get
```
**Expected**: All dependencies install without errors

#### Test 2: Code Analysis
```bash
flutter analyze
```
**Expected**: No errors, warnings acceptable

#### Test 3: Web Build
```bash
flutter build web
```
**Expected**: Build completes successfully

#### Test 4: Android Build Check (Optional)
```bash
flutter build apk --debug
```
**Expected**: APK builds without errors

---

## Part 3: E2E AUTOMATED TESTS (Future - Not Yet Implemented)

**Status**: ❌ No E2E test framework configured yet

### Recommended E2E Framework: Flutter Integration Tests

**To implement in future:**
```bash
# Add to pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### E2E Test Scenarios (Future Implementation)

#### E2E-1: Complete Task Submission Flow
1. Admin creates task
2. Member receives task
3. Member submits work
4. Admin reviews and approves
5. Member sees approved status

#### E2E-2: Multi-User Real-Time Collaboration
1. User A and User B open same task
2. User A sends message
3. User B sees message in real-time
4. Both users see live updates

#### E2E-3: Authentication & Authorization
1. Login as member
2. Try to access admin-only screen
3. Verify access denied
4. Login as admin
5. Verify admin screens accessible

#### E2E-4: Offline Functionality
1. Load app with internet
2. Disconnect internet
3. Verify cached data accessible
4. Reconnect internet
5. Verify sync works

---

## Testing Checklist Summary

### ✅ DO NOW: Manual Tests
- [ ] 5 Critical Priority Tests (20 min) - **START HERE**
- [ ] 12 Standard Priority Tests (25 min)
- [ ] Terminal compilation tests (5 min)

### ⏳ DO LATER: E2E Tests
- [ ] Set up integration_test framework
- [ ] Implement 4 E2E test scenarios
- [ ] Automate with CI/CD pipeline

---

## Test Credentials

```
Super Admin: testsuperadmin@ith.com / Test123!
Org Admin:   testadminorg@ith.com / Test123!
Member 1:    testmember1@ith.com / Test123!
Member 2:    testmember2@ith.com / Test123!
```

---

## How to Run

### Start Backend (If not running)
```bash
cd backend
npm run dev
# Should be running on http://localhost:5000
```

### Start Frontend (Chrome)
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### Run Terminal Tests
```bash
cd frontend
flutter pub get
flutter analyze
flutter build web
```

---

## Reporting Results

After testing, update this file with results:

**Critical Tests**: ✅ 5/5 passed | ❌ X/5 failed
**Standard Tests**: ✅ X/12 passed | ❌ X/12 failed  
**Terminal Tests**: ✅ X/4 passed | ❌ X/4 failed

**Bugs Found**:
1. [Description]
2. [Description]

**Notes**:
- [Any observations]

