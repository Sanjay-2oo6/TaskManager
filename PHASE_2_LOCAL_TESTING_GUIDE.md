# Phase 2: Local Backend Testing - Quick Start Guide

**Status:** ✅ Ready for Mobile Testing  
**Date:** 2026-08-10  
**Backend:** Running on http://192.168.29.120:5000  
**Frontend:** Configured to connect to local backend

---

## What's Been Done ✅

### Backend Setup
- ✅ Backend running with `npm run dev`
- ✅ MongoDB connected and healthy
- ✅ All services initialized (Firebase, S3, Socket.IO)
- ✅ Health endpoint responds at http://localhost:5000/health
- ✅ API endpoints available at http://localhost:5000/api/v1

### Frontend Setup
- ✅ frontend/.env created with: `BACKEND_URL=http://192.168.29.120:5000`
- ✅ Ready for Flutter to build and run

---

## Next Steps: Run the Flutter App

### Step 1: Build Flutter App
```bash
cd frontend
flutter pub get
flutter run
```

**Expected Output:**
```
Flutter run
Running "flutter pub get" in frontend...
Building for Android...
Starting app...
```

### Step 2: Once App Opens

The app should:
1. Show the **Login Screen**
2. Connect to backend at http://192.168.29.120:5000
3. Be ready to test authentication

---

## Test Credentials

Use these credentials to login:

| Role | Email | Password |
|------|-------|----------|
| Super Admin | superadmin@ith.test | SuperAdmin@123 |
| Admin | admin@test.local | Admin@123 |
| Member | member@test.local | Member@123 |

---

## Phase 2 Test Scenarios

Once app is running, execute these 6 tests and document results in TESTING_CHECKLIST.md:

### Test 1: Authentication (Login)
- [ ] App shows login screen
- [ ] Can enter credentials
- [ ] Login succeeds (HTTP 200)
- [ ] JWT token stored locally
- [ ] Navigates to home/dashboard

**Expected Time:** 10-15 seconds

### Test 2: View Tasks List
- [ ] Tasks screen loads
- [ ] All user's tasks displayed
- [ ] Task titles, dates visible
- [ ] No errors in console

**Expected Time:** 3-5 seconds

### Test 3: Create New Task (Admin Only)
- [ ] Admin can access task creation
- [ ] Can fill form (title, description, assignee)
- [ ] Submit creates task
- [ ] Task appears in list

**Expected Time:** 10-20 seconds

### Test 4: Submit Proof/Evidence (Member Only)
- [ ] Member views assigned task
- [ ] Can upload proof image
- [ ] File uploads to S3
- [ ] Submission shows "pending" status

**Expected Time:** 15-30 seconds (depending on file size)

### Test 5: Review & Approve Submission (Admin Only)
- [ ] Admin views pending submissions
- [ ] Can see submitted images
- [ ] Can approve/reject with feedback
- [ ] Status updates

**Expected Time:** 10-15 seconds

### Test 6: Real-time Features
- [ ] WebSocket connected
- [ ] Live updates work (if multiple devices)
- [ ] No connection errors

**Expected Time:** Depends on multi-device setup

---

## During Testing: Monitor Backend Logs

**In separate terminal:**
```bash
cd backend
npm run pm2:logs
# Or: tail -f logs/combined-*.log
```

**What to look for:**
- ✅ API requests logged (GET/POST/PUT/PATCH/DELETE)
- ✅ HTTP 200/201 status codes
- ❌ No 500 errors
- ❌ No database connection errors
- ❌ No authentication failures (401)

---

## Troubleshooting

### "Cannot reach the server" Error
**Solution:** Verify your IP
```bash
ipconfig | findstr "IPv4"
# Should show: 192.168.29.120
```

### App Doesn't Update After .env Change
**Solution:** Rebuild app
```bash
flutter clean
flutter pub get
flutter run
```

### Backend Responds But App Can't Connect
**Solution:** Check firewall
- Allow port 5000 through Windows Defender
- Or temporarily disable firewall for testing

### Login Fails But Credentials are Correct
**Solution:** Check backend logs
```bash
cd backend
npm run pm2:logs
# Look for authentication errors
```

---

## After Testing Each Scenario

1. **Document Result** in TESTING_CHECKLIST.md:
   - Mark as PASS ✅ or FAIL ❌
   - Note any issues
   - Record response times

2. **Check Backend Logs** for errors
3. **Take Screenshots** if bugs found
4. **Continue to Next Test**

---

## Success Criteria

✅ **Phase 2 Complete When:**
- [x] Backend startup verified
- [x] Frontend configured with local IP
- [ ] All 6 test scenarios executed
- [ ] Results documented in TESTING_CHECKLIST.md
- [ ] No critical blockers found

---

## What's the Backend URL Used By App?

Your app will connect to:
```
http://192.168.29.120:5000/api/v1
```

Breaking down:
- `192.168.29.120` = Your local machine IP
- `5000` = Backend port
- `/api/v1` = API version prefix (added by app)

---

## Quick Commands Reference

```bash
# Start Backend (if not already running)
cd backend && npm run dev

# Build & Run Flutter App
cd frontend && flutter run

# Monitor Backend Logs
cd backend && npm run pm2:logs

# Get Local IP
ipconfig | findstr "IPv4"

# Test Health Endpoint
curl http://192.168.29.120:5000/health

# View Frontend Config
cat frontend/.env
```

---

## Need to Switch Back to Production Later?

```bash
# Update frontend/.env to production URL
echo "BACKEND_URL=https://your-app.onrender.com" > frontend/.env

# Rebuild and run
cd frontend && flutter run
```

---

**Status:** 🟢 READY TO RUN FLUTTER APP  
**Next Action:** Run `cd frontend && flutter run` and start Test 1  
**Estimated Duration:** 1-2 hours for all 6 tests + documentation
