# Pre-Deployment Testing Plan

**Objective:** Complete end-to-end testing before production deployment  
**Duration:** 2-3 hours  
**Environment:** Local development

---

## 🚀 QUICK START - Run Now

### Step 1: Start Backend (5 min)

```bash
cd backend
npm run dev
```

Verify health check:
```bash
curl http://localhost:5000/health
```

Should return: `{"status":"OK"...}`

---

### Step 2: Test Accounts Ready

Default test accounts (from database):
- Admin: `testadminorg@ith.com` / `Test123!`
- Member 1: `testmember1@ith.com` / `Test123!`  
- Member 2: `testmember2@ith.com` / `Test123!`
- Super Admin: `testsuperadmin@ith.com` / `Test123!`

---

## 🧪 TESTING CHECKLIST

### SECTION 1: Backend API Tests (15 min)

#### Test 1.1: Login Works
```bash
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"testadminorg@ith.com","password":"Test123!"}'
```

Expected: `{success: true, data: {user: {...}, token: "..."}}`

- [ ] ✅ PASS

---

#### Test 1.2: Get All Tasks (Admin View)
```bash
# Use TOKEN from login response above
curl -X GET http://localhost:5000/api/v1/tasks \
  -H "Authorization: Bearer TOKEN"
```

Expected: Task array with pagination

- [ ] ✅ PASS (admin sees all tasks)

---

#### Test 1.3: Get My Tasks (Member View)
```bash
# Login as member
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"testmember1@ith.com","password":"Test123!"}'

# Get member's tasks
curl -X GET http://localhost:5000/api/v1/tasks/my \
  -H "Authorization: Bearer MEMBER_TOKEN"
```

Expected: Only tasks assigned to member (fewer than admin)

- [ ] ✅ PASS (member sees only assigned tasks)

---

#### Test 1.4: Get Single Task
```bash
curl -X GET http://localhost:5000/api/v1/tasks/TASK_ID \
  -H "Authorization: Bearer TOKEN"
```

Expected: Single task detail with all fields

- [ ] ✅ PASS

---

### SECTION 2: Frontend Admin Workflow (20 min)

Open app and test as admin:

1. **Login**
   - Email: `testadminorg@ith.com`
   - Password: `Test123!`
   - [ ] ✅ Redirects to admin dashboard

2. **Task Control Tab**
   - [ ] ✅ Task list displays (5+ tasks expected)
   - [ ] ✅ Task titles visible
   - [ ] ✅ Status chips showing
   - [ ] ✅ Priority badges showing
   - [ ] ✅ Due dates visible

3. **Click Task → Detail Screen**
   - [ ] ✅ Detail screen opens
   - [ ] ✅ Task title shows
   - [ ] ✅ Description shows
   - [ ] ✅ Assigned members listed
   - [ ] ✅ Status & priority chips visible

4. **Click COLLABORATION Tab**
   - [ ] ✅ Chat section loads
   - [ ] ✅ Message history visible (if any)
   - [ ] ✅ Message input field present
   - [ ] ✅ Can type message

5. **Click SUBMISSIONS Tab**
   - [ ] ✅ Pending submissions visible
   - [ ] ✅ Can click submission to review

6. **Click TEAM MANAGEMENT Tab**
   - [ ] ✅ Team members listed
   - [ ] ✅ Roles visible

7. **Logout**
   - [ ] ✅ Redirects to login screen

---

### SECTION 3: Frontend Member Workflow (20 min)

Logout and login as member:

1. **Login**
   - Email: `testmember1@ith.com`
   - Password: `Test123!`
   - [ ] ✅ Redirects to member dashboard

2. **My Tasks Tab**
   - [ ] ✅ Task list shows (1-3 tasks expected, NOT all 5)
   - [ ] ✅ Only assigned tasks visible
   - [ ] ✅ Count less than admin's count

3. **Click Task → Detail**
   - [ ] ✅ Detail screen opens
   - [ ] ✅ Task info correct
   - [ ] ✅ Currently assigned to member

4. **Click SUBMIT WORK PROOF**
   - [ ] ✅ File picker opens
   - [ ] ✅ Can select image/PDF
   - [ ] ✅ Description field present

5. **Click COLLABORATION Tab**
   - [ ] ✅ Chat loads
   - [ ] ✅ Can type message

6. **Logout**
   - [ ] ✅ Redirects to login

---

### SECTION 4: Multi-Tenant Isolation (10 min)

If you have multiple organizations:

**Admin from Org A:**
- [ ] ✅ Sees only Org A tasks (e.g., 5 tasks)
- [ ] ✅ NO Org B tasks visible

**Switch to Admin from Org B:**
- [ ] ✅ Sees only Org B tasks (e.g., 3 tasks, DIFFERENT count)
- [ ] ✅ NO Org A tasks visible
- [ ] ✅ No data leakage between orgs

---

### SECTION 5: Error Handling (10 min)

1. **Invalid Login Attempt**
   - Try: `testadmin@ith.com` / `wrongpassword`
   - [ ] ✅ Error shown (not generic, specific message)

2. **Simulate Network Error**
   - Disable WiFi/network
   - Try to load tasks
   - [ ] ✅ Error shows with "Retry" button

3. **Offline Mode**
   - Load tasks online
   - Disable network
   - Refresh
   - [ ] ✅ Cached tasks still visible

4. **Re-enable Network**
   - Enable WiFi/network
   - [ ] ✅ Auto-sync occurs
   - [ ] ✅ Data updated

---

### SECTION 6: Performance Check (10 min)

Time each action:

| Action | Target | Actual | Pass? |
|--------|--------|--------|-------|
| Login | <3s | ___s | [ ] |
| Load task list | <2s | ___s | [ ] |
| Load task detail | <2s | ___s | [ ] |
| Submit work | <3s | ___s | [ ] |

- [ ] ✅ All under target times

---

## ✅ FINAL CHECKLIST

### Backend
- [ ] Health check works
- [ ] Login returns token
- [ ] All tasks endpoint works
- [ ] My tasks endpoint works
- [ ] Single task endpoint works
- [ ] No HTTP 500 errors
- [ ] Responses formatted correctly

### Frontend - Admin
- [ ] Login works
- [ ] Dashboard loads
- [ ] Task list shows all tasks
- [ ] Task detail opens
- [ ] Chat section loads
- [ ] Submissions tab works
- [ ] Logout works

### Frontend - Member  
- [ ] Login works
- [ ] Dashboard loads
- [ ] Task list shows filtered tasks
- [ ] Task detail opens
- [ ] Submit work button present
- [ ] Chat works
- [ ] Logout works

### Multi-Tenant
- [ ] Different orgs see different tasks
- [ ] No cross-org data leakage
- [ ] Member sees only assigned tasks

### Errors
- [ ] Invalid login shows error
- [ ] Network error shows retry
- [ ] Offline caching works
- [ ] Friendly error messages

### Performance
- [ ] No loading over 5 seconds
- [ ] Smooth UI interactions
- [ ] No crashes/freezes

---

## 📊 TEST RESULTS

```
OVERALL STATUS: ✅ PASS / ❌ FAIL

Backend Tests:     ✅ PASS / ❌ FAIL
Frontend - Admin:  ✅ PASS / ❌ FAIL
Frontend - Member: ✅ PASS / ❌ FAIL
Multi-Tenant:      ✅ PASS / ❌ FAIL
Error Handling:    ✅ PASS / ❌ FAIL
Performance:       ✅ PASS / ❌ FAIL

CRITICAL ISSUES FOUND:
(none / list issues)

READY FOR DEPLOYMENT: ✅ YES / ❌ NO - FIX ISSUES FIRST
```

---

## 🔧 IF YOU FIND ISSUES

**Common Problems:**

1. **Login fails**
   - Check: Is backend running?
   - Check: Is database accessible?
   - Check: Are test accounts created?

2. **Task list empty**
   - Check: Are tasks in database?
   - Check: Do they have correct organizationId?

3. **Member sees all tasks**
   - Check: Is `showMyTasksOnly: true` passed?
   - Check: Does API scope by organization?

4. **Slow performance**
   - Check: Database indexes
   - Check: Network latency
   - Check: API response times

5. **Offline not working**
   - Check: Hive caching enabled
   - Check: Connectivity package included

---

## ✅ IF ALL TESTS PASS

You're ready for production deployment!

**Next steps:**
1. Deploy to production
2. Start collecting user feedback
3. Plan Phase E
4. Monitor logs daily

---

## ⏱️ Timeline

**Total Time:** 2-3 hours
- Backend tests: 30 min
- Admin workflow: 20 min
- Member workflow: 20 min
- Multi-tenant: 10 min
- Errors: 10 min
- Performance: 10 min
- Analysis: 20 min buffer

**Start now and let me know results!**

---

**When done, reply with:**
- ✅ ALL TESTS PASS → Ready to deploy
- ❌ SOME FAILURES → List issues, I'll help fix
- ❓ QUESTIONS → Ask and I'll clarify
