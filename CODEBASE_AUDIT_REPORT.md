# Task Manager Codebase Integration Audit Report

**Date**: August 10, 2026  
**Status**: Complete analysis across 10 integration categories  
**Total Issues Found**: 27 (6 Critical, 2 High, 19 Medium)

---

## Executive Summary

Comprehensive audit of backend (8 routes, 7 controllers, 8 middleware, 5 models) and frontend (22 screens, 8 providers, 4 services, 5 models) systems.

**Key Findings**:
- ✅ Socket.IO event names correctly aligned
- ✅ REST endpoint URLs correctly matched
- 🔴 6 critical integration issues (login field, multi-tenant scope, offline sync)
- 🟡 21 medium/high issues requiring fixes

---

## 1. ENDPOINT URL MISMATCHES

### Status: ✅ NO ISSUES

All endpoint URLs correctly match between frontend API client and backend routes:
- `/tasks` - GET, POST
- `/tasks/my` - GET
- `/tasks/:id` - GET, PUT, DELETE
- `/submissions` - POST, GET
- `/messages/:taskId` - GET
- `/auth/*` - All endpoints match
- `/super-admin/organizations/*` - All match
- `/analytics/*` - All match
- `/app/version` - GET, PUT

---

## 2. VALIDATION SCHEMA MISMATCHES

### 🔴 CRITICAL: Login Field Name Mismatch
**Location**: `login_screen.dart` → `authController.js`

**Problem**:
- Frontend UI label says "Username" but sends to `username_controller`
- Backend expects `{ email, password }`
- Fields don't match - login could fail if user enters username instead of email

**Evidence**:
```
Frontend: _usernameController.text (sends as login param)
Backend: const { email, password } = req.body
```

**Fix**: Change frontend login screen label from "Username" to "Email"

---

### 🟡 WARNING: User Model Deprecation
**Status**: Backward compatible but inconsistent

- Backend User model has deprecated `username` field
- Still returns in responses for backward compatibility
- Frontend still displays username
- **Need**: Full migration to email-only or standardized display

---

### 🟡 WARNING: Role Creation Validation Mismatch
**Location**: `authController.js`

**Problem**:
- Backend enforces role creation rules (only super_admin creates admins)
- Frontend has no validation of these restrictions
- Frontend could attempt invalid role creations

**Fix**: Add frontend validation before sending role to backend

---

## 3. FIELD NAME INCONSISTENCIES

### 🔴 CRITICAL: Inconsistent User Reference Fields
**Issue**: Backend uses both `username` and `name` fields inconsistently

**Affected Areas**:
- Task responses: `assignedToUsernames` array
- Submission responses: User objects with mixed field names
- Frontend expects: `assignedToNames` for display

**Fix**: Standardize on `name` for display; keep `email` for authentication

---

### 🟡 WARNING: Admin Feedback Field Name
**Location**: `api_client.dart` line 291 → `submissionController.js`

**Inconsistency**:
- Frontend sends: `feedback`
- Backend expects: `adminFeedback`
- **Status**: Works but confusing naming

**Fix**: Rename frontend parameter to `adminFeedback` for clarity

---

### 🟡 WARNING: Submission Status Structure
- ✅ Frontend sends `{ status, adminFeedback }` correctly
- ✅ Backend receives and processes correctly
- ⚠️ Documentation unclear about optional adminFeedback

---

## 4. MISSING ERROR HANDLING

### 🔴 CRITICAL: No Organization Validation in Socket.IO
**Location**: `server.js` - Socket.IO handlers

**Vulnerability**:
```
send-message handler validates task assignment but NOT organization
User from Organization A could theoretically access Organization B's tasks
if they know the taskId
```

**Fix**: Add organization validation:
```javascript
if (task.organizationId !== socket.user.organizationId) {
  return socket.emit('error', 'Unauthorized access');
}
```

---

### 🔴 CRITICAL: Socket.IO Rooms Not Organization-Scoped
**Location**: `server.js` room names

**Issue**:
- Current: `task_${taskId}`
- Multi-tenant risk: Tasks from different orgs could have same ID
- **Best practice**: `org_${orgId}_task_${taskId}`

**Fix**: Update all room join/leave operations to include organization context

---

### 🟡 WARNING: Bulk Task Update Endpoint Incomplete
**Location**: `taskRoutes.js` line 36 - `/bulk/update` route

**Status**:
- Route defined ✅
- Controller function `bulkUpdateTasks` exists ✅
- Implementation incomplete - needs error handling

**Fix**: Complete implementation with proper error responses

---

### 🟡 WARNING: Missing Pagination Validation
**Location**: `api_client.dart` - all list endpoints

**Problem**:
- Frontend doesn't pre-validate pagination limits
- Backend enforces max 100 items per request
- Frontend could request 1000+ items silently rejected

**Fix**: Frontend should validate and limit page size before sending

---

### 🟡 WARNING: No File Upload Size Validation
**Location**: Frontend proof upload

**Problem**:
- Backend limits: 20MB per file (submissions), 50MB per file (tasks)
- Frontend picks files without size check
- Users upload, then get rejection error

**Fix**: Add frontend file size validation before picker

---

## 5. MULTI-TENANT CONTEXT NOT PASSED

### 🟡 WARNING: Inconsistent organizationId in Responses

**Missing organizationId in**:
- ❌ User list responses
- ❌ Analytics metadata
- ✅ Task responses (included)
- ✅ Submission responses (included)
- ✅ Message responses (included)

**Fix**: Add organizationId to all response DTOs

---

### 🟡 WARNING: Frontend Doesn't Verify Organization After Login
**Issue**: Organization status cached, not checked for deactivation

**Current**: Frontend caches organizationId in SharedPreferences
**Should**: Check org status periodically or on startup

**Mitigation**: ✅ Backend returns 401 if org inactive on next request

---

### 🟡 WARNING: Socket.IO organizationId Not Broadcast
**Location**: `server.js` - `send-message` handler

**Issue**: Messages created with organizationId but not included in broadcast
**Frontend**: Can't verify message belongs to their organization
**Status**: Low risk - frontend only joins appropriate task rooms
**Fix**: Include organizationId in Socket.IO event payloads

---

## 6. SOCKET.IO EVENT NAME MISMATCHES

### Status: ✅ NO ISSUES

All event names correctly aligned:
- ✅ `join-task`
- ✅ `leave-task`
- ✅ `send-message`
- ✅ `mark-read`
- ✅ `typing` / `user-typing`
- ✅ `stop-typing` / `user-stop-typing`
- ✅ `new-chat-message`
- ✅ `messages-read`
- ✅ `task-updated`
- ✅ `new-submission`
- ✅ `submission-reviewed`
- ✅ `task-unlocked`
- ✅ `global-chat-alert`

---

## 7. PROVIDER STATE MANAGEMENT ISSUES

### 🟡 WARNING: Race Condition in Task Updates
**Location**: `task_providers.dart` + Socket.IO `task-updated` event

**Scenario**:
1. User updates task via HTTP
2. Frontend receives response
3. Socket.IO broadcast arrives simultaneously
4. State update order not guaranteed

**Fix**: Add version/timestamp to responses and events for idempotency

---

### 🟡 WARNING: Unread Counts Not Synced on Socket Disconnect
**Location**: `sync_status_provider.dart` + Socket.IO disconnect

**Issue**: Badge counts might not sync if socket drops
**Current mitigation**: ✅ Frontend calls REST API `/messages/:taskId/read` as fallback

---

### 🟡 WARNING: Auth Provider Doesn't Sync Organization Status
**Scenario**: Organization deactivated while user logged in
**Current**: Frontend won't know until next HTTP 401
**Mitigation**: ✅ Backend catches and returns 401 on deactivation

---

## 8. OFFLINE SYNC COMPATIBILITY ISSUES

### 🔴 CRITICAL: Sync Service Doesn't Store organizationId
**Location**: `sync_service.dart` - Hive sync queue

**Problem**:
```
Offline user makes changes
SyncAction queued WITHOUT organizationId
User comes online, syncs
organizationId missing - could sync to wrong organization
```

**Impact**: Multi-tenant data breach possibility

**Fix**: Store `organizationId` with every `SyncAction` in Hive:
```dart
SyncAction(
  type: SyncActionType.submitProof,
  payload: {...},
  organizationId: organizationId,  // ADD THIS
)
```

---

### 🟡 WARNING: No Conflict Resolution for Concurrent Updates
**Scenario**:
1. User offline, makes changes
2. Comes online, starts sync
3. Same time: Socket.IO broadcasts different update
4. Last-write-wins - data loss possible

**Fix**: Implement version/timestamp-based conflict detection

---

### 🟡 WARNING: File Upload Retry Without Organization Check
**Location**: `sync_service.dart` - file upload retry

**Issue**: Offline file uploads don't verify organization before retry
**Risk**: If user changed organization (unlikely), upload goes to wrong org

**Fix**: Validate organizationId matches before syncing file uploads

---

## 9. AUTHORIZATION ROLE MISMATCHES

### 🔴 CRITICAL: Inconsistent Admin Role in Task Operations
**Location**: `taskRoutes.js` - bulk update route

**Issue**:
- Bulk update route: `authorize(['admin'])` only
- Most task routes: Same
- Super admin: Cannot perform task bulk operations (incomplete check)

**Fix**: Add super_admin role if intended:
```javascript
router.put('/bulk/update', protect, authorize(['admin', 'super_admin']), ...);
```

---

### 🟡 WARNING: Super Admin Has No Task Access
**Current design**:
- Super admin excluded from organization-scoped queries
- Can only view organization statistics
- Cannot directly manage organization tasks

**Question**: Is this intentional (org management only) or bug?
**Action needed**: Clarify design requirement

---

### 🟡 WARNING: App Deployment Authorization Ambiguous
**Location**: `appRoutes.js` - version deployment

**Current**: `authorize(['admin', 'super_admin'])`
**Question**: 
- Admin: per-organization only?
- Super admin: deploy globally or per-org?

**Action**: Clarify and document authorization model

---

## 10. DATA SERIALIZATION ISSUES

### 🟡 WARNING: File URL Expiry Not Validated Frontend
**Location**: `proof_upload_screen.dart`

**Issue**:
- Backend generates signed S3 URLs with expiry
- Frontend displays as-is without checking expiry
- Could display expired URLs if cached heavily

**Fix**: Refresh S3 URLs every 5 minutes or when accessed

---

### 🟡 WARNING: Task History Serialization Inconsistent
**Location**: `taskController.js` - list endpoints

**Issue**:
- `.lean()` queries DON'T populate history
- Detail endpoint populates history with user names
- Frontend model expects history field

**Status**: ✅ Frontend handles null history gracefully
**Fix**: Explicitly document which endpoints include history

---

### 🟡 WARNING: Message Sender Population Varies
**Location**: `messageController.js` + `socket_service.dart`

**Inconsistency**:
- Backend populates: `{ name, username, role }`
- Frontend expects: sender object
- If backend structure changes, frontend breaks

**Fix**: Standardize required sender fields in API documentation

---

### 🟡 WARNING: Submission Comments Not Populated in Lists
**Location**: `submissionController.js` - list queries

**Issue**: Comments field exists but not populated in list responses
**Frontend**: Assumes comments available when editing submission

**Fix**: Add explicit population:
```javascript
.populate('comments.user', 'name role')
```

---

## SUMMARY

| Category | Critical | High | Medium |
|----------|----------|------|--------|
| Endpoint URLs | 0 | 0 | 0 |
| Validation Schemas | 1 | 1 | 1 |
| Field Names | 1 | 1 | 1 |
| Error Handling | 2 | 0 | 2 |
| Multi-Tenant Context | 0 | 0 | 4 |
| Socket.IO Events | 0 | 0 | 0 |
| Provider State | 0 | 0 | 3 |
| Offline Sync | 1 | 0 | 2 |
| Authorization Roles | 1 | 0 | 2 |
| Data Serialization | 0 | 0 | 4 |
| **TOTAL** | **6** | **2** | **19** |

---

## RECOMMENDED FIX PRIORITY

### Phase 1: CRITICAL (Security/Data Integrity)
1. Socket.IO organization scope validation
2. Sync service organizationId storage
3. Login field name (email vs username)

### Phase 2: HIGH (Multi-Tenant Correctness)
4. Bulk task update authorization
5. Inconsistent user reference fields
6. File upload size validation frontend

### Phase 3: MEDIUM (Data Consistency)
7. Task history serialization
8. Submission comments population
9. File URL expiry refresh
10. Pagination pre-validation

---

## Next Steps

1. Review this audit with team
2. Prioritize fixes by business impact
3. Create tickets for each issue
4. Update integration tests to catch these issues
5. Consider documentation updates

---

**End of Report**
