# Design Document: Bulk User Import via Excel

## Overview

The bulk user import feature enables organization admins to efficiently onboard multiple team members by uploading an Excel or CSV file. This feature streamlines the user creation workflow, validates data comprehensively, detects duplicates within the organization, enforces member limits, and provides detailed reporting of successes and failures. The implementation integrates seamlessly with the existing single-user creation workflow and maintains strict multi-tenant isolation.

### Key Design Decisions

1. **File Processing Pipeline**: Sequential validation stages (format → row data → duplicates → password → member limit) allow early rejection and clear error reporting
2. **Atomic Operations**: MongoDB atomic increments (`$inc`) prevent race conditions during concurrent bulk imports
3. **Organization Scoping**: All operations are scoped to the admin's organization; duplicate detection uses organization-specific queries
4. **Batch User Creation**: Valid rows are created in a single batch operation for performance, with individual user creation failures handled gracefully
5. **Detailed Reporting**: Multi-status responses (207) distinguish between partial successes and complete failures
6. **Password Reset Flag**: Imported users are marked with `requiresPasswordReset: true`, forcing them to change passwords on first login
7. **Audit Trail**: All import events are logged with admin ID, organization ID, file metadata, and IP address for compliance

---

## Architecture

### Request Flow

```
Admin POSTs to /api/v1/auth/bulk-import
    ↓
[Authentication Middleware]
    ↓ (Verify JWT token)
[Authorization Middleware]
    ↓ (Verify admin role)
[File Upload Middleware]
    ↓ (Accept multipart/form-data)
[Bulk Import Controller]
    ├─ Parse file (XLSX/CSV)
    ├─ Validate file format (2 columns, headers)
    ├─ Validate each row (name, email, format, trim)
    ├─ Validate password strength
    ├─ Check for duplicates (org-scoped)
    ├─ Check member limit
    ├─ Create users in batch
    ├─ Increment organization memberCount (atomic)
    ├─ Log audit events
    └─ Return import report (201, 207, or 400)
```

### File Handling

- **Upload**: Multipart form-data via `multer` middleware (existing file upload infrastructure)
- **Temporary Storage**: File stored temporarily in memory or temp directory
- **Parsing**: 
  - **XLSX**: `xlsx` library to parse sheets and extract data rows
  - **CSV**: `csv-parse` library to parse delimited values
- **Cleanup**: Temporary file deleted after processing completes (success or failure)
- **Size Limits**: Enforce 2MB file size limit (existing backend standard)

### Data Validation Strategy

#### Stage 1: File Format Validation
- Verify file type (.xlsx or .csv)
- Parse file without errors
- Check for exactly 2 columns
- Verify column headers are "Name" and "Email" (case-insensitive)

**Failure**: Return HTTP 400 with file format error

#### Stage 2: Row-Level Data Validation
- For each row:
  - Name field: non-empty, trim whitespace, max 100 characters
  - Email field: non-empty, trim whitespace, valid RFC 5322 format
- Collect all validation errors per row
- Mark failed rows with specific error reasons

**Failure**: If all rows fail validation, return HTTP 400 with all row errors

#### Stage 3: Password Validation
- Admin-provided default password: minimum 6 characters (same as existing system)
- Validate before any user creation

**Failure**: Return HTTP 400 with password error

#### Stage 4: Duplicate Detection (Organization-Scoped)
- Query existing users in admin's organization
- Case-insensitive email comparison (using lowercase normalization)
- Within file: mark all but first occurrence of duplicate email as failed
- Against database: mark any email matching existing user in organization as failed

**Failure**: If all rows are duplicates, return HTTP 400

#### Stage 5: Member Limit Check
- Query organization's current `memberCount` and `memberLimit`
- Check if adding all valid rows would exceed limit
- If yes, determine which rows can be created (up to limit)
- Mark excess rows as failed

**Partial Failure**: If some rows exceed limit, create up to limit and return HTTP 207

#### Stage 6: User Creation
- For each valid row (not failed in earlier stages):
  1. Create User document with:
     - `name`: trimmed text value
     - `email`: lowercase trimmed value
     - `password`: admin-provided default (will be hashed by pre-save hook)
     - `role`: `member`
     - `organizationId`: admin's organization ID
     - `emailVerified`: `false`
     - `lastLoginTimestamp`: `null`
     - `requiresPasswordReset`: `true`
  2. Trigger password hashing middleware (existing pre-save hook)
  3. Log user creation event with batch import ID
  4. Atomic increment organization `memberCount` using `findByIdAndUpdate` with `$inc`

**Failure at User Creation**: 
- If duplicate key error (email taken between validation and creation): mark as failed, continue
- If other database error: mark as failed, continue
- If member limit exceeded atomically: mark as failed, continue

### Import Report Generation

**Success Responses**

HTTP 201 (Created) - All rows successfully created:
```json
{
  "success": true,
  "status": 201,
  "data": {
    "batchId": "batch_12345_uuid",
    "totalRows": 50,
    "successCount": 50,
    "failedCount": 0,
    "successfulUsers": [
      { "id": "user_id", "name": "John Doe", "email": "john@example.com", "role": "member" },
      ...
    ],
    "failedRows": []
  },
  "message": "All users imported successfully"
}
```

HTTP 207 (Multi-Status) - Partial success:
```json
{
  "success": false,
  "status": 207,
  "data": {
    "batchId": "batch_12345_uuid",
    "totalRows": 50,
    "successCount": 45,
    "failedCount": 5,
    "successfulUsers": [
      { "id": "user_id", "name": "John Doe", "email": "john@example.com", "role": "member" },
      ...
    ],
    "failedRows": [
      { "rowNumber": 3, "name": "Jane Doe", "email": "jane@example.com", "error": "Email already exists in organization" },
      { "rowNumber": 7, "name": "Bob Smith", "email": "invalid-email", "error": "Invalid email format" },
      { "rowNumber": 48, "name": "Alice Johnson", "email": "alice@example.com", "error": "Organization member limit exceeded" }
    ]
  },
  "message": "Import completed with 45 successes and 5 failures"
}
```

**Error Responses**

HTTP 400 (Bad Request) - Validation error before any user creation:
```json
{
  "success": false,
  "status": 400,
  "data": null,
  "message": "Import validation failed",
  "errors": {
    "fileFormat": "File must contain exactly 2 columns (found 3)",
    "headers": "Column headers must be 'Name' and 'Email' (found 'Name', 'Email', 'Phone')"
  }
}
```

HTTP 400 (Bad Request) - All rows invalid:
```json
{
  "success": false,
  "status": 400,
  "data": null,
  "message": "All rows failed validation",
  "failedRows": [
    { "rowNumber": 1, "error": "Name field is empty" },
    { "rowNumber": 2, "error": "Invalid email format" },
    { "rowNumber": 3, "error": "Email field is empty" }
  ]
}
```

HTTP 500 (Internal Server Error) - System error during import:
```json
{
  "success": false,
  "status": 500,
  "data": null,
  "message": "Import processing failed",
  "error": "Database connection error"
}
```

---

## Components and Interfaces

### Controller: `bulkUserImportController.js`

**Endpoint**: `POST /api/v1/auth/bulk-import`

**Middleware Stack**:
1. `protect` (JWT authentication)
2. `authorize(['admin'])` (admin role verification)
3. `createUserLimiter` (rate limiting)
4. `multer` (file upload - max 2MB)

**Request**:
- **Body** (multipart/form-data):
  - `file` (required): Excel (.xlsx) or CSV (.csv) file
  - `password` (required): Default password string

**Response**:
- **201 Created**: All users imported successfully
- **207 Multi-Status**: Partial import (some users created, some failed)
- **400 Bad Request**: Validation error or all rows invalid
- **500 Internal Server Error**: System error

**Handler Function**: `bulkImportUsers`
```
async (req, res) => {
  // 1. Validate request (file, password, auth, authorization)
  // 2. Parse file (XLSX or CSV)
  // 3. Validate file format (2 columns, headers)
  // 4. Validate rows (trim, validate name/email, format)
  // 5. Validate password strength
  // 6. Check for duplicates (org-scoped)
  // 7. Check member limit
  // 8. Create users (batch)
  // 9. Increment memberCount (atomic)
  // 10. Generate import report
  // 11. Log audit events
  // 12. Return response
}
```

### Service: `bulkImportService.js` (New)

Helper functions extracted for clarity and testability:

**Functions**:
- `parseExcelFile(filePath)` → Returns array of row objects
- `parseCsvFile(filePath)` → Returns array of row objects
- `validateFileFormat(rows)` → Validates column structure
- `validateRowData(rows)` → Validates and trims each row
- `checkDuplicatesInOrganization(emails, organizationId)` → Queries database
- `detectInFileduplicates(rows)` → Marks duplicates within file
- `checkMemberLimit(organizationId, rowCount)` → Checks available capacity
- `createBulkUsers(rows, organizationId, hashedPassword)` → Batch creation
- `generateImportReport(successfulUsers, failedRows, batchId)` → Report formatting

### Model Updates: `User.js`

**New Field** (optional, supports Req. 11):
```javascript
requiresPasswordReset: {
  type: Boolean,
  default: false
}
```

**Existing Fields** (used by bulk import):
- `name` - Imported from file, trimmed
- `email` - Imported from file, lowercase + trimmed
- `password` - Admin-provided default, hashed by pre-save hook
- `role` - Always `member` for bulk imports
- `organizationId` - Admin's organization ID
- `emailVerified` - Always `false` for bulk imports
- `lastLoginTimestamp` - Always `null` for bulk imports

### Route: `authRoutes.js`

**New Route**:
```javascript
router.post(
  '/bulk-import',
  protect,
  authorize(['admin']),
  createUserLimiter,
  upload.single('file'),  // Multer middleware for single file
  bulkImportUsers         // New controller function
);
```

### Middleware Updates

**File Upload Middleware** (`multer` configuration):
- Max file size: 2MB (consistent with existing limits)
- Allowed mime types: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`, `text/csv`
- Storage: Memory storage (deleted after processing)
- File field name: `file`

### Logging

**Audit Log Events** (using existing `logger.admin`):

1. **Import Start**:
   ```
   logger.admin('Bulk import initiated', {
     adminId: req.user.id,
     organizationId: req.user.organizationId,
     fileName: req.file.originalname,
     fileSize: req.file.size,
     rowCount: rows.length,
     ip: req.ip,
     timestamp: new Date()
   })
   ```

2. **User Creation (per user)**:
   ```
   logger.admin('User created via bulk import', {
     userId: newUser._id,
     email: newUser.email,
     batchId: importBatchId,
     ip: req.ip
   })
   ```

3. **Import Completion**:
   ```
   logger.admin('Bulk import completed', {
     adminId: req.user.id,
     organizationId: req.user.organizationId,
     batchId: importBatchId,
     totalRows: importReport.totalRows,
     successCount: importReport.successCount,
     failedCount: importReport.failedCount,
     duration: elapsedTime,
     ip: req.ip
   })
   ```

4. **Import Failure**:
   ```
   logger.admin('Bulk import failed', {
     adminId: req.user.id,
     organizationId: req.user.organizationId,
     fileName: req.file.originalname,
     reason: error.message,
     ip: req.ip
   })
   ```

---

## Data Models

### Import Report Object

```javascript
{
  batchId: String,              // UUID generated for batch
  totalRows: Number,            // Total rows in file
  successCount: Number,         // Rows successfully created
  failedCount: Number,          // Rows that failed
  successfulUsers: Array,       // Array of created user objects
  failedRows: Array,            // Array of failed row details
  timestamp: Date,              // When import completed
  duration: Number              // Processing time in milliseconds
}
```

### Failed Row Object

```javascript
{
  rowNumber: Number,            // 1-indexed row in file
  name: String,                 // Name value from file
  email: String,                // Email value from file
  error: String                 // Error reason (validation, duplicate, limit, etc.)
}
```

### Successful User Object

```javascript
{
  id: ObjectId,                 // User's MongoDB ID
  name: String,                 // User's name
  email: String,                // User's email (lowercase)
  role: String                  // Always "member"
}
```

---

## Error Handling

### Pre-Validation Errors (400)

| Error | Cause | Handling |
|-------|-------|----------|
| `File is required` | No file uploaded | Check `req.file` exists |
| `Password is required` | No password parameter | Check `req.body.password` exists |
| `Unsupported file format` | File is not .xlsx or .csv | Validate MIME type |
| `File size exceeds 2MB` | File too large | Multer enforces limit |
| `Password must be at least 6 characters` | Password too short | Validate length |
| `File contains no rows` | Empty file after header | Count rows after parse |

### File Format Errors (400)

| Error | Cause | Handling |
|-------|-------|----------|
| `File must contain exactly 2 columns` | Wrong column count | Check parsed sheet dimensions |
| `Column headers must be 'Name' and 'Email'` | Wrong headers | Validate header row case-insensitive |
| `File parsing failed` | Corrupted file | Try/catch around parser |

### Row Validation Errors (400 or 207)

| Error | Cause | Handling |
|-------|-------|----------|
| `Name field is empty` | Name is null/empty/whitespace | Trim and check length |
| `Email field is empty` | Email is null/empty/whitespace | Trim and check length |
| `Invalid email format` | Email doesn't match RFC 5322 | Use existing regex from User model |
| `Name exceeds 100 characters` | Name too long | Check after trim |
| `Email exceeds 100 characters` | Email too long | Check after trim |

### Duplicate Detection Errors (400 or 207)

| Error | Cause | Handling |
|-------|-------|----------|
| `Email already exists in organization` | Email found in User collection | Query database case-insensitive |
| `Duplicate email in file` | Same email appears twice in file | Track seen emails during parsing |

### Member Limit Errors (207)

| Error | Cause | Handling |
|-------|-------|----------|
| `Organization member limit exceeded` | Adding user would exceed limit | Check `memberCount + 1 > memberLimit` |
| `No capacity to import any users` | All rows fail due to limit | Reject import if `successCount === 0` |

### System Errors (500)

| Error | Cause | Handling |
|-------|-------|----------|
| `Database error` | MongoDB connection/query error | Catch error, log, return 500 |
| `File parsing error` | Corrupted or unreadable file | Catch parser exception |
| `User creation failed` | Unexpected error during save | Catch error, mark row failed, continue |

### Error Response Format

```javascript
{
  success: false,
  data: null,
  message: "Error description",
  errors: { field: "error message" }  // If multiple errors
}
```

---

## Testing Strategy

### Unit Tests

**File Parsing**:
- Test XLSX parsing with valid file
- Test CSV parsing with valid file
- Test rejection of invalid file formats
- Test handling of corrupted files

**Data Validation**:
- Test name validation (empty, whitespace, too long)
- Test email validation (empty, invalid format, too long)
- Test trimming of whitespace
- Test case-insensitive header matching

**Duplicate Detection**:
- Test detection of duplicates in database (org-scoped)
- Test detection of duplicates within file
- Test that first occurrence is not marked duplicate
- Test email case-insensitivity

**Member Limit Enforcement**:
- Test capacity check (under limit, at limit, over limit)
- Test partial creation when some rows exceed limit
- Test rejection when no rows can be created

**Import Report Generation**:
- Test HTTP 201 response when all rows succeed
- Test HTTP 207 response when partial success
- Test HTTP 400 response for validation errors
- Test report structure and data completeness

### Integration Tests

**End-to-End Flow**:
- Test complete import with valid Excel file
- Test complete import with valid CSV file
- Test import with mixed results (some pass, some fail)
- Test import that fails file format validation
- Test import that fails password validation
- Test import that fails member limit check
- Test audit logging of successful import
- Test audit logging of failed import

**Concurrency Tests**:
- Test concurrent imports to same organization (atomicity)
- Test concurrent single-user and bulk imports (data consistency)
- Test race condition handling for member limit

**Multi-Tenant Isolation Tests**:
- Test that admin can only import to own organization
- Test that duplicate detection is org-scoped (same email in different org is OK)
- Test that memberCount increments are isolated per organization

---

## Security Considerations

### Authentication & Authorization
- JWT token required (existing `protect` middleware)
- Admin role required (existing `authorize` middleware)
- Organization context extracted from JWT claims

### Input Validation & Sanitization
- File type validation (whitelist .xlsx, .csv)
- File size limit (2MB)
- Email format validation (RFC 5322 regex)
- Name trimming and length limits
- Password strength validation

### Data Protection
- Temporary files deleted after processing
- Passwords hashed using bcryptjs (existing pre-save hook)
- Email stored lowercase (prevents case-sensitivity attacks)
- Audit logging of all import actions with IP address

### Timing Attacks
- No timing differences between existing email and new email (existing single-user endpoint pattern)
- Batch processing prevents request length variance attacks

### Rate Limiting
- Reuse existing `createUserLimiter` middleware
- Apply per admin to prevent bulk import abuse

### Multi-Tenant Isolation
- All queries scoped to admin's organization
- No cross-organization data leakage
- Duplicate detection is org-scoped (email duplicate is only within org)

---

## Performance Considerations

### File Processing
- Stream large files if > 1MB (implement later if needed)
- Process rows sequentially to provide detailed error feedback
- Lazy-load file parser libraries to reduce memory footprint

### Database Operations
- Batch user creation with `User.insertMany()` for valid rows
- Atomic `$inc` for organization memberCount to prevent race conditions
- Use indexed queries for duplicate detection (index on `organizationId`, `email`)
- Reuse organization object from req.user context when possible

### Response Time
- Target: < 5 seconds for 1000 rows (with network latency)
- Optimize: Use indexed lookups, batch operations, avoid N+1 queries

### Constraints
- Maximum 1000 rows per import (prevent system overload)
- Maximum 2MB file size (existing backend standard)

---

## Known Limitations & Future Enhancements

### Limitations
1. **Single Language**: File headers and validation messages are English-only
2. **No Transaction Rollback**: If import fails partway through, created users remain (by design—report shows which were created)
3. **No Resume**: Cannot resume a failed import; must re-upload and re-validate
4. **No Email Notification**: Imported users are not automatically notified; admin must provide passwords separately
5. **No Bulk Edit**: Cannot re-run import to update existing users (only creates new)

### Future Enhancements
1. **Email Notifications**: Auto-send welcome emails with temporary password and reset link
2. **Password-Less Onboarding**: Generate unique invite links instead of sharing password
3. **Import History**: Track and display previous imports with results
4. **Resume Failed Imports**: Allow admin to retry or continue failed import
5. **Bulk Update**: Support updating existing users (merge with existing email)
6. **Scheduled Imports**: Allow scheduled uploads from external source (e.g., SFTP, Google Drive)
7. **Custom Field Mapping**: Allow import of additional fields (phone, role, department)
8. **Multi-Language**: Localize error messages and UI

---

## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: File Format Validation

**For any** Excel or CSV file with exactly 2 columns labeled "Name" and "Email" (case-insensitive), the system SHALL successfully parse all data rows without file format errors and extract them for downstream validation.

**Validates: Requirements 1.1, 1.2, 1.5**

### Property 2: Row Data Validation

**For any** row with non-empty, properly formatted name and email (after trimming), the system SHALL mark the row as valid for further processing (duplicate detection, member limit check).

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

### Property 3: Email Format Validation

**For any** email string, if it conforms to RFC 5322 pattern matching, the system SHALL accept it as valid; if it does not conform, the system SHALL reject it with an "Invalid email format" error.

**Validates: Requirements 2.3**

### Property 4: Whitespace Normalization

**For any** name or email field with leading or trailing whitespace, the system SHALL trim the whitespace and store the normalized value in the database.

**Validates: Requirements 2.4**

### Property 5: Organization-Scoped Duplicate Detection

**For any** email in the import file, if a user with that email (case-insensitive) already exists in the admin's organization, the system SHALL mark that row as failed with a duplicate error.

**Validates: Requirements 3.1, 3.2**

### Property 6: In-File Duplicate Handling

**For any** import file where the same email appears multiple times, the system SHALL mark all but the first occurrence as duplicate failures.

**Validates: Requirements 3.3**

### Property 7: Password Strength Enforcement

**For any** default password provided by the admin, if the password contains fewer than 6 characters, the system SHALL reject the import with a password validation error before creating any users.

**Validates: Requirements 4.1, 4.2, 4.3**

### Property 8: Password Hashing Consistency

**For any** imported user created with a default password, the system SHALL hash the password using bcryptjs with the same salt rounds as single-user creation (both passwords hash consistently and can be verified with the same algorithm).

**Validates: Requirements 4.4, 4.5**

### Property 9: User Role Assignment

**For any** user created via bulk import, the system SHALL assign the `member` role and the admin's organization ID (never `admin` or `super_admin` roles, never NULL organization).

**Validates: Requirements 5.2, 5.3**

### Property 10: User Initialization State

**For any** user created via bulk import, the system SHALL set `emailVerified` to `false`, `lastLoginTimestamp` to `null`, and `requiresPasswordReset` to `true`.

**Validates: Requirements 5.4, 5.5, 11.1**

### Property 11: Atomic Member Count Increment

**For any** user creation in bulk import, the system SHALL increment the organization's `memberCount` atomically using MongoDB's `$inc` operator, preventing race conditions even during concurrent imports.

**Validates: Requirements 5.7, 9.4**

### Property 12: Member Limit Enforcement

**For any** bulk import, if the total valid rows would exceed the organization's member limit, the system SHALL mark excess rows as failed and only create users up to the limit (or reject entirely if no rows can be created).

**Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

### Property 13: Import Report Completeness

**For any** completed import, the system SHALL return a report containing: total row count, successful count, failed count, successful user details (ID, name, email, role), and failed row details (row number, name, email, error reason).

**Validates: Requirements 7.1, 7.2, 7.3, 7.4**

### Property 14: HTTP Status Code Accuracy

**For any** import result:
- If all rows succeed: return HTTP 201 (Created)
- If some rows fail: return HTTP 207 (Multi-Status)
- If validation fails before any user creation: return HTTP 400 (Bad Request)
- If system error occurs: return HTTP 500

**Validates: Requirements 7.5, 7.6, 7.7, 7.8**

### Property 15: Audit Log Completeness

**For any** bulk import operation, the system SHALL log: import start event (with admin ID, org ID, file metadata), user creation events (with user ID, email, batch ID), import completion event (with success/failure counts), all with admin IP address.

**Validates: Requirements 8.1, 8.2, 8.3, 8.4, 8.5**

### Property 16: Single-User Endpoint Integrity

**For any** single-user creation request via `/api/v1/auth/users` endpoint, the system SHALL continue to work identically before and after bulk import feature addition (same validation, same authorization, same member limit checks, no interference from bulk import workflows).

**Validates: Requirements 9.1, 9.2, 9.3**

### Property 17: Concurrent Operation Consistency

**For any** concurrent single-user creation and bulk import operations targeting the same organization, the system SHALL maintain data consistency using atomic MongoDB operations, ensuring memberCount is never inaccurate and member limits are never violated.

**Validates: Requirements 9.4**

### Property 18: Endpoint Availability

The system SHALL provide a POST endpoint at `/api/v1/auth/bulk-import` that accepts file upload in multipart/form-data format, requires JWT authentication and admin authorization, and accepts a password parameter.

**Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5**

### Property 19: File Type Validation

**For any** file upload to the bulk import endpoint, if the file is not `.xlsx` or `.csv` format, the system SHALL reject with "Unsupported file format" error.

**Validates: Requirements 10.7, 10.8**

### Property 20: Password Reset Flag on First Login

**For any** user created via bulk import with `requiresPasswordReset: true`, when that user logs in, the system SHALL include `passwordResetRequired: true` in the login response.

**Validates: Requirements 11.1, 11.2, 11.3**

### Property 21: Password Change Clears Reset Flag

**For any** imported user with `requiresPasswordReset: true`, when the user updates their password via `/api/v1/auth/users/:id/password` endpoint, the system SHALL set `requiresPasswordReset` to `false`.

**Validates: Requirements 11.4**

### Property 22: All-Row Failure Rejection

**For any** import where all rows fail validation, the system SHALL reject the entire import without creating any users and return HTTP 400 with all row errors.

**Validates: Requirements 2.6, 3.4**

---

## Implementation Checklist

- [ ] Create `bulkImportService.js` with file parsing, validation, and reporting functions
- [ ] Update `authController.js` with `bulkImportUsers` function
- [ ] Add `/bulk-import` route to `authRoutes.js` with appropriate middleware
- [ ] Update `User.js` model with `requiresPasswordReset` field
- [ ] Configure `multer` for file upload (2MB limit, Excel/CSV MIME types)
- [ ] Update login endpoint to check and return `passwordResetRequired` flag
- [ ] Update password change endpoint to clear `requiresPasswordReset` flag
- [ ] Add audit logging for all bulk import events
- [ ] Write comprehensive unit tests for validation functions
- [ ] Write integration tests for complete import flow
- [ ] Test concurrent imports and race condition handling
- [ ] Test multi-tenant isolation
- [ ] Document API endpoint with request/response examples
- [ ] Create admin dashboard UI component for file upload (Flutter frontend)

---

## Dependencies

### New Packages Required

| Package | Version | Purpose |
|---------|---------|---------|
| `xlsx` | ^0.18.5 | Parse Excel (.xlsx) files |
| `csv-parse` | ^5.4.1 | Parse CSV files |

### Existing Packages Used

| Package | Purpose |
|---------|---------|
| `multer` | File upload middleware |
| `bcryptjs` | Password hashing |
| `express` | Web framework |
| `mongoose` | MongoDB ODM |
| `winston` | Logging |
| `joi` | Validation |

---

## References & Notes

- Existing single-user creation: `/api/v1/auth/users` POST endpoint (preserve as-is)
- Existing file upload infrastructure: `multer` with 2MB limit
- Existing logging system: `winston` with daily rotation
- Existing authentication: JWT in Authorization header
- Existing password hashing: `bcryptjs` with salt rounds in pre-save hook
- Multi-tenant architecture: Organization scoping via `organizationId` in JWT claims
- Rate limiting: Reuse existing `createUserLimiter` middleware
- Error handling: Follow existing error response format with `sendError` helper

