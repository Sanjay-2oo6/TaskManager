# Deploying Task Manager Backend to Render

## Overview
This guide walks through deploying the Node.js backend to Render with MongoDB Atlas for production testing.

---

## Prerequisites

1. **GitHub Account** - Your code is already at: https://github.com/Sanjay-2oo6/TaskManager
2. **Render Account** - Sign up at https://render.com (free tier available)
3. **MongoDB Atlas Account** - Sign up at https://www.mongodb.com/cloud/atlas (free tier available)
4. **Firebase Project** - Already set up with FCM (from backend/.env.example)

---

## Step 1: Set Up MongoDB Atlas

### 1.1 Create MongoDB Cluster
1. Go to https://www.mongodb.com/cloud/atlas
2. Sign in or create account
3. Click **"Create"** to build a new cluster
4. Select **M0 Sandbox** (free tier)
5. Choose region: **Asia Pacific (ap-south-1)** - Same as your AWS S3
6. Click **"Create Cluster"** (takes 2-3 minutes)

### 1.2 Create Database User
1. In MongoDB Atlas, go to **Security → Database Access**
2. Click **"Add New Database User"**
3. Username: `taskmanager`
4. Password: Generate strong password and **save it** (you'll need for connection string)
5. Set role to **"Atlas admin"**
6. Click **"Create Database User"**

### 1.3 Add IP Whitelist
1. Go to **Security → Network Access**
2. Click **"Add IP Address"**
3. Select **"Allow Access from Anywhere"** (0.0.0.0/0) for Render compatibility
4. Click **"Confirm"**

⚠️ **Note**: For production, you should whitelist Render's IP range. For testing, this is fine.

### 1.4 Get Connection String
1. Click **"Databases"** tab
2. Click **"Connect"** button on your cluster
3. Select **"Drivers"** → **Node.js**
4. Copy the connection string (looks like):
   ```
   mongodb+srv://taskmanager:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
5. Replace `<password>` with the password you created in step 1.2
6. Replace `/?` with `/task_manager?` (specify database name)
7. **Save this connection string** - you'll need it for Render

**Final format**:
```
mongodb+srv://taskmanager:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/task_manager?retryWrites=true&w=majority
```

---

## Step 2: Set Up Firebase Service Account

### 2.1 Get Firebase Credentials
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to **Project Settings** (gear icon) → **Service Accounts**
4. Click **"Generate New Private Key"**
5. Save the JSON file (keep it secret!)
6. Open the JSON file and copy the entire content

### 2.2 Convert to Single Line
The Firebase JSON needs to be on a single line for environment variables:

```bash
# If on Mac/Linux:
cat firebase-key.json | jq -c . | pbcopy

# If on Windows PowerShell:
$content = Get-Content firebase-key.json -Raw
$json = $content | ConvertFrom-Json | ConvertTo-Json -Compress
$json | Set-Clipboard
```

Or use an online tool: https://jsoncrush.com (paste JSON, copy compressed)

**Save the single-line JSON** - you'll need it for Render.

---

## Step 3: Create Render Service

### 3.1 Connect GitHub Repository
1. Go to https://render.com and sign in
2. Click **"New +"** → **"Web Service"**
3. Click **"Connect a repository"**
4. Search for `TaskManager`
5. Click **"Connect"** next to your repository

### 3.2 Configure Deployment
Fill in the following:

| Field | Value |
|-------|-------|
| **Name** | `task-manager-backend` |
| **Environment** | `Node` |
| **Region** | `Singapore` (closest to ap-south-1) |
| **Build Command** | `npm install` |
| **Start Command** | `node server.js` |

### 3.3 Select Plan
- Choose **Free** for testing (auto-spins down after 15 min inactivity)
- Or **Starter** ($7/month) for continuous availability

---

## Step 4: Add Environment Variables

### 4.1 In Render Dashboard
1. Scroll down to **"Environment"**
2. Click **"Add Environment Variable"**
3. Add all variables from the table below:

| Key | Value | Notes |
|-----|-------|-------|
| `NODE_ENV` | `production` | Required for production mode |
| `PORT` | `5000` | Render will override this (5000 is default) |
| `MONGODB_URI` | `mongodb+srv://taskmanager:PASSWORD@cluster0...` | From Step 1.4 |
| `JWT_SECRET` | Generate new: `openssl rand -hex 32` | Must be secure |
| `JWT_EXPIRES_IN` | `7d` | Token expiration |
| `MASTER_ADMIN_USERNAME` | `superadmin` | Master admin username |
| `AWS_ACCESS_KEY_ID` | Your AWS key | From your AWS account |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret | From your AWS account |
| `AWS_REGION` | `ap-south-1` | Your S3 region |
| `AWS_BUCKET_NAME` | Your bucket name | Your S3 bucket |
| `FIREBASE_SERVICE_ACCOUNT` | Single-line JSON from Step 2.2 | Must be properly escaped |
| `BACKEND_URL` | `https://task-manager-backend-xxx.onrender.com` | Your Render URL (you'll get this after deploy) |

### 4.2 Generate JWT Secret
```bash
# On your local machine (any OS):
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Output example: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
```

---

## Step 5: Deploy

### 5.1 Click Deploy
1. In Render dashboard, click **"Create Web Service"**
2. Render will start building (this takes 2-5 minutes)
3. Watch the **"Build"** and **"Deploy"** logs

### 5.2 Monitor Logs
```
Expected logs:
✅ Logger initialized
✅ Firebase Admin Initialized
✅ MongoDB connected
✅ Database indexes created
🚀 Server running on port 5000
```

### 5.3 Get Your Backend URL
Once deployed, Render assigns you a URL like:
```
https://task-manager-backend-xxx.onrender.com
```

**Save this URL** - you need it to update the Flutter app.

---

## Step 6: Test Deployment

### 6.1 Test Health Endpoint
```bash
curl https://task-manager-backend-xxx.onrender.com/health
```

Expected response:
```json
{
  "status": "ok",
  "version": "1.3.0",
  "uptime": 123
}
```

### 6.2 Test API
```bash
# Get app version
curl https://task-manager-backend-xxx.onrender.com/api/v1/app/version

# Try login (should fail with 401 - expected)
curl -X POST https://task-manager-backend-xxx.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test"}'
```

---

## Step 7: Update Frontend

### 7.1 Update Flutter `.env`
Edit `frontend/.env`:

```env
BACKEND_URL=https://task-manager-backend-xxx.onrender.com
```

Replace `xxx` with your actual Render service name.

### 7.2 Rebuild APK
```bash
cd frontend
flutter build apk --release
```

The APK will now point to your Render backend instead of localhost.

---

## Step 8: Test End-to-End

### 8.1 Create Test Admin Account
```bash
# Using your backend's script (run locally first, then test against Render)
cd backend
node scripts/create-test-users.js

# Or via API:
curl -X POST https://task-manager-backend-xxx.onrender.com/api/v1/auth/users \
  -H "Content-Type: application/json" \
  -d '{
    "email":"admin@test.com",
    "password":"Test@123",
    "name":"Test Admin",
    "role":"admin"
  }'
```

### 8.2 Test Full Submission Flow
1. Install updated APK on device
2. Login as admin
3. Create a task
4. Assign to a member
5. Login as member (same device or different)
6. Submit work with photos
7. **Verify**:
   - ✅ Task status changes to "submitted"
   - ✅ Admin receives notification
   - ✅ Admin can approve/reject
   - ✅ Files stored in S3

---

## Troubleshooting

### Issue: "Cannot connect to MongoDB"
**Error in logs**: `MongoServerSelectionError`

**Solution**:
1. Check connection string is correct (username, password, cluster)
2. Verify MongoDB Atlas Network Access includes 0.0.0.0/0
3. Verify MONGODB_URI in Render environment variables

### Issue: "Firebase initialization failed"
**Error in logs**: `Firebase admin failed to initialize`

**Solution**:
1. Check FIREBASE_SERVICE_ACCOUNT is properly formatted (single line)
2. Verify the JSON is valid (use https://jsonlint.com)
3. Ensure all quotes are properly escaped

### Issue: "Render keeps spinning down"
**Cause**: Free tier spins down after 15 minutes inactivity

**Solution**:
1. Upgrade to Starter plan ($7/month) for always-on
2. Or keep app active by pinging it periodically

### Issue: "Images not uploading to S3"
**Error in logs**: `AWS S3 error`

**Solution**:
1. Verify AWS credentials are correct
2. Verify bucket name is correct
3. Verify AWS_REGION matches bucket region
4. Check S3 bucket policy allows uploads from your service

### Issue: "Notifications not working"
**Cause**: FCM tokens not registered

**Solution**:
1. Check admin is logged in on device receiving notifications
2. Verify Firebase is initialized (check logs)
3. Verify FCM token was registered: Check MongoDB for user.fcmToken field

---

## Auto-Deploy with GitHub

Once set up, Render automatically redeploys when you push to GitHub:

```bash
git add .
git commit -m "Fix: Update submission sync"
git push origin feat/bulk-user-import
```

Render will:
1. Detect the push
2. Pull latest code
3. Run `npm install`
4. Run `node server.js`
5. Deploy live (2-3 minutes)

---

## Production Checklist

Before going live:

- [ ] MongoDB Atlas credentials are secure
- [ ] Firebase service account is not committed to GitHub
- [ ] JWT_SECRET is a strong random value
- [ ] AWS credentials are from IAM user (not root)
- [ ] S3 bucket has proper CORS and permissions
- [ ] Backend URL is updated in Flutter app
- [ ] Tested full submission flow (submit → admin notified → approve)
- [ ] Tested file uploads work (photos saved to S3)
- [ ] Tested on multiple devices and networks
- [ ] Render logs show no errors on startup

---

## Monitoring & Maintenance

### View Logs
```bash
# In Render Dashboard:
# Click "task-manager-backend" → Logs tab
# Real-time logs appear here
```

### Manual Redeploy
```bash
# In Render Dashboard:
# Click "task-manager-backend" → "Manual Deploy" button
```

### Environment Variable Updates
1. Click "task-manager-backend"
2. Go to "Environment" tab
3. Edit variable
4. Save (auto-redeploys)

---

## Your Render Service URL Format

Once deployed, your URLs will be:
```
Health Check:  https://task-manager-backend-xxx.onrender.com/health
API Base:      https://task-manager-backend-xxx.onrender.com/api/v1
Login:         POST https://task-manager-backend-xxx.onrender.com/api/v1/auth/login
```

Replace `xxx` with your actual service name (chosen in Step 3.2).

---

## Next Steps

1. ✅ Complete Steps 1-5 above
2. ✅ Test with curl commands in Step 6
3. ✅ Update Flutter app in Step 7
4. ✅ Rebuild APK and test on devices
5. ✅ Monitor logs for any issues

**Questions?** Check Render's docs: https://render.com/docs
