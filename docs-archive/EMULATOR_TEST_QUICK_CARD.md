# ?? EMULATOR TESTING QUICK CARD

## Test Credentials
- Super Admin: testsuperadmin@ith.com / Test123!
- Org Admin: testadminorg@ith.com / Test123!
- Member 1: testmember1@ith.com / Test123!
- Member 2: testmember2@ith.com / Test123!

## Start Testing
```bash
cd frontend
flutter pub get
flutter run
```

## ?? 5 CRITICAL TESTS (20 min)

### 1. Bug #3: Delete Button Logic
- Login as org admin
- Team Management screen
- ? Delete button for members
- ? NO delete for org founder

### 2. Bug #1: Password PUT Endpoint
- Login as member1
- Change password Test123! ? NewPass123!
- ? No 404 error
- ? Can login with new password

### 3. Fix #5: Pagination
- Pending Submissions
- ? Max 20 items per page
- ? Page navigation visible

### 4. Fix #1: Multi-Tenant
- Task list
- ? Only see your org's tasks

### 5. Fix #8: Input Validation
- Add user with password "weak"
- ? Error: "Must be 8+ characters"

## ?? Success Criteria

**Minimum**: All 5 critical pass
**Production**: 90%+ of 89 tests pass

## ?? Start Now!

Test the 5 critical items above.
Full 89-test checklist in TERMINAL_TEST_RESULTS.md

Good luck! ??
