# Deployment Checklist - Phase 2

## Pre-Deployment (48 hours before)

### Code Review
- [ ] All PRs merged to main/develop
- [ ] No console.logs in production code
- [ ] No hardcoded credentials
- [ ] All tests passing
- [ ] Linting clean (`npm run lint`, `flutter analyze`)

### Database
- [ ] Backup current production database
- [ ] Test restore from backup
- [ ] Indexes verified: `db.tasks_ith.getIndexes()`
- [ ] No pending migrations

### Environment
- [ ] `.env` configured for staging
- [ ] AWS S3 credentials valid
- [ ] Firebase FCM keys valid
- [ ] JWT secret secure (32+ chars)
- [ ] MONGO_URI correct

### Infrastructure
- [ ] Staging servers available
- [ ] CDN cache cleared
- [ ] DNS configured for staging
- [ ] SSL certificates valid

---

## Staging Deployment (Day 1)

### 1. Backend Deploy
```bash
# 1. Pull latest code
git pull origin main

# 2. Install deps
npm install

# 3. Run migrations (if any)
npm run migrate

# 4. Build (if applicable)
npm run build

# 5. Start with PM2
npm run pm2:start

# 6. Verify health
curl http://localhost:5000/health

# 7. Check logs
npm run pm2:logs
```

### 2. Frontend Build
```bash
# 1. Flutter clean
flutter clean

# 2. Get deps
flutter pub get

# 3. Build APK/IPA
flutter build apk --release
# OR
flutter build ios --release

# 4. Upload to staging store (TestFlight/Google Play internal)
```

### 3. Smoke Tests (Manual)
- [ ] Login works
- [ ] Admin sees team members
- [ ] Member can create submission
- [ ] Rejection & resubmission flow works
- [ ] File viewing works
- [ ] Offline mode queues actions
- [ ] Messages sync in real-time

### 4. Performance Check
- [ ] Response times < 500ms
- [ ] No memory leaks (monitor 1 hour)
- [ ] Database queries optimized
- [ ] Socket.IO stable (50+ concurrent)

### 5. Security Check
```bash
# Check for exposed secrets
npm install -g snyk
snyk test

# Verify org isolation
curl -H "org: A" /api/v1/tasks  # Should only see org A tasks
curl -H "org: B" /api/v1/tasks  # Should only see org B tasks
```

### 6. Logs & Monitoring
- [ ] No ERROR level logs
- [ ] Security logs clean
- [ ] Request IDs present in all logs
- [ ] Monitoring dashboard active

---

## Staging Testing (Day 2)

### QA Test Cycle
- [ ] Run all test cases from PHASE_2_TEST_CASES.md
- [ ] Document any failures
- [ ] Fix critical issues only
- [ ] Re-test fixes

### User Acceptance Testing
- [ ] 2-3 real team members test
- [ ] Document feedback
- [ ] Fix UI/UX issues
- [ ] Verify bug fixes resolved

### Load Testing (Optional)
```bash
# Simulate 100 concurrent users
artillery quick --count 100 --num 10 http://staging.app/api/v1/tasks

# Check:
# - No 5xx errors
# - Response times stable
# - Database handles load
```

### Rollback Verification
- [ ] Tested rollback procedure
- [ ] Previous version deployable
- [ ] Database rollback safe
- [ ] Data not lost during rollback

---

## Production Deployment (Day 3)

### Pre-Deployment (1 hour before)
- [ ] Final code review
- [ ] Database backup taken
- [ ] Team notified of deployment window
- [ ] On-call team briefed
- [ ] Rollback plan ready

### Deployment Steps
```bash
# 1. Stop current service
npm run pm2:stop

# 2. Pull latest code
git pull origin main

# 3. Install deps (if needed)
npm install --production

# 4. Update environment
# Update .env with production values
# Verify sensitive data NOT in code

# 5. Run database migrations (if any)
npm run migrate:prod

# 6. Start service
npm run pm2:start

# 7. Verify health
curl https://api.taskmanager.com/health

# 8. Check logs
npm run pm2:logs | tail -20
```

### Post-Deployment (30 minutes)
- [ ] Health check passes
- [ ] No ERROR logs
- [ ] All critical endpoints responding
- [ ] User can login
- [ ] Real-time events working
- [ ] File uploads to S3 working

### Monitoring (First 24 hours)
- [ ] Response times normal
- [ ] Error rate < 0.1%
- [ ] Database queries normal
- [ ] Memory stable
- [ ] No user complaints
- [ ] Security logs clean

---

## Rollback Plan

If production deployment fails:

### Immediate Actions (< 5 min)
1. Stop current service: `npm run pm2:stop`
2. Checkout previous version: `git checkout <previous-tag>`
3. Start previous version: `npm run pm2:start`
4. Verify health: `curl /health`
5. Notify team

### Database Rollback (if needed)
```bash
# Restore from backup
mongorestore --uri "mongodb://..." backup/

# Verify data
db.tasks_ith.count()
```

### User Communication
- Post status update
- Apologize for interruption
- ETA for fix
- Offer support

---

## Post-Deployment (48 hours)

### Verification
- [ ] All workflows tested
- [ ] No critical bugs reported
- [ ] Performance metrics normal
- [ ] Security audit clean

### Documentation
- [ ] Update deployment docs
- [ ] Record lessons learned
- [ ] Update runbooks
- [ ] Archive logs

### Team Debrief
- [ ] What went well?
- [ ] What could improve?
- [ ] Action items for next deployment
- [ ] Update playbooks

---

## Contacts & Escalation

| Role | Name | Phone | Slack |
|------|------|-------|-------|
| Dev Lead | [Name] | [Phone] | @dev-lead |
| DevOps | [Name] | [Phone] | @devops |
| QA Lead | [Name] | [Phone] | @qa-lead |
| Product | [Name] | [Phone] | @product |

---

## Emergency Procedures

### If users cannot login
1. Check JWT_SECRET in .env
2. Verify auth service running: `npm run pm2:status`
3. Check database connection
4. If unsure, rollback

### If file uploads fail
1. Check AWS S3 credentials
2. Verify S3 bucket permissions
3. Check network connectivity
4. If unsure, disable feature + rollback

### If real-time messages not working
1. Check Socket.IO namespace
2. Verify org validation not too strict
3. Check WebSocket port open (usually 5000)
4. If unsure, restart Socket.IO service

### If database slow/down
1. Check indexes: `db.tasks_ith.getIndexes()`
2. Monitor connections: `db.serverStatus().connections`
3. If overloaded, enable read replicas
4. Consider scaling up instance

---

## Success Criteria

Deployment is successful when ALL are true:
✅ No ERROR logs in first 24 hours
✅ Response times < 500ms average
✅ Zero security incidents
✅ All critical workflows functional
✅ 99%+ uptime
✅ Team agrees "ready for use"

---

**Deployment Owner:** [Name]  
**Deployment Date:** [Date]  
**Deployment Time:** [Start - End]  
**Status:** [ ] Scheduled [ ] In Progress [ ] Complete [ ] Rolled Back
