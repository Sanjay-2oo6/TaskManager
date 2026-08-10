# Testing Checklist: Task Manager

**Start Date:** [YYYY-MM-DD]  
**Tester:** [Your Name]  
**Branch:** feat/bulk-user-import

---

## Phase 1: Environment Setup ✓

### Backend Preparation
- [ ] Backend .env file exists with all required keys
- [ ] MongoDB connection string verified
- [ ] JWT_SECRET configured
- [ ] AWS S3 credentials valid
- [ ] Firebase service account JSON present
- [ ] Local machine IP address noted: `_____________`
- [ ] Git repository initialized and pushed

### Frontend Preparation
- [ ] Flutter SDK installed (`flutter --version`)
- [ ] Android SDK/emulator available OR iOS device connected
- [ ] `flutter pub get` completed without errors
- [ ] No dart compilation errors (`flutter analyze`)
- [ ] Git branch: feat/bulk-user-import checked out

### Testing Environment
- [ ] Device/Emulator ready
- [ ] Network connectivity verified
- [ ] Enough storage space available
- [ ] Development machine not on power saver mode

---

## Phase 2: Local Backend Testing (localhost:5000)

### Backend Startup
- [ ] Navigated to backend folder
- [ ] Ran `npm run dev` successfully
- [ ] Server logs show "Connected to MongoDB"
- [ ] No critical errors in startup logs
- [ ] Backend available at http://localhost:5000/health

### Frontend Configuration - Local
- [ ] Updated frontend/.env with local IP: `http://192.168.1.X:5000`
- [ ] Flutter app rebuilt with new .env
- [ ] App points to correct backend URL

### Test 1: Authentication (Login)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] App starts and shows login screen
- [ ] Valid admin credentials login successfully
- [ ] JWT token appears in local storage
- [ ] App navigates to home/dashboard screen
- [ ] No 401 errors in logs
- [ ] Logout works correctly

**Notes:** ___________________________________________________________

### Test 2: View Tasks List
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] Tasks screen loads within 3 seconds
- [ ] Task list displays all user's tasks
- [ ] Task titles, dates, and statuses visible
- [ ] No 500 errors in backend logs
- [ ] Scrolling works smoothly
- [ ] No duplicate tasks displayed

**Notes:** ___________________________________________________________

### Test 3: Create New Task (Admin)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] Admin can access task creation screen
- [ ] Can fill in task title, description
- [ ] Can select assignee(s)
- [ ] Task saves successfully (HTTP 201)
- [ ] Task appears in list immediately
- [ ] Backend logs show successful creation
- [ ] No validation errors on invalid input

**Notes:** ___________________________________________________________

### Test 4: Submit Proof/Evidence (Member)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] Member can view assigned tasks
- [ ] Can access submission/proof upload screen
- [ ] Can select image from device/gallery
- [ ] Image uploads successfully (< 10 seconds for 1MB)
- [ ] File stored in AWS S3 (verified in bucket)
- [ ] Submission status shows "pending"
- [ ] No file size or format errors

**Notes:** ___________________________________________________________

### Test 5: Review & Approve Submission (Admin)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] Admin can view pending submissions
- [ ] Can see submitted images/files
- [ ] Can add approval/rejection feedback
- [ ] Can approve or reject submission
- [ ] Status updates in real-time (or after refresh)
- [ ] Member receives notification
- [ ] Audit logs record the action

**Notes:** ___________________________________________________________

### Test 6: Real-time Features (Socket.IO)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] WebSocket connection established (check browser DevTools)
- [ ] Task updates appear in real-time across devices
- [ ] Chat messages appear without refresh
- [ ] Notifications push in real-time
- [ ] Connection remains stable for 10+ minutes
- [ ] No "WebSocket connection failed" errors

**Notes:** ___________________________________________________________

### Local Backend Testing Summary
**Result:** ☐ ALL PASS ☐ SOME FAILURES ☐ CRITICAL ISSUES

**Issues Found:**
1. _________________________________________________________________
2. _________________________________________________________________
3. _________________________________________________________________

**Severity:** ☐ Blocker ☐ High ☐ Medium ☐ Low

---

## Phase 3: Production Deployment (Render)

### Render Deployment
- [ ] Created Render account and web service
- [ ] Connected GitHub repo (feat/bulk-user-import branch)
- [ ] Configured environment variables in Render
- [ ] Deployment completed without errors
- [ ] Production URL obtained: `_________________________`
- [ ] Health check passes: `curl https://your-app/health`
- [ ] First request takes < 30 seconds (container startup)

### Production URL Verification
- [ ] App is accessible publicly
- [ ] No 502/503 errors
- [ ] Database connection working
- [ ] S3 connection working
- [ ] HTTPS certificate valid

### Render Logs Monitoring
- [ ] Logs accessible in Render dashboard
- [ ] No startup errors
- [ ] No persistent error messages
- [ ] Server responding to requests

---

## Phase 4: Production Backend Testing (Render + Mobile)

### Frontend Configuration - Production
- [ ] Updated frontend/.env with production URL: `https://...onrender.com`
- [ ] Removed any hardcoded localhost references
- [ ] Flutter app rebuilt with production URL
- [ ] No API errors due to URL mismatch

### Test 1: Authentication (Production)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] Login works from production backend
- [ ] Response time: ____ seconds
- [ ] No SSL/certificate errors
- [ ] JWT token obtained and stored

**Notes:** ___________________________________________________________

### Test 2: View Tasks (Production)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] Tasks load from production backend
- [ ] Response time: ____ seconds
- [ ] All tasks display correctly
- [ ] No data inconsistencies from local testing

**Notes:** ___________________________________________________________

### Test 3: Create Task (Production)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] Can create task on production
- [ ] Response time: ____ seconds
- [ ] Task appears in production list
- [ ] Task created via local backend still visible

**Notes:** ___________________________________________________________

### Test 4: Submit Proof (Production)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] File upload successful to production
- [ ] Upload time: ____ seconds
- [ ] File stored in production S3 bucket
- [ ] No SSL errors during upload

**Notes:** ___________________________________________________________

### Test 5: Approve Submission (Production)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] Approval process works on production
- [ ] Status updates reflect in database
- [ ] No errors in Render logs

**Notes:** ___________________________________________________________

### Test 6: Real-time Features (Production)
**Status:** ☐ PASS ☐ FAIL ☐ SKIP

- [ ] WebSocket connects successfully (may be slower)
- [ ] Real-time updates work or gracefully degrade
- [ ] Notifications received

**Notes:** ___________________________________________________________

### Production Backend Testing Summary
**Result:** ☐ ALL PASS ☐ SOME FAILURES ☐ CRITICAL ISSUES

**Issues Found:**
1. _________________________________________________________________
2. _________________________________________________________________
3. _________________________________________________________________

**Severity:** ☐ Blocker ☐ High ☐ Medium ☐ Low

---

## Phase 5: Comparison & Analysis

### Performance Comparison

| Metric | Local | Production | Difference | Notes |
|--------|-------|------------|-----------|-------|
| Login Response | ___ms | ___ms | ±___ms | |
| Task List Load | ___ms | ___ms | ±___ms | |
| Task Creation | ___ms | ___ms | ±___ms | |
| File Upload (1MB) | ___s | ___s | ±___s | |
| Proof Approval | ___ms | ___ms | ±___ms | |
| WebSocket Connect | ___ms | ___ms | ±___ms | |

### Data Consistency
- [ ] Tasks created on local visible on production
- [ ] Submissions visible in both environments
- [ ] User data consistent across backends
- [ ] No duplicate records

### Error Handling
- [ ] Invalid input rejected gracefully
- [ ] Network errors handled properly
- [ ] 401/403 errors show meaningful messages
- [ ] 500 errors logged but don't crash app

### Browser/DevTools Checks
- [ ] No JavaScript console errors
- [ ] No network 4xx/5xx errors
- [ ] API requests all successful (2xx status)
- [ ] Local storage contains valid JWT

---

## Phase 6: Issues & Blockers

### Critical Issues (Block Release)
**Issue 1:**
- **Description:** _____________________________________________________
- **Steps to Reproduce:** ___________________________________________
- **Expected:** ______________________________________________________
- **Actual:** ________________________________________________________
- **Environment:** ☐ Local ☐ Production ☐ Both
- **Severity:** ☐ Blocker ☐ High
- **Status:** ☐ New ☐ Investigating ☐ Fixed ☐ Deferred

---

### High Priority Issues (Should Fix)
**Issue 1:**
- **Description:** _____________________________________________________
- **Environment:** ☐ Local ☐ Production ☐ Both
- **Severity:** ☐ High
- **Status:** ☐ New ☐ Investigating ☐ Fixed

---

### Medium Priority Issues (Nice to Have)
**Issue 1:**
- **Description:** _____________________________________________________
- **Environment:** ☐ Local ☐ Production ☐ Both
- **Severity:** ☐ Medium
- **Status:** ☐ New ☐ Deferred

---

### Low Priority Issues (Future)
- Issue 1: _________________________________________________________________
- Issue 2: _________________________________________________________________

---

## Phase 7: Sign-Off

### Testing Results Summary

**Total Tests:** 6 per environment = 12 total

**Local Backend:** ___/6 PASS

**Production Backend:** ___/6 PASS

**Overall Result:**
- ☐ ALL TESTS PASS - READY FOR RELEASE
- ☐ MOST TESTS PASS - READY WITH CONDITIONS
- ☐ SOME TESTS FAIL - NEEDS FIXES
- ☐ CRITICAL FAILURES - DO NOT RELEASE

### Recommendations

**If All Pass:**
- [ ] Merge feat/bulk-user-import to main
- [ ] Deploy to production
- [ ] Proceed with bulk-user-import feature development

**If Some Issues:**
- [ ] List blockers in GitHub issues
- [ ] Create PR with fixes
- [ ] Re-test after each fix
- [ ] Update this checklist

**If Critical Issues:**
- [ ] Do NOT deploy
- [ ] Investigate root cause
- [ ] Fix and re-test from Phase 2

### Sign-Off

**Tester Name:** ____________________________

**Date Completed:** ____________________________

**Signature/Approval:** ____________________________

**Next Steps:** 
- [ ] Merge to main
- [ ] Deploy production version
- [ ] Notify team of results
- [ ] Begin bulk-user-import implementation

---

**Testing Branch:** feat/bulk-user-import  
**GitHub URL:** https://github.com/Sanjay-2oo6/Task-manager  
**Test Execution Date:** [YYYY-MM-DD]  
**Duration:** [X hours]
