# Staging Test Plan - Phase 2

**Duration:** 48 hours  
**Start Date:** [To be scheduled]  
**QA Team:** [Names]  
**Environment:** staging.taskmanager.com  

---

## Day 1: Core Workflows (Manual Testing)

### Morning (4 hours)

#### Setup
- [ ] Environment ready (DB seeded with test data)
- [ ] 3 test accounts created (admin, member1, member2)
- [ ] Admin account has 5+ team members
- [ ] Slack channel #staging-qa created

#### Test: Admin Member List
```
1. Login as admin
2. Go to Create Task → Member dropdown
3. Verify shows 5+ team members
✅ PASS / ❌ FAIL (screenshot: ___)
Notes:
```

#### Test: Task Creation
```
1. Admin creates task "Test Task 1"
2. Assign to member1 + member2
3. Set priority HIGH, due date tomorrow
4. Add reference file (PDF)
5. Submit
✅ Verify task created
✅ Verify members notified
✅ Verify appears in member's task list
✅ PASS / ❌ FAIL
```

#### Test: Offline Submission (Flight Mode)
```
1. Member1 opens task
2. Enable flight mode (offline)
3. Attach before/after photos
4. Submit with description
✅ See "Queued offline" message
✅ Disable flight mode
✅ See sync notification
✅ Submission synced to admin
✅ PASS / ❌ FAIL
```

#### Test: File Viewing
```
1. Admin opens Task Detail
2. Click reference PDF
✅ Opens in viewer (not download)
3. Click image
✅ Opens in image modal
✅ PASS / ❌ FAIL
```

### Afternoon (4 hours)

#### Test: Rejection & Resubmission
```
1. Admin sees member1's submission in Admin Review
2. Click "REJECT" + add feedback
3. Login as member1
4. Open task detail
✅ See rejection card with feedback
5. Click "Resubmit"
6. Upload new photos + description
7. Submit
✅ Task shows "SUBMITTED" (NOT "pending")
✅ Rejection card GONE
✅ Admin notified of resubmission
✅ PASS / ❌ FAIL
```

#### Test: Real-Time Messages
```
1. Open task in Chrome (Admin)
2. Open same task in Firefox (Member1)
3. Member1 sends message "Test message"
✅ Admin sees immediately (< 1 sec)
4. Admin replies "Got it"
✅ Member1 sees immediately
✅ Read receipts show (✓✓)
✅ PASS / ❌ FAIL
```

#### Test: Task Dependencies
```
1. Create Task A "Prerequisite"
2. Create Task B "Locked Task"
3. Assign B's dependsOn to Task A
✅ Task B shows "WAITING" status
4. Member submits Task A
5. Admin approves
✅ Task B automatically unlocked
✅ Member notified "task unlocked"
✅ PASS / ❌ FAIL
```

---

## Day 2: Advanced Scenarios & Performance

### Morning (4 hours)

#### Test: Multi-Tenant Isolation
```
1. Create Org A with users: admin_a, member_a
2. Create Org B with users: admin_b, member_b
3. Login as admin_a
✅ See only Org A tasks
✅ Member dropdown shows only Org A members
4. Org A admin tries to view Org B task (URL hack)
✅ Get 403 Unauthorized
✅ PASS / ❌ FAIL
```

#### Test: Socket.IO Cross-Org Block
```
1. Admin A joins task from Org A
2. Admin B tries to join from Org B (same taskId)
✅ Connection rejected (error message)
✅ Cannot see chat
✅ PASS / ❌ FAIL
```

#### Test: Pagination
```
1. Create 50+ tasks
2. GET /api/v1/tasks?page=1&limit=20
✅ Returns 20 tasks
✅ Includes pagination metadata
3. Page 2
✅ Different 20 tasks
✅ PASS / ❌ FAIL
```

#### Test: Sync Error Handling
```
1. Queue offline action
2. Disable internet
3. Queue 5 more actions
4. Restart app
✅ Actions still in queue
5. Enable internet
✅ All sync successfully
✅ No 400/403 errors
✅ PASS / ❌ FAIL
```

### Afternoon (4 hours)

#### Performance Test: Concurrent Users
```
# Open 10 concurrent browser tabs
# Each joins same task chat
1. User 1 sends message
✅ All 10 see within 2 seconds
✅ Read receipts sync
✅ No message loss
✅ PASS / ❌ FAIL

# Monitor:
- Server CPU usage (should < 70%)
- Memory stable (no leaks)
- Response times consistent
```

#### Performance Test: File Upload
```
1. Upload 5MB file
✅ Uses 5-minute timeout
✅ S3 succeeds
✅ Signed URL generated
✅ File viewable immediately after
⏱️ Measure time: ___ seconds
✅ PASS / ❌ FAIL
```

#### Stress Test: Database
```
# Run rapid-fire operations
1. Create 100 tasks (async)
2. Create 500 messages (async)
3. Update 100 submissions (async)

✅ All complete without error
✅ Database response times stable
✅ No connection pool exhaustion
✅ PASS / ❌ FAIL
```

#### Security Test: Input Validation
```
1. Try XSS in comment: <script>alert('xss')</script>
✅ Sanitized, no alert appears
2. Try SQL injection in search (N/A for MongoDB)
✅ No errors
3. Try circular dependency
✅ 400 error "Circular dependency detected"
✅ PASS / ❌ FAIL
```

---

## Test Data Requirements

### Users to Create
```
Org: ITH
- admin_ith (super admin)
- admin1_ith (org admin)
- member1_ith
- member2_ith
- member3_ith

Org: TestCorp
- admin_testcorp
- member_testcorp1
- member_testcorp2
```

### Sample Tasks
```
- Task 1: Simple assignment (no dependencies)
- Task 2: With reference files (PDF, images)
- Task 3: With dependencies (depends on Task 1)
- Task 4: Already with submission
- Task 5: With rejection history
```

---

## Defect Logging Template

For each failure, create issue:

```
**Title:** [Workflow] [Environment] - [Description]

**Severity:** 
[ ] Critical (blocks deployment)
[ ] High (major feature broken)
[ ] Medium (workaround exists)
[ ] Low (cosmetic)

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Environment:**
- Browser: Chrome / Firefox / Safari
- OS: Windows / Mac / iOS / Android
- Test Account: admin1_ith
- Timestamp: [UTC]

**Screenshots/Logs:**
[Attach]

**Assigned To:** 
[ ] Dev Lead
[ ] Backend Dev
[ ] Frontend Dev
[ ] QA
```

---

## Test Sign-Off

| Component | Tester | Status | Date | Notes |
|-----------|--------|--------|------|-------|
| Admin Features | [Name] | ✅/❌ | [Date] | |
| Member Features | [Name] | ✅/❌ | [Date] | |
| Offline Sync | [Name] | ✅/❌ | [Date] | |
| Real-Time Chat | [Name] | ✅/❌ | [Date] | |
| Multi-Tenant | [Name] | ✅/❌ | [Date] | |
| Performance | [Name] | ✅/❌ | [Date] | |
| Security | [Name] | ✅/❌ | [Date] | |
| Deployment | [Name] | ✅/❌ | [Date] | |

---

## Final Approval

**QA Lead Sign-Off:**
```
I certify that all critical and high-severity workflows 
have been tested and are working as expected.

Name: ___________________
Date: ___________________
Status: [ ] APPROVED [ ] NEEDS FIXES
```

**Product Lead Sign-Off:**
```
I accept this build for production deployment.

Name: ___________________
Date: ___________________
```

---

## Post-Test Actions

If APPROVED:
1. ✅ Archive test results
2. ✅ Update release notes
3. ✅ Schedule production deployment
4. ✅ Brief on-call team
5. ✅ Notify stakeholders

If NEEDS FIXES:
1. ❌ Assign bugs to dev team
2. ❌ Dev fixes in 24 hours
3. ❌ Re-test on staging
4. ❌ Re-run checklist
5. ❌ Re-schedule deployment

