# Tasks: Bulk User Import via Excel

## Overview

This document contains implementation tasks for the bulk user import feature. Tasks are organized by component/layer, with clear dependencies and verification steps. All 22 correctness properties from the design document are covered by at least one task's verification step.

**Total Estimated Effort:** 65-75 story points  
**Recommended Sprint Structure:** 2 sprints (3-4 weeks)  
**Team Size:** 2-3 developers (1 backend lead, 1 backend specialist, 1 QA)

---

## Task Dependency Graph

```
Phase 1: Infrastructure
├─ 1.1: Install dependencies (xlsx, csv-parse)
└─ 1.2: Create bulkImportService.js skeleton

Phase 2: Core Service Functions (6 tasks)
├─ 2.1: File parsing (Excel/CSV)
├─ 2.2: File format validation
├─ 2.3: Row data validation
├─ 2.4: Duplicate detection (org-scoped)
├─ 2.5: Member limit checking
└─ 2.6: Import report generation

Phase 3: Model Updates (3 tasks)
├─ 3.1: Add requiresPasswordReset field
├─ 3.2: Verify User pre-save hook
└─ 3.3: Verify Organization model

Phase 4: Controller & Routes (3 tasks)
├─ 4.1: Implement bulkImportUsers controller
├─ 4.2: Add bulk-import route
└─ 4.3: Configure multer middleware

Phase 5: Auth & Logging (4 tasks)
├─ 5.1: Verify JWT protect middleware
├─ 5.2: Verify admin authorization
├─ 6.1: Implement audit logging
└─ 6.2: Verify winston integration

Phase 6: Endpoint Updates (4 tasks)
├─ 7.1: Update login response for passwordResetRequired
├─ 7.2: Update password change endpoint
├─ 8.1: Test login with reset flag
└─ 8.2: Test password change clears flag

Phase 7: Testing (17 tasks)
├─ 9.1-9.7: Unit tests (7 tasks)
├─ 10.1-10.10: Integration tests (10 tasks)

Phase 8: Documentation & Verification (3 tasks)
├─ 11.1: Update API documentation
├─ 11.2: Create admin dashboard guide
└─ 11.3: Final property verification
```

---

## Phase 1: Infrastructure & Dependencies

### 1.1: Install Dependencies (Effort: 1 SP)

**Description:** Install Node.js packages for Excel and CSV parsing  
**Dependencies:** None  
**Estimated Effort:** 1 story point

**Acceptance Criteria:**
- [ ] `xlsx` (v0.18.5+) installed and available
- [ ] `csv-parse` (v5.4.1+) installed and available  
- [ ] Both packages listed in `package.json`
- [ ] `npm install` runs without errors
- [ ] Both libraries importable in Node.js

**Implementation:** `npm install xlsx@^0.18.5 csv-parse@^5.4.1`

**Verification:**
1. Check package.json has both dependencies
2. Run `npm install` without errors
3. Test import: `node -e "require('xlsx'); require('csv-parse');"`

**Validates Properties:** Infrastructure only

---

### 1.2: Create bulkImportService.js Skeleton (Effort: 2 SP)

**Description:** Create service file with function stubs  
**Dependencies:** 1.1  
**Estimated Effort:** 2 story points

**Acceptance Criteria:**
- [ ] File created at `backend/services/bulkImportService.js`
- [ ] All 9 required functions stubbed with JSDoc
- [ ] Exports all functions for controller use
- [ ] Follows existing service patterns
- [ ] Includes error handling infrastructure

**Required Functions:**
```
parseExcelFile(filePath)
parseCsvFile(filePath)
validateFileFormat(rows)
validateRowData(rows)
checkDuplicatesInOrganization(emails, organizationId)
detectInFileDuplicates(rows)
checkMemberLimit(organizationId, rowCount)
createBulkUsers(rows, organizationId, hashedPassword)
generateImportReport(successfulUsers, failedRows, batchId)
```

**Verification:**
1. File exists and is importable
2. All stubs export correctly
3. Can import in controller

---

## Phase 2: Core Service Functions

### 2.1: Implement File Parsing Functions (Effort: 4 SP)

**Description:** Implement `parseExcelFile()` and `parseCsvFile()`  
**Dependencies:** 1.2, 1.1  
**Estimated Effort:** 4 story points

**Acceptance Criteria:**
- [ ] parseExcelFile() returns array of { name, email, rowNumber }
- [ ] parseCsvFile() returns array of { name, email, rowNumber }
- [ ] Both skip header row
- [ ] Corrupted files raise descriptive errors
- [ ] Empty files return empty array
- [ ] Large files (1000+ rows) parse in < 2 seconds

**Implementation Guidance:**
- Use XLSX.readFile() for Excel parsing
- Use csv-parse stream for CSV parsing
- Map rowNumber starting from 2 (header is row 1)
- Handle both stream and file-based errors

**Verification:**
1. Parse valid Excel file → correct format
2. Parse valid CSV file → correct format
3. Empty file (header only) → []
4. Corrupted file → throws error
5. Large file (1000 rows) → < 2 seconds

**Validates Properties:** Property 1 (File Format Validation - parsing step)

---

### 2.2: Implement File Format Validation (Effort: 3 SP)

**Description:** Implement `validateFileFormat()` function  
**Dependencies:** 2.1  
**Estimated Effort:** 3 story points

**Acceptance Criteria:**
- [ ] Validates exactly 2 columns exist
- [ ] Validates headers are "Name" and "Email" (case-insensitive)
- [ ] Returns { valid: true } or { valid: false, error: string }
- [ ] Skips header row correctly
- [ ] Provides specific error messages

**Verification:**
1. 2 correct columns → { valid: true }
2. 3 columns → { valid: false, fileFormat: "..." }
3. Wrong headers → { valid: false, headers: "..." }
4. Case variations (name, EMAIL) → { valid: true }

**Validates Properties:** Property 1 (File Format Validation)

---

### 2.3: Implement Row Data Validation (Effort: 4 SP)

**Description:** Implement `validateRowData()` function  
**Dependencies:** 2.2  
**Estimated Effort:** 4 story points

**Acceptance Criteria:**
- [ ] Validates name: non-empty, trim, max 100 chars
- [ ] Validates email: non-empty, trim, RFC 5322 format
- [ ] Normalizes email to lowercase
- [ ] Returns { rowNumber, name, email, valid, errors }
- [ ] Collects all errors per row

**Verification:**
1. Valid row → valid: true, no errors
2. Empty name → valid: false, errors: ["Name field is empty"]
3. Invalid email format → errors: ["Invalid email format"]
4. Email normalized to lowercase
5. Whitespace trimmed
6. Name > 100 chars → errors: ["Name exceeds 100 characters"]

**Validates Properties:** Properties 2, 3, 4

---

### 2.4: Implement Duplicate Detection (Effort: 5 SP)

**Description:** Implement `checkDuplicatesInOrganization()` and `detectInFileDuplicates()`  
**Dependencies:** 2.3  
**Estimated Effort:** 5 story points

**Acceptance Criteria:**
- [ ] checkDuplicatesInOrganization() queries User collection case-insensitive
- [ ] Returns Set of emails that exist in organization
- [ ] detectInFileDuplicates() marks all but first occurrence as duplicate
- [ ] Returns rows with { duplicate, duplicateReason }
- [ ] Email comparison is case-insensitive

**Verification:**
1. Query non-existent emails → empty Set
2. Query existing emails → returns Set with matches
3. File: email at row 1 and 3 → row 3 marked duplicate, row 1 not
4. Email case insensitivity → john@example.com matches JOHN@EXAMPLE.COM
5. Organization scoping → only checks organization's users

**Validates Properties:** Properties 5, 6

---

### 2.5: Implement Member Limit Checking (Effort: 3 SP)

**Description:** Implement `checkMemberLimit()` function  
**Dependencies:** 2.4  
**Estimated Effort:** 3 story points

**Acceptance Criteria:**
- [ ] Queries organization's memberCount and memberLimit
- [ ] Returns available capacity
- [ ] Marks excess rows as failed
- [ ] If no capacity, all rows marked failed
- [ ] Uses atomic MongoDB queries

**Verification:**
1. Capacity 10, members 5, import 3 → all pass
2. Capacity 10, members 9, import 5 → 1 passes, 4 fail
3. At capacity → all rows fail
4. Over capacity → all rows fail

**Validates Properties:** Property 12 (Member Limit Enforcement)

---

### 2.6: Implement Import Report Generation (Effort: 3 SP)

**Description:** Implement `generateImportReport()` function  
**Dependencies:** 2.5  
**Estimated Effort:** 3 story points

**Acceptance Criteria:**
- [ ] Returns { batchId, totalRows, successCount, failedCount, successfulUsers, failedRows }
- [ ] successfulUsers include { id, name, email, role }
- [ ] failedRows include { rowNumber, name, email, error }
- [ ] Includes timestamp and duration
- [ ] JSON serializable

**Verification:**
1. Report with 50 success, 5 failed → counts correct
2. successfulUsers structure valid
3. failedRows structure valid
4. JSON serializable

**Validates Properties:** Property 13 (Import Report Completeness)

---

## Phase 3: Model & Database Updates

### 3.1: Add requiresPasswordReset Field to User Model (Effort: 1 SP)

**Description:** Add boolean field to User schema  
**Dependencies:** None  
**Estimated Effort:** 1 story point

**Acceptance Criteria:**
- [ ] Field added to User.js schema
- [ ] Type is Boolean, defaults to false
- [ ] Field optional for existing users
- [ ] No migration needed for existing data

**Implementation:** Add to User schema:
```javascript
requiresPasswordReset: {
  type: Boolean,
  default: false
}
```

**Verification:**
1. User created without field → defaults to false
2. User created with field true → stored as true
3. Existing users unaffected

**Validates Properties:** Property 10 (User Initialization State)

---

### 3.2: Verify User Model Pre-Save Hook (Effort: 1 SP)

**Description:** Verify pre-save hook hashes passwords correctly  
**Dependencies:** 3.1  
**Estimated Effort:** 1 story point

**Acceptance Criteria:**
- [ ] Pre-save hook exists and uses bcryptjs
- [ ] Hash uses consistent salt rounds (same as single-user creation)
- [ ] Hook checks isModified('password')
- [ ] Bulk import passwords hashed consistently

**Verification:**
1. Review User.js pre-save hook
2. Verify isModified('password') check
3. Verify bcryptjs.hash() with correct salt rounds
4. Test: create bulk import user → password hashed in DB

**Validates Properties:** Property 8 (Password Hashing Consistency)

---

### 3.3: Verify Organization Model Fields (Effort: 1 SP)

**Description:** Confirm Organization model has required fields  
**Dependencies:** None  
**Estimated Effort:** 1 story point

**Acceptance Criteria:**
- [ ] Organization model has memberCount field (numeric)
- [ ] Organization model has memberLimit field (numeric)
- [ ] Both fields initialized with valid defaults
- [ ] memberCount can be incremented atomically

**Verification:**
1. Review Organization.js schema
2. Verify memberCount is Number type
3. Verify memberLimit is Number type
4. Test atomic increment: findByIdAndUpdate with $inc

**Validates Properties:** Property 11 (Atomic Member Count Increment)

---

## Phase 4: Controller & Route Implementation

### 4.1: Implement bulkImportUsers Controller Function (Effort: 8 SP)

**Description:** Implement main bulk import handler in authController.js  
**Dependencies:** 2.6, 3.1, 3.3  
**Estimated Effort:** 8 story points

**Acceptance Criteria:**
- [ ] Validates request (file, password, auth, org)
- [ ] Orchestrates all validation stages sequentially
- [ ] Handles file parsing with error handling
- [ ] Performs batch user creation
- [ ] Atomically increments organization memberCount
- [ ] Generates correct HTTP status (201, 207, 400, 500)
- [ ] Returns formatted response with import report
- [ ] Cleans up temporary files
- [ ] Logs all events via audit logging

**Implementation Flow:**
1. Validate file and password exist
2. Validate password strength (min 6 chars)
3. Parse file (Excel or CSV)
4. Validate file format (2 columns, headers)
5. Validate each row (name, email, format, trim)
6. Detect in-file duplicates
7. Check organization duplicates (case-insensitive)
8. Check member limit
9. Hash password with bcryptjs
10. Batch create valid users with User.insertMany()
11. Atomically increment memberCount
12. Generate import report
13. Determine status code (201/207/400)
14. Log audit events
15. Clean up temp file
16. Return response

**Verification:**
1. Valid file → 201, all users created
2. Mixed valid/invalid rows → 207 with breakdown
3. All invalid rows → 400
4. Temp file deleted after processing
5. Correct HTTP status codes

**Validates Properties:** Properties 7, 9, 10, 14

---

### 4.2: Add Bulk Import Route to authRoutes.js (Effort: 2 SP)

**Description:** Add POST /api/v1/auth/bulk-import route  
**Dependencies:** 4.1  
**Estimated Effort:** 2 story points

**Acceptance Criteria:**
- [ ] Route defined at `/bulk-import` with POST
- [ ] Protected with JWT auth middleware
- [ ] Authorized for admin role only
- [ ] Uses file upload middleware
- [ ] Calls bulkImportUsers controller
- [ ] Rate limiting applied

**Implementation:**
```javascript
router.post(
  '/bulk-import',
  protect,
  authorize(['admin']),
  createUserLimiter,
  upload.single('file'),
  bulkImportUsers
);
```

**Verification:**
1. Route accessible at POST /api/v1/auth/bulk-import
2. Without JWT → 401 Unauthorized
3. Non-admin user → 403 Forbidden
4. Admin JWT → request reaches controller

**Validates Properties:** Property 18 (Endpoint Availability)

---

### 4.3: Configure Multer for File Upload (Effort: 2 SP)

**Description:** Configure multer middleware for file handling  
**Dependencies:** 4.2  
**Estimated Effort:** 2 story points

**Acceptance Criteria:**
- [ ] Multer configured for single file upload
- [ ] Max file size: 2MB
- [ ] Allowed MIME types: .xlsx, .csv
- [ ] File stored in memory
- [ ] File field name: 'file'
- [ ] Error handling for oversized files

**Implementation:**
```javascript
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/csv'
    ];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Unsupported file format'));
    }
  }
});
```

**Verification:**
1. Upload .xlsx file → accepted
2. Upload .csv file → accepted
3. Upload .txt file → rejected
4. Upload > 2MB file → rejected
5. File available in req.file

**Validates Properties:** Property 19 (File Type Validation)

---

## Phase 5: Authentication & Authorization

### 5.1: Verify JWT Protect Middleware (Effort: 1 SP)

**Description:** Verify existing JWT authentication middleware  
**Dependencies:** 4.2  
**Estimated Effort:** 1 story point

**Acceptance Criteria:**
- [ ] Existing protect middleware verifies JWT token
- [ ] Token extracted from Authorization header
- [ ] req.user populated with user data
- [ ] req.user.organizationId available
- [ ] Invalid token returns 401

**Verification:**
1. Review authMiddleware.js protect function
2. Test with valid JWT → req.user populated
3. Test with invalid JWT → 401 error
4. Test req.user has organizationId

**Validates Properties:** Properties 1, 10, 18 (auth layer)

---

### 5.2: Verify Admin Authorization Middleware (Effort: 1 SP)

**Description:** Verify admin role-based authorization  
**Dependencies:** 5.1  
**Estimated Effort:** 1 story point

**Acceptance Criteria:**
- [ ] authorize(['admin']) middleware checks role
- [ ] Only admin users can access bulk-import
- [ ] Non-admin returns 403 Forbidden
- [ ] Super-admin can access (if design allows)

**Verification:**
1. Review roleMiddleware.js authorize function
2. Test admin user → access allowed
3. Test member user → 403 error
4. Test unauthenticated → 401 error

**Validates Properties:** Property 18 (Authorization)

---

## Phase 6: Logging & Audit Trail

### 6.1: Implement Audit Logging for Import Events (Effort: 3 SP)

**Description:** Log all bulk import events via winston  
**Dependencies:** 5.2, 4.1  
**Estimated Effort:** 3 story points

**Acceptance Criteria:**
- [ ] Log import start: admin ID, org ID, file metadata
- [ ] Log each user creation: user ID, email, batch ID
- [ ] Log import completion: success/failure counts, duration
- [ ] Log import failure: reason, partial results
- [ ] Include admin IP address in all logs
- [ ] Use logger.admin() for audit events

**Events to Log:**
1. Import initiated (file name, size, row count)
2. User created (per user in batch)
3. Import completed (total, success, failed, duration)
4. Import failed (error reason)

**Verification:**
1. Review bulkImportUsers controller for logger calls
2. Run import → check logs for all events
3. Verify IP address logged
4. Verify batch ID consistent across events

**Validates Properties:** Property 15 (Audit Log Completeness)

---

### 6.2: Verify Winston Logger Integration (Effort: 1 SP)

**Description:** Verify existing winston logging available  
**Dependencies:** 6.1  
**Estimated Effort:** 1 story point

**Acceptance Criteria:**
- [ ] logger.admin() function available
- [ ] Logs written to daily-rotated files
- [ ] Logs include timestamp, level, context
- [ ] Can import logger in bulkImportUsers

**Verification:**
1. Review utils/logger.js
2. Verify logger.admin() exists
3. Test: logger.admin() call → logged to file

**Validates Properties:** Property 15 (Audit Trail)

---

## Phase 7: Endpoint Updates for Password Reset

### 7.1: Update Login Response for passwordResetRequired (Effort: 2 SP)

**Description:** Update login endpoint to return passwordResetRequired flag  
**Dependencies:** 3.1  
**Estimated Effort:** 2 story points

**Acceptance Criteria:**
- [ ] Login response includes passwordResetRequired field
- [ ] Field set to true if user.requiresPasswordReset === true
- [ ] Field set to false or omitted if false
- [ ] Works with bulk import users
- [ ] Backward compatible with existing login clients

**Implementation:**
In authController login function, add to response:
```javascript
passwordResetRequired: user.requiresPasswordReset || false
```

**Verification:**
1. Login with regular user → passwordResetRequired: false
2. Login with bulk import user → passwordResetRequired: true
3. Existing clients still work

**Validates Properties:** Property 20 (Password Reset Flag on First Login)

---

### 7.2: Update Password Change Endpoint (Effort: 2 SP)

**Description:** Clear requiresPasswordReset flag when user changes password  
**Dependencies:** 7.1  
**Estimated Effort:** 2 story points

**Acceptance Criteria:**
- [ ] Password change endpoint at /api/v1/auth/users/:id/password
- [ ] Sets requiresPasswordReset to false after change
- [ ] Updates user in database
- [ ] Logs password change event
- [ ] Returns success response

**Implementation:**
In password change handler:
```javascript
await User.findByIdAndUpdate(userId, {
  password: hashedPassword,
  requiresPasswordReset: false
});
```

**Verification:**
1. Change password with bulk import user → flag cleared
2. User can login with new password
3. Login response shows passwordResetRequired: false
4. Password change logged

**Validates Properties:** Property 21 (Password Change Clears Reset Flag)

---

### 7.3: Test Login with Reset Flag (Effort: 1 SP)

**Description:** End-to-end test of login with requiresPasswordReset  
**Dependencies:** 7.1  
**Estimated Effort:** 1 story point

**Acceptance Criteria:**
- [ ] Bulk import user can login
- [ ] Response includes passwordResetRequired: true
- [ ] Client can detect flag and redirect to password change
- [ ] All login fields present

**Verification:**
1. Create bulk import user
2. Login with credentials
3. Check response for passwordResetRequired: true
4. Verify all required login fields present

**Validates Properties:** Property 20

---

### 7.4: Test Password Change Clears Flag (Effort: 1 SP)

**Description:** End-to-end test of password change clearing flag  
**Dependencies:** 7.2  
**Estimated Effort:** 1 story point

**Acceptance Criteria:**
- [ ] User with requiresPasswordReset: true changes password
- [ ] POST /api/v1/auth/users/:id/password succeeds
- [ ] requiresPasswordReset set to false
- [ ] Subsequent login shows flag as false
- [ ] New password works for login

**Verification:**
1. Create bulk import user (flag: true)
2. Call password change endpoint
3. Query user → flag is false
4. Login with new password → flag is false

**Validates Properties:** Property 21

---

## Phase 8: Unit Testing

### 9.1: Unit Tests for File Parsing (Effort: 2 SP)

**Description:** Test parseExcelFile() and parseCsvFile() functions  
**Dependencies:** 2.1  
**Estimated Effort:** 2 story points

**Test Cases:**
- [ ] Parse valid Excel file → correct format
- [ ] Parse valid CSV file → correct format
- [ ] Empty file (header only) → returns []
- [ ] Corrupted Excel file → throws error with message
- [ ] Corrupted CSV file → throws error with message
- [ ] Large file (1000 rows) → completes in < 2 seconds
- [ ] File with special characters → parsed correctly
- [ ] File with Unicode → handled correctly

**Test File Locations:**
- `backend/services/__tests__/bulkImportService.test.js`
- Test data files in `backend/services/__tests__/fixtures/`

**Verification:**
1. Run tests with npm test or jest
2. All tests pass
3. Coverage > 90% for parsing functions

**Validates Properties:** Property 1 (File Format Validation - parsing)

---

### 9.2: Unit Tests for File Format Validation (Effort: 2 SP)

**Description:** Test validateFileFormat() function  
**Dependencies:** 2.2  
**Estimated Effort:** 2 story points

**Test Cases:**
- [ ] 2 correct columns → { valid: true }
- [ ] 3 columns → { valid: false, fileFormat: "..." }
- [ ] 1 column → { valid: false, fileFormat: "..." }
- [ ] Wrong headers (Phone, Address) → { valid: false, headers: "..." }
- [ ] Case variations (name, EMAIL) → { valid: true }
- [ ] Headers misspelled (Nam, Emial) → { valid: false, headers: "..." }
- [ ] Empty rows array → { valid: true }

**Verification:**
1. Run unit tests
2. All tests pass
3. Coverage 100% for validateFileFormat

**Validates Properties:** Property 1 (File Format Validation)

---

### 9.3: Unit Tests for Row Data Validation (Effort: 2 SP)

**Description:** Test validateRowData() function  
**Dependencies:** 2.3  
**Estimated Effort:** 2 story points

**Test Cases:**
- [ ] Valid name and email → valid: true
- [ ] Empty name → valid: false, errors: ["Name field is empty"]
- [ ] Whitespace-only name → valid: false
- [ ] Invalid email format → errors: ["Invalid email format"]
- [ ] Empty email → valid: false, errors: ["Email field is empty"]
- [ ] Name with leading/trailing spaces → trimmed
- [ ] Email with spaces → trimmed and lowercase
- [ ] Name > 100 characters → errors: ["Name exceeds 100 characters"]
- [ ] Email > 100 characters → errors: ["Email exceeds 100 characters"]
- [ ] Multiple errors → all collected

**Verification:**
1. Run unit tests
2. All tests pass
3. Coverage 100% for validateRowData

**Validates Properties:** Properties 2, 3, 4

---

### 9.4: Unit Tests for Duplicate Detection (Effort: 3 SP)

**Description:** Test checkDuplicatesInOrganization() and detectInFileDuplicates()  
**Dependencies:** 2.4, integration with mock User model  
**Estimated Effort:** 3 story points

**Test Cases:**
- [ ] Non-existent emails → returns empty Set
- [ ] Existing emails in org → returns Set with matches
- [ ] Case insensitivity → JOHN@EXAMPLE.COM matches john@example.com
- [ ] Different organization → emails not included
- [ ] In-file duplicate at row 1 and 3 → row 3 marked duplicate
- [ ] Multiple in-file duplicates → only first valid
- [ ] All rows duplicates → all but first marked failed
- [ ] No duplicates → all marked valid

**Test Setup:**
- Mock User.find() to return existing users
- Create test data with duplicates

**Verification:**
1. Run unit tests with mocked database
2. All tests pass
3. No database calls in unit tests

**Validates Properties:** Properties 5, 6

---

### 9.5: Unit Tests for Member Limit Checking (Effort: 2 SP)

**Description:** Test checkMemberLimit() function  
**Dependencies:** 2.5, integration with mock Organization model  
**Estimated Effort:** 2 story points

**Test Cases:**
- [ ] Under capacity → all rows valid
- [ ] At capacity → all rows marked failed
- [ ] Over capacity → all rows marked failed
- [ ] Partial capacity → some pass, some fail
- [ ] Exactly filling capacity → all pass
- [ ] Empty capacity → all fail

**Test Data:**
- Organization with capacity 10, various member counts
- Import batches of various sizes

**Verification:**
1. Run unit tests with mocked database
2. All tests pass
3. Row order preserved

**Validates Properties:** Property 12 (Member Limit Enforcement)

---

### 9.6: Unit Tests for Import Report Generation (Effort: 1 SP)

**Description:** Test generateImportReport() function  
**Dependencies:** 2.6  
**Estimated Effort:** 1 story point

**Test Cases:**
- [ ] Report structure complete
- [ ] successfulUsers have required fields (id, name, email, role)
- [ ] failedRows have required fields (rowNumber, name, email, error)
- [ ] Counts accurate
- [ ] JSON serializable
- [ ] Includes batchId, timestamp, duration
- [ ] Empty success list → counts correct
- [ ] Empty failure list → counts correct

**Verification:**
1. Run unit tests
2. All tests pass
3. Report structure validated against schema

**Validates Properties:** Property 13 (Import Report Completeness)

---

### 9.7: Unit Tests for Error Handling (Effort: 2 SP)

**Description:** Test error handling in all service functions  
**Dependencies:** 2.1-2.6  
**Estimated Effort:** 2 story points

**Test Cases:**
- [ ] Corrupted file → throws error with message
- [ ] Invalid password strength → caught and handled
- [ ] Database errors → caught and handled
- [ ] Missing required parameters → caught and handled
- [ ] Invalid input types → caught and handled

**Verification:**
1. Run unit tests
2. Error messages descriptive
3. No unhandled rejections

**Validates Properties:** Error handling across all properties

---

## Phase 9: Integration Testing

### 10.1: End-to-End: Successful Import (Excel) (Effort: 3 SP)

**Description:** Complete flow with valid Excel file  
**Dependencies:** 4.3, 9.1  
**Estimated Effort:** 3 story points

**Test Steps:**
- [ ] Create Excel file with 10 valid users
- [ ] POST /api/v1/auth/bulk-import with file and password
- [ ] Verify HTTP 201 response
- [ ] Verify all 10 users created in database
- [ ] Verify users have correct fields (name, email, role, org, requiresPasswordReset)
- [ ] Verify organization memberCount incremented
- [ ] Verify audit logs recorded
- [ ] Verify response includes all successful users

**Test Data:**
```
Name,Email
John Doe,john@example.com
Jane Smith,jane@example.com
... (8 more)
```

**Verification:**
1. Create test file
2. Call endpoint with admin JWT
3. Assert 201 status
4. Query database → all users exist
5. Check audit logs

**Validates Properties:** Properties 1, 2, 7, 8, 9, 10, 11, 13, 14, 15

---

### 10.2: End-to-End: Successful Import (CSV) (Effort: 2 SP)

**Description:** Complete flow with valid CSV file  
**Dependencies:** 4.3, 9.1  
**Estimated Effort:** 2 story points

**Test Steps:**
- [ ] Create CSV file with 5 valid users
- [ ] POST /api/v1/auth/bulk-import with file and password
- [ ] Verify HTTP 201 response
- [ ] Verify all 5 users created
- [ ] Verify identical behavior to Excel flow

**Test Data:**
```
Name,Email
Alice Brown,alice@example.com
Bob Wilson,bob@example.com
```

**Verification:**
1. Create CSV test file
2. Call endpoint
3. Assert 201 status and users created

**Validates Properties:** Same as 10.1 but with CSV format

---

### 10.3: End-to-End: Partial Import (Mixed Results) (Effort: 3 SP)

**Description:** Import with some valid and some invalid rows  
**Dependencies:** 4.1, 9.2-9.5  
**Estimated Effort:** 3 story points

**Test Steps:**
- [ ] Create file with 10 rows: 7 valid, 3 invalid
- [ ] Include 1 duplicate in org, 1 invalid email, 1 empty name
- [ ] POST /api/v1/auth/bulk-import
- [ ] Verify HTTP 207 response
- [ ] Verify 7 users created
- [ ] Verify failedRows includes all 3 failures with reasons
- [ ] Verify successfulUsers includes all 7 with details
- [ ] Verify memberCount incremented by 7

**Verification:**
1. Create mixed file
2. Call endpoint
3. Assert 207 status
4. Verify counts: successCount 7, failedCount 3
5. Check all failures documented

**Validates Properties:** Properties 1-15

---

### 10.4: End-to-End: File Format Validation Failure (Effort: 2 SP)

**Description:** Reject file with incorrect format  
**Dependencies:** 4.1, 9.2  
**Estimated Effort:** 2 story points

**Test Steps:**
- [ ] Create file with 3 columns (Name, Email, Phone)
- [ ] POST /api/v1/auth/bulk-import
- [ ] Verify HTTP 400 response
- [ ] Verify error message about column count
- [ ] Verify no users created
- [ ] Verify memberCount unchanged
- [ ] Verify file cleaned up

**Verification:**
1. Create invalid file
2. Call endpoint
3. Assert 400 status
4. Check error message
5. Verify no database changes

**Validates Properties:** Properties 1, 22

---

### 10.5: End-to-End: Password Validation Failure (Effort: 1 SP)

**Description:** Reject import with weak password  
**Dependencies:** 4.1  
**Estimated Effort:** 1 story point

**Test Steps:**
- [ ] Create valid file
- [ ] POST /api/v1/auth/bulk-import with password: "123" (too short)
- [ ] Verify HTTP 400 response
- [ ] Verify error about password strength
- [ ] Verify no users created

**Verification:**
1. Call with weak password
2. Assert 400 status
3. Check error message
4. Verify no database changes

**Validates Properties:** Properties 7, 22

---

### 10.6: End-to-End: Member Limit Enforcement (Effort: 2 SP)

**Description:** Test partial rejection due to member limit  
**Dependencies:** 4.1, 9.5  
**Estimated Effort:** 2 SP

**Setup:**
- Organization with memberLimit 12, current members 10
- Create file with 5 users

**Test Steps:**
- [ ] POST /api/v1/auth/bulk-import with 5 users
- [ ] Verify HTTP 207 response
- [ ] Verify 2 users created (fills capacity)
- [ ] Verify 3 users marked failed with limit error
- [ ] Verify memberCount incremented by 2

**Verification:**
1. Setup org at 10/12 capacity
2. Call endpoint
3. Assert 207 status
4. Verify successCount 2, failedCount 3
5. Check failure reasons

**Validates Properties:** Property 12, 22

---

### 10.7: End-to-End: Audit Logging (Effort: 2 SP)

**Description:** Verify all import events logged  
**Dependencies:** 6.1, 10.1  
**Estimated Effort:** 2 story points

**Test Steps:**
- [ ] Execute successful import
- [ ] Check logger for import start event
- [ ] Check logger for user creation events (per user)
- [ ] Check logger for import completion event
- [ ] Verify all logs include admin ID, org ID, IP
- [ ] Verify batchId consistent across events

**Verification:**
1. Run import
2. Query log files for events
3. Verify all required fields present
4. Check batchId linking

**Validates Properties:** Property 15 (Audit Log Completeness)

---

### 10.8: Concurrency Test: Concurrent Imports to Same Organization (Effort: 3 SP)

**Description:** Test atomicity with concurrent bulk imports  
**Dependencies:** 4.1, 11  
**Estimated Effort:** 3 story points

**Setup:**
- Organization with memberLimit 50, current members 40
- Prepare 2 concurrent import requests (10 users each)

**Test Steps:**
- [ ] Execute both imports concurrently
- [ ] Wait for both to complete
- [ ] Verify both 207 responses (partial success)
- [ ] Verify memberCount = 40 + 10 + 10 = 60 (or correctly handles limit)
- [ ] Verify no data inconsistencies
- [ ] Verify no duplicate user creation

**Verification:**
1. Use Promise.all() to send concurrent requests
2. Check final memberCount
3. Verify both imports processed correctly
4. Verify atomic $inc operation prevented race conditions

**Validates Properties:** Property 11, 17 (Concurrent Operation Consistency)

---

### 10.9: Concurrency Test: Single-User and Bulk Import (Effort: 2 SP)

**Description:** Test consistency between single-user and bulk import  
**Dependencies:** 9, 10.1  
**Estimated Effort:** 2 story points

**Test Steps:**
- [ ] Create user via single-user endpoint
- [ ] Create bulk import concurrently with memberLimit 12, current 10
- [ ] Verify single-user created (memberCount = 11)
- [ ] Verify bulk import gets 1 slot, creates 1, fails others
- [ ] Verify final memberCount = 12 (not over limit)
- [ ] Verify no duplicate emails

**Verification:**
1. Execute both endpoints concurrently
2. Check memberCount stays accurate
3. Verify both workflows respected limit

**Validates Properties:** Property 16, 17 (Single-User Endpoint Integrity, Concurrent Operations)

---

### 10.10: Multi-Tenant Isolation Test (Effort: 2 SP)

**Description:** Verify organization scoping is maintained  
**Dependencies:** 4.1, 5.2  
**Estimated Effort:** 2 story points

**Setup:**
- Organization A and Organization B
- Admin from Org A
- Email exists in Org B

**Test Steps:**
- [ ] Org A admin uploads file with email from Org B
- [ ] Verify email is NOT marked duplicate
- [ ] Create user successfully (email unique in Org A)
- [ ] Verify user belongs to Org A only
- [ ] Verify cannot access Org B data

**Verification:**
1. Query duplicate detection for Org A only
2. Verify scoping in all queries
3. Check organization ID in created users

**Validates Properties:** Properties 5, 9, 17 (Multi-Tenant Isolation)

---

## Phase 10: Documentation & Final Verification

### 11.1: Update API Documentation (Effort: 2 SP)

**Description:** Document bulk import endpoint  
**Dependencies:** 4.2  
**Estimated Effort:** 2 story points

**Documentation to Create:**
- [ ] Endpoint: POST /api/v1/auth/bulk-import
- [ ] Request format (multipart/form-data)
- [ ] Parameters: file, password
- [ ] Response: 201, 207, 400, 500 examples
- [ ] Error codes and meanings
- [ ] Authentication: JWT required, admin role
- [ ] Rate limiting: applied
- [ ] Example Excel/CSV files
- [ ] Curl/Postman examples

**Files to Update:**
- `backend/API_TEST_GUIDE.md` or docs folder
- In-code JSDoc for bulkImportUsers

**Verification:**
1. Documentation complete and accurate
2. Examples functional
3. Error cases documented

**Validates Properties:** Documentation only

---

### 11.2: Create Admin Dashboard Integration Guide (Effort: 2 SP)

**Description:** Guide for Flutter frontend UI integration  
**Dependencies:** All backend tasks complete  
**Estimated Effort:** 2 story points

**Guidance to Provide:**
- [ ] File picker integration
- [ ] POST request format
- [ ] Handling 201 response (all success)
- [ ] Handling 207 response (show failed rows)
- [ ] Handling 400 response (validation errors)
- [ ] Progress indication for large files
- [ ] Success/failure notification UI
- [ ] Display import report to admin

**Documentation:**
- Create `docs/BULK_IMPORT_FRONTEND_GUIDE.md`
- Include code snippets for Dio HTTP client
- Show example Flutter widget

**Verification:**
1. Guide complete and clear
2. Examples work with Dio library
3. Frontend developer can implement from guide

**Validates Properties:** Integration guidance

---

### 11.3: Final Property Verification Matrix (Effort: 2 SP)

**Description:** Verify all 22 correctness properties satisfied  
**Dependencies:** All tasks  
**Estimated Effort:** 2 story points

**Properties to Verify (22 total):**
- [ ] Property 1: File Format Validation → Tasks 2.1, 2.2, 9.2, 10.4
- [ ] Property 2: Row Data Validation → Tasks 2.3, 9.3, 10.3
- [ ] Property 3: Email Format Validation → Tasks 2.3, 9.3
- [ ] Property 4: Whitespace Normalization → Tasks 2.3, 9.3
- [ ] Property 5: Organization-Scoped Duplicate → Tasks 2.4, 9.4, 10.10
- [ ] Property 6: In-File Duplicate Handling → Tasks 2.4, 9.4
- [ ] Property 7: Password Strength Enforcement → Tasks 4.1, 10.5
- [ ] Property 8: Password Hashing Consistency → Tasks 3.2, 10.1
- [ ] Property 9: User Role Assignment → Tasks 4.1, 10.1
- [ ] Property 10: User Initialization State → Tasks 3.1, 4.1, 10.1
- [ ] Property 11: Atomic Member Count → Tasks 3.3, 4.1, 10.8
- [ ] Property 12: Member Limit Enforcement → Tasks 2.5, 9.5, 10.6
- [ ] Property 13: Import Report Completeness → Tasks 2.6, 9.6, 10.1
- [ ] Property 14: HTTP Status Code Accuracy → Tasks 4.1, 10.1-10.6
- [ ] Property 15: Audit Log Completeness → Tasks 6.1, 6.2, 10.7
- [ ] Property 16: Single-User Endpoint Integrity → Tasks 5.1, 10.9
- [ ] Property 17: Concurrent Operation Consistency → Tasks 10.8, 10.9
- [ ] Property 18: Endpoint Availability → Tasks 4.2, 4.3, 5.2
- [ ] Property 19: File Type Validation → Tasks 4.3, 10.4
- [ ] Property 20: Password Reset Flag on First Login → Tasks 7.1, 7.3
- [ ] Property 21: Password Change Clears Flag → Tasks 7.2, 7.4
- [ ] Property 22: All-Row Failure Rejection → Tasks 2.2, 10.4

**Verification Process:**
1. For each property, run associated test tasks
2. Document test results
3. Create property verification report
4. Sign-off on all 22 properties

**Output:**
- Create `docs/PROPERTY_VERIFICATION_REPORT.md`
- Checklist of all 22 properties
- Test results per property
- Coverage matrix

---

## Task Summary by Category

### Service Layer Tasks (6 tasks, 22 SP)
- 2.1: File Parsing (4 SP)
- 2.2: File Format Validation (3 SP)
- 2.3: Row Data Validation (4 SP)
- 2.4: Duplicate Detection (5 SP)
- 2.5: Member Limit Checking (3 SP)
- 2.6: Import Report Generation (3 SP)

### Model & Database Tasks (3 tasks, 3 SP)
- 3.1: Add requiresPasswordReset field (1 SP)
- 3.2: Verify pre-save hook (1 SP)
- 3.3: Verify Organization model (1 SP)

### Controller & Routing Tasks (3 tasks, 12 SP)
- 4.1: Bulk import controller (8 SP)
- 4.2: Add route (2 SP)
- 4.3: Multer configuration (2 SP)

### Authentication & Authorization Tasks (2 tasks, 2 SP)
- 5.1: JWT verify (1 SP)
- 5.2: Admin authorization (1 SP)

### Logging Tasks (2 tasks, 4 SP)
- 6.1: Audit logging implementation (3 SP)
- 6.2: Winston verification (1 SP)

### Endpoint Update Tasks (4 tasks, 6 SP)
- 7.1: Login response update (2 SP)
- 7.2: Password change update (2 SP)
- 7.3: Login with flag test (1 SP)
- 7.4: Password change flag test (1 SP)

### Testing Tasks (17 tasks, 25 SP)
- Phase 8 Unit Tests (9.1-9.7): 14 SP
- Phase 9 Integration Tests (10.1-10.10): 21 SP

### Documentation Tasks (3 tasks, 6 SP)
- 11.1: API documentation (2 SP)
- 11.2: Frontend integration guide (2 SP)
- 11.3: Property verification (2 SP)

---

## Risk Assessment & Mitigation

### High-Risk Areas

**1. Race Conditions in Member Limit Checking**
- Risk: Concurrent imports both check limit, both pass, both create
- Mitigation: Use atomic $inc for memberCount; validate during creation
- Task: 10.8 (Concurrency test)

**2. File Parsing Errors with Large Files**
- Risk: Out of memory or timeout
- Mitigation: Stream-based parsing; 1000 row limit
- Task: 9.1 (Performance testing)

**3. Temporary File Cleanup**
- Risk: Temp files not deleted, disk fills up
- Mitigation: Always delete in finally block; test cleanup
- Task: 4.1 (Verified in tests)

**4. Email Enumeration in Duplicate Check**
- Risk: Timing differences reveal which emails exist
- Mitigation: Consistent query timing; follow existing pattern
- Task: 2.4 (Uses org-scoped queries)

### Medium-Risk Areas

**1. Bulk Create Partial Failure**
- Risk: Some users created before error, inconsistent state
- Mitigation: Atomic operations; detailed error reporting
- Task: 10.3, 10.8

**2. Password Reset Flag Confusion**
- Risk: Client forgets to check flag, bypasses reset flow
- Mitigation: Clear documentation; API requires reset endpoint
- Task: 7.1, 11.1

**3. Organization Scoping Errors**
- Risk: User imported to wrong organization
- Mitigation: Extract org from JWT; verify in controller; test scoping
- Task: 10.10

---

## Implementation Order & Sprint Planning

### Sprint 1 (Week 1-2): Core Implementation
- Week 1:
  - 1.1: Install dependencies (1 day)
  - 1.2: Service skeleton (1 day)
  - 2.1-2.6: Core service functions (5 days)
  - 3.1-3.3: Model updates (1 day)

- Week 2:
  - 4.1: Main controller (3 days)
  - 4.2-4.3: Routes and multer (2 days)
  - 5.1-5.2: Auth verification (1 day)
  - 6.1-6.2: Logging setup (1 day)

**Deliverable:** Complete backend implementation ready for testing

### Sprint 2 (Week 3-4): Testing & Documentation
- Week 3:
  - 9.1-9.7: Unit tests (3 days)
  - 10.1-10.7: Integration tests (3 days)
  - Bug fixes from test failures (1 day)

- Week 4:
  - 10.8-10.10: Concurrency and integration tests (2 days)
  - 7.1-7.4: Endpoint updates and testing (2 days)
  - 11.1-11.3: Documentation and verification (2 days)
  - Final cleanup and code review (1 day)

**Deliverable:** Fully tested, documented, production-ready feature

---

## Success Criteria

Feature is complete when:

1. **All 40 tasks completed** ✓
2. **All 22 properties verified** ✓
3. **Test coverage > 90%** ✓
4. **All integration tests pass** ✓
5. **No race conditions in concurrency tests** ✓
6. **API documentation complete** ✓
7. **Frontend integration guide provided** ✓
8. **Code reviewed and approved** ✓
9. **Security audit passed** ✓
10. **Performance benchmarks met** (< 5 sec for 1000 rows)

---

## Appendix: Test Data Files

### Sample Excel File (valid.xlsx)
```
Name,Email
John Doe,john@example.com
Jane Smith,jane@example.com
Bob Wilson,bob@example.com
```

### Sample CSV File (valid.csv)
```
Name,Email
Alice Brown,alice@example.com
Charlie Davis,charlie@example.com
```

### Sample Invalid File (invalid.xlsx)
```
Name,Email,Phone
Test User,test@example.com,555-1234
```

---

## Appendix: Quick Reference

**Key Endpoints:**
- `POST /api/v1/auth/bulk-import` - Main bulk import endpoint
- `POST /api/v1/auth/login` - Updated to return passwordResetRequired
- `POST /api/v1/auth/users/:id/password` - Updated to clear flag

**Key Service Functions:**
- `parseExcelFile(filePath)`
- `parseCsvFile(filePath)`
- `validateFileFormat(rows)`
- `validateRowData(rows)`
- `checkDuplicatesInOrganization(emails, organizationId)`
- `detectInFileDuplicates(rows)`
- `checkMemberLimit(organizationId, validRows)`
- `createBulkUsers(rows, organizationId, hashedPassword)`
- `generateImportReport(successfulUsers, failedRows, batchId)`

**Database Collections:**
- `users_{organizationId}` - User records (affected)
- `organizations` - Organization metadata (memberCount incremented)
- Logs - Audit trail of imports

