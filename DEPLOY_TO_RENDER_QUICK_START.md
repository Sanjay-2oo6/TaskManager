# Quick Start: Deploy to Render in 10 Minutes

## What You Need (Already Have ✅)
- ✅ GitHub account with code at: https://github.com/Sanjay-2oo6/TaskManager
- ✅ Backend in `backend/` folder with `npm start` working locally
- ✅ Firebase project with FCM set up
- ✅ AWS S3 bucket for file uploads

## What You Need to Create (NEW)
- ⭕ Render account (free at https://render.com)
- ⭕ MongoDB Atlas cluster (free tier at https://www.mongodb.com/cloud/atlas)
- ⭕ Firebase service account JSON (from Firebase Console)
- ⭕ AWS credentials for S3

---

## 5-Step Deployment

### Step 1: Create MongoDB Cluster (3 minutes)
```
1. Go to https://www.mongodb.com/cloud/atlas
2. Sign up or login
3. Click "Create" → Choose "M0 Sandbox" (free)
4. Region: Asia Pacific (same as your S3)
5. Wait 2-3 minutes for cluster creation

Create Database User:
6. Security → Database Access → Add User
7. Username: taskmanager
8. Password: [Generate strong password] ← SAVE THIS
9. Role: Atlas admin

Add Network Access:
10. Security → Network Access → Add IP
11. Select "Allow from Anywhere" (0.0.0.0/0)

Get Connection String:
12. Click Databases → Connect
13. Choose Node.js driver
14. Copy connection string
15. Replace <password> with your password
16. Change /?retryWrites to /task_manager?retryWrites
17. Result: mongodb+srv://taskmanager:PASSWORD@cluster0...mongodb.net/task_manager...
```

**SAVE**: Your MongoDB connection string

---

### Step 2: Get Firebase Service Account (2 minutes)
```
1. Go to Firebase Console → Your Project
2. Settings (gear) → Service Accounts
3. Click "Generate New Private Key"
4. Save the JSON file

Convert to single line:
5. On Windows PowerShell:
   $json = Get-Content firebase-key.json -Raw | ConvertFrom-Json | ConvertTo-Json -Compress
   $json | Set-Clipboard

OR use https://jsoncrush.com (paste JSON → copy compressed)
```

**SAVE**: Your single-line Firebase JSON

---

### Step 3: Create Render Web Service (2 minutes)
```
1. Go to https://render.com and sign in
2. Click "New +" → Web Service
3. "Connect repository" → select TaskManager
4. Fill in:
   - Name: task-manager-backend
   - Region: Singapore (closest to India)
   - Build Command: cd backend && npm install
   - Start Command: cd backend && node server.js
5. Choose Plan: Free (for testing) or Starter ($7/month)
6. Click "Create Web Service"

⏳ Render starts building (takes 2-5 minutes)
```

**SAVE**: Your Render URL (will be like task-manager-backend-xxx.onrender.com)

---

### Step 4: Add Environment Variables to Render (2 minutes)
```
In Render Dashboard → task-manager-backend → Environment:

Add these variables:

KEY                         VALUE
─────────────────────────────────────────────
NODE_ENV                    production
MONGODB_URI                 [From Step 1]
JWT_SECRET                  [Generate: openssl rand -hex 32]
JWT_EXPIRES_IN              7d
MASTER_ADMIN_USERNAME       superadmin
AWS_ACCESS_KEY_ID           [Your AWS key]
AWS_SECRET_ACCESS_KEY       [Your AWS secret]
AWS_REGION                  ap-south-1
AWS_BUCKET_NAME             [Your bucket name]
FIREBASE_SERVICE_ACCOUNT    [From Step 2]
BACKEND_URL                 https://task-manager-backend-xxx.onrender.com

Click "Save" (auto-redeploys)
```

---

### Step 5: Test & Update Frontend App (1 minute)
```
Test backend is working:
1. Visit: https://task-manager-backend-xxx.onrender.com/health
2. Should see: {"status":"ok", ...}

Update Flutter app:
3. Edit frontend/.env
4. Change: BACKEND_URL=https://task-manager-backend-xxx.onrender.com
5. Rebuild APK: flutter build apk --release

Test on device:
6. Install new APK
7. Login → Try creating/submitting a task
```

---

## Environment Variable Generator

Generate missing values:

### JWT_SECRET (Run this command)
```bash
# On Windows PowerShell:
[System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(32) | ForEach-Object { "{0:x2}" -f $_ } | Join-String

# Output: a1b2c3d4e5f6...  ← Copy this
```

### Check Your Values
```
✅ MONGODB_URI     - Should start with "mongodb+srv://"
✅ JWT_SECRET      - Should be 64 hex characters
✅ Firebase JSON   - Should start with {"type":"service_account",...} (no line breaks)
✅ AWS credentials - Should be from IAM user, not root
✅ S3 bucket       - Should already exist and have upload permissions
```

---

## Common Issues & Fixes

### Build Failed: "Cannot find module"
```
Fix: Check backend/package.json exists
     npm install doesn't have errors locally
     Render uses 'cd backend && npm install'
```

### Deploy Stuck: "Port Already in Use"
```
Fix: Render picks a random port automatically
     Don't set PORT=5000 explicitly (it's assigned by Render)
     Your code: process.env.PORT or 5000 (fallback)
```

### MongoDB Connection Failed
```
Fix: Verify connection string:
     ✅ Username and password correct
     ✅ Cluster name correct
     ✅ Database name in URL (/task_manager)
     ✅ Network Access includes 0.0.0.0/0
```

### Firebase Not Initializing
```
Fix: Check FIREBASE_SERVICE_ACCOUNT:
     ✅ Is a single line (no line breaks)
     ✅ JSON is valid (test on jsonlint.com)
     ✅ All quotes properly escaped
```

### App Still Using localhost
```
Fix: 1. Edit frontend/.env
     2. Change BACKEND_URL to your Render URL
     3. Rebuild: flutter build apk --release
     4. Install new APK
```

---

## Verification Checklist

After deployment, verify:

- [ ] Render shows "Build succeeded"
- [ ] Backend health check passes: https://your-url/health
- [ ] MongoDB Atlas shows connection (Metrics tab)
- [ ] No errors in Render logs (View → Logs)
- [ ] Flutter app points to correct BACKEND_URL
- [ ] APK rebuilt after updating .env
- [ ] Can login with test account
- [ ] Can create tasks
- [ ] Can submit tasks with files
- [ ] Files appear in S3 bucket
- [ ] Admin receives notifications

---

## What's Next

1. ✅ Deploy backend to Render
2. ✅ Update Flutter app to use Render URL
3. ✅ Test submission flow end-to-end
4. ⭕ Create bulk user import feature (from spec)
5. ⭕ Deploy to app stores (Play Store, App Store)

---

## Getting Help

**Render Docs**: https://render.com/docs
**MongoDB Docs**: https://docs.mongodb.com/
**Firebase Docs**: https://firebase.google.com/docs
**Express.js Docs**: https://expressjs.com

---

## Expected Timeline

| Step | Time | Status |
|------|------|--------|
| 1. MongoDB Setup | 5 min | ⏳ |
| 2. Firebase JSON | 2 min | ⏳ |
| 3. Render Service | 5 min | ⏳ |
| 4. Environment Vars | 2 min | ⏳ |
| 5. Test & Update App | 3 min | ⏳ |
| **TOTAL** | **~17 minutes** | ⏳ |

---

## Your Deployed Service URLs

Once complete:
```
Health:  https://task-manager-backend-xxx.onrender.com/health
API:     https://task-manager-backend-xxx.onrender.com/api/v1/
Login:   POST https://task-manager-backend-xxx.onrender.com/api/v1/auth/login
Tasks:   GET https://task-manager-backend-xxx.onrender.com/api/v1/tasks
```

Replace `xxx` with your actual Render service name.

---

## Questions Before Starting?

Read the full guide: `RENDER_DEPLOYMENT_GUIDE.md`

Ready? Let's go! 🚀
