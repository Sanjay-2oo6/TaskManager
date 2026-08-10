# Testing Setup Guide: Task Manager

## Overview

This guide covers testing the Task Manager app across three environments:
1. **Local Backend** (localhost:5000) + Mobile App
2. **Production Backend** (Render) + Mobile App
3. **Verification & Comparison**

---

## Prerequisites

- ✅ Git repository initialized and pushed to GitHub (feat/bulk-user-import branch)
- ✅ Backend .env configured with MongoDB URI, JWT secret, AWS S3, Firebase keys
- ✅ Frontend .env template ready
- ✅ Node.js v16+ installed
- ✅ Flutter SDK installed
- ✅ Android emulator or physical device

---

## Part 1: Local Testing (Backend on localhost:5000)

### Step 1.1: Start Backend Locally

```bash
cd backend
npm install              # Install dependencies if not already done
npm run dev              # Start with nodemon (auto-reload on file changes)
```

**Expected Output:**
```
[nodemon] restarting due to changes...
[nodemon] starting `node server.js`
Server running on http://localhost:5000
Connected to MongoDB
```

**Verify Server is Running:**
```bash
curl http://localhost:5000/health
# Should return: {"status":"ok"}
```

### Step 1.2: Get Your Local Machine IP Address

```bash
# Windows (PowerShell)
ipconfig | findstr "IPv4"

# macOS/Linux
ifconfig | grep "inet "
```

**Example Output:**
```
IPv4 Address: 192.168.1.5
```

Note: You'll use this IP for mobile app testing (e.g., http://192.168.1.5:5000)

### Step 1.3: Configure Frontend for Local Backend

Create or update `frontend/.env`:

```env
BACKEND_URL=http://192.168.1.5:5000
```

Replace `192.168.1.5` with your actual machine IP.

### Step 1.4: Run Flutter App on Emulator/Device

```bash
cd frontend
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
```

**For Android Emulator:**
```bash
flutter run -d emulator-5554
```

**For Physical Device:**
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Step 1.5: Test Key Workflows

#### A. Login Test
1. Open app → Login screen
2. Enter admin credentials
3. Verify:
   - ✅ Login succeeds
   - ✅ App navigates to home screen
   - ✅ JWT token stored locally
   - ✅ No network errors

#### B. View Tasks
1. Navigate to tasks screen
2. Verify:
   - ✅ Tasks load from backend
   - ✅ Task list displays correctly
   - ✅ Timestamps are readable
   - ✅ No 401/403 errors

#### C. Create Task (Admin)
1. Navigate to task creation
2. Fill in task details:
   - Name: "Test Task"
   - Description: "Testing from mobile"
   - Assigned to: Select user
3. Verify:
   - ✅ Task created successfully
   - ✅ Task appears in list
   - ✅ Backend logs show creation

#### D. Submit Proof (Member)
1. As member, view assigned task
2. Upload proof image
3. Verify:
   - ✅ File uploads successfully
   - ✅ Submission shows pending status
   - ✅ Image stored in AWS S3

#### E. Approve Submission (Admin)
1. As admin, view pending submissions
2. Approve or reject with feedback
3. Verify:
   - ✅ Status updates to approved/rejected
   - ✅ Member receives notification
   - ✅ Audit log records action

### Step 1.6: Monitor Backend Logs

**Terminal 2 - Watch Logs:**
```bash
cd backend
npm run pm2:logs         # Or: tail -f logs/combined-*.log
```

**Look for:**
- ✅ HTTP requests (200, 201 status codes)
- ✅ No 500 errors
- ✅ JWT validation succeeds
- ✅ Database queries complete
- ✅ S3 uploads successful

### Step 1.7: Document Local Testing Results

Create `LOCAL_TEST_RESULTS.md`:

```markdown
# Local Testing Results - Date

## Backend Status
- Backend Started: YES/NO
- Server Port: 5000
- Database Connected: YES/NO
- S3 Connected: YES/NO
- Firebase Connected: YES/NO

## App Connection
- Device IP: 192.168.1.5
- Backend URL: http://192.168.1.5:5000
- Connection Status: CONNECTED/FAILED

## Test Results

| Test | Status | Notes |
|------|--------|-------|
| Login | PASS/FAIL | |
| View Tasks | PASS/FAIL | |
| Create Task | PASS/FAIL | |
| Submit Proof | PASS/FAIL | |
| Approve Submission | PASS/FAIL | |
| Real-time Updates (Socket.IO) | PASS/FAIL | |

## Issues Found
- Issue 1: ...
- Issue 2: ...

## Next Steps
- [ ] Fix identified issues
- [ ] Re-test workflows
- [ ] Prepare for production testing
```

---

## Part 2: Prepare Production Backend on Render

### Step 2.1: Deploy to Render

**Option A: Using Render Dashboard**
1. Go to https://dashboard.render.com
2. Create new Web Service
3. Connect GitHub repo (feat/bulk-user-import branch)
4. Configure:
   - **Runtime:** Node
   - **Build:** `npm install`
   - **Start:** `npm start`
   - **Environment Variables:** Copy from backend/.env

**Option B: Using Render CLI**
```bash
npm install -g render-cli
render login
render deploy --name task-manager-api
```

### Step 2.2: Verify Render Deployment

```bash
# Test health endpoint
curl https://<your-app>.onrender.com/health

# Expected: {"status":"ok"}
```

**Note:** First request may be slow (container startup)

### Step 2.3: Monitor Render Logs

```bash
# In Render Dashboard:
# Services → task-manager-api → Logs
```

Look for:
- ✅ Server started successfully
- ✅ Database connection established
- ✅ No deployment errors

---

## Part 3: Production Testing (Backend on Render + Mobile App)

### Step 3.1: Update Frontend to Point to Render

Update `frontend/.env`:

```env
BACKEND_URL=https://your-app.onrender.com
```

**Important:** 
- Use HTTPS (not HTTP) for production
- No port number needed

### Step 3.2: Rebuild Flutter App

```bash
cd frontend
flutter pub get
flutter run                    # Hot reload will update API URL
```

### Step 3.3: Repeat All Tests from Part 1.5

Run the same test workflows:
- [ ] Login
- [ ] View Tasks
- [ ] Create Task
- [ ] Submit Proof
- [ ] Approve Submission

### Step 3.4: Monitor Production Logs

**Render:**
```
Dashboard → Services → task-manager-api → Logs
```

**Backend:**
```bash
# SSH into Render instance or check logs in dashboard
```

### Step 3.5: Document Production Testing Results

Create `PRODUCTION_TEST_RESULTS.md`:

```markdown
# Production Testing Results - Date

## Render Deployment
- Deployment URL: https://your-app.onrender.com
- Status: UP/DOWN
- Response Time: XXXms
- Database Connected: YES/NO

## Test Results

| Test | Status | Local | Production | Notes |
|------|--------|-------|------------|-------|
| Login | PASS/FAIL | PASS/FAIL | PASS/FAIL | |
| View Tasks | PASS/FAIL | PASS/FAIL | PASS/FAIL | |
| Create Task | PASS/FAIL | PASS/FAIL | PASS/FAIL | |
| Submit Proof | PASS/FAIL | PASS/FAIL | PASS/FAIL | |
| Approve Submission | PASS/FAIL | PASS/FAIL | PASS/FAIL | |
| Real-time Updates | PASS/FAIL | PASS/FAIL | PASS/FAIL | |

## Performance Comparison

| Metric | Local | Production | Difference |
|--------|-------|------------|-----------|
| Login Response | XXXms | XXXms | +/-XXms |
| Task List Load | XXXms | XXXms | +/-XXms |
| File Upload | XXXs | XXXs | +/-XXs |

## Issues Found
- Issue 1: ...
- Issue 2: ...

## Production Blockers
- [ ] All tests pass
- [ ] No 500 errors
- [ ] Performance acceptable
- [ ] Real-time features work
```

---

## Part 4: Comparison & Issues

### Create Comparison Report

File: `TESTING_COMPARISON.md`

```markdown
# Local vs Production Testing Comparison

## Summary
- Local Tests: X/6 PASS
- Production Tests: X/6 PASS
- Status: READY FOR RELEASE / NEEDS FIXES

## Detailed Comparison

### 1. Login
- **Local:** PASS (100ms)
- **Production:** PASS (250ms)
- **Analysis:** Slower due to network latency

### 2. View Tasks
- **Local:** PASS
- **Production:** FAIL - Timeout after 30s
- **Root Cause:** MongoDB query slow on production
- **Fix:** Add database index on organizationId

### 3. Real-time Updates
- **Local:** PASS
- **Production:** FAIL - Socket.IO disconnects
- **Root Cause:** Render doesn't support persistent connections well
- **Fix:** Check Render WebSocket settings

## Critical Issues (Block Release)
1. Socket.IO disconnects on production
2. Task list timeouts

## Minor Issues (Address Later)
1. Slower response times than local
2. File upload progress bar jumpy

## Recommendations
- [ ] Fix Socket.IO on Render
- [ ] Optimize database queries
- [ ] Add caching layer
- [ ] Re-test after fixes

## Sign-Off
- Tested by: @developer
- Date: 2026-08-10
- Status: READY / NOT READY
```

---

## Troubleshooting

### Backend Connection Issues

**Error:** `Cannot reach the server. Check your network connection.`

**Solutions:**
1. Check backend is running: `curl http://192.168.1.5:5000/health`
2. Verify IP address: `ipconfig | findstr "IPv4"`
3. Check firewall allows port 5000
4. Disable Windows Defender temporarily
5. Try from emulator: `adb shell "curl http://10.0.2.2:5000/health"`

### JWT Token Issues

**Error:** `Unauthorized. Please login again.`

**Solutions:**
1. Clear app data: Settings → Apps → Task Manager → Clear Storage
2. Logout and re-login
3. Check JWT_SECRET matches on backend
4. Verify token isn't expired: Check JWT_EXPIRES_IN in .env

### Socket.IO Disconnects

**Error:** Real-time updates not working

**Solutions:**
1. Check WebSocket is enabled on Render
2. Use same URL scheme (HTTPS for production, HTTP for local)
3. Check CORS settings on backend
4. Look for 401 errors on WebSocket connection

### File Upload Issues

**Error:** Upload fails or takes too long

**Solutions:**
1. Check AWS S3 credentials
2. Verify bucket exists and is accessible
3. Check file size < 2MB
4. Test on same network as backend first

### Database Connection Issues

**Error:** `Connection refused` or `no servers available`

**Solutions:**
1. Check MongoDB URI in .env
2. Verify IP whitelist on MongoDB Atlas
3. Test connection: `mongo <connection-string>`
4. Check firewall allows 27017

---

## Quick Reference

### Restart Backend
```bash
cd backend
npm run dev      # Local development
npm run pm2:restart   # If using PM2
```

### Clear Flutter Cache
```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
flutter run
```

### View Recent Commits
```bash
git log --oneline -10
```

### Switch Between Local/Production
```bash
# Local
echo "BACKEND_URL=http://192.168.1.5:5000" > frontend/.env

# Production
echo "BACKEND_URL=https://your-app.onrender.com" > frontend/.env

# Rebuild
cd frontend && flutter run
```

### Kill Process on Port 5000 (if stuck)
```bash
# PowerShell
Get-Process | Where-Object {$_.ProcessName -like "*node*"} | Stop-Process

# Or find what's using port 5000
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

---

## Success Criteria

✅ Testing is complete when:
- [ ] All 6 workflows pass on local backend
- [ ] All 6 workflows pass on production backend
- [ ] Response times are acceptable (< 2s typical)
- [ ] No unhandled errors or 500s
- [ ] Real-time features work (Socket.IO, notifications)
- [ ] File uploads complete successfully
- [ ] Comparison report generated
- [ ] Issues documented and triaged

---

## Next Steps After Testing

1. ✅ If tests pass:
   - [ ] Merge feat/bulk-user-import to main
   - [ ] Deploy to production
   - [ ] Notify stakeholders
   - [ ] Begin bulk-user-import implementation

2. ❌ If tests fail:
   - [ ] Document all issues
   - [ ] Create bug tickets
   - [ ] Fix highest priority issues
   - [ ] Re-test
   - [ ] Repeat until all pass

---

**Last Updated:** 2026-08-10  
**Testing Phase:** Complete App End-to-End Validation  
**Branch:** feat/bulk-user-import
