# Requirements Document: Bulk User Import via Excel

## Introduction

This document specifies requirements for a bulk user import feature in the Task Manager admin dashboard. Admins will be able to import multiple team members at once via Excel file upload, streamlining onboarding workflows. The system will validate file format, detect duplicates, create user accounts with a default password, and provide detailed import reports to the admin.

## Glossary

- **Admin**: User with `admin` role, belongs to a single organization
- **Organization**: A tenant container with its own users, tasks, and data (multi-tenant pattern)
- **Excel File**: Spreadsheet format (.xlsx or .csv) with 2 columns: Name, Email
- **Default Password**: A temporary password assigned to all newly imported users during bulk import
- **Import Report**: Summary of successful imports, failures, and duplicate detections
- **Member**: User with `member` role, belongs to an organization
- **System**: The Task Manager application backend API

---

## Requirements

### Requirement 1: Excel File Format Validation

**User Story:** As an admin, I want the system to validate my Excel file format, so that I receive clear feedback on any structural issues before processing begins.

#### Acceptance Criteria

1. WHEN an admin uploads an Excel file (.xlsx) or CSV file (.csv), THE System SHALL validate that the file contains exactly 2 columns
2. WHEN the Excel file contains exactly 2 columns, THE System SHALL verify the column headers are "Name" and "Email" (case-insensitive)
3. IF the Excel file does not have exactly 2 columns, THEN THE System SHALL reject the file and return an error message indicating the expected column count
4. IF the Excel file column headers do not match expected headers, THEN THE System SHALL reject the file and return an error message specifying the mismatched headers
5. WHEN the file format is valid (2 columns with correct headers), THE System SHALL extract all data rows from the file

### Requirement 2: Input Data Validation Per Row

**User Story:** As an admin, I want each row in my Excel file to be validated individually, so that I can identify which rows have issues before import begins.

#### Acceptance Criteria

1. FOR EACH row in the Excel file, THE System SHALL validate that the Name field is non-empty and not purely whitespace
2. FOR EACH row in the Excel file, THE System SHALL validate that the Email field is non-empty and not purely whitespace
3. FOR EACH row in the Excel file, THE System SHALL validate that the Email field matches a valid email format using RFC 5322 pattern matching
4. FOR EACH row in the Excel file, THE System SHALL trim leading and trailing whitespace from Name and Email fields
5. FOR EACH row with invalid data, THE System SHALL mark the row as failed and include the specific validation error in the import report
6. IF all rows are invalid, THEN THE System SHALL reject the entire import and return errors without creating any users

### Requirement 3: Duplicate Email Detection (Organization Scope)

**User Story:** As an admin, I want the system to detect duplicate emails within my organization, so that I don't accidentally create multiple accounts for the same person.

#### Acceptance Criteria

1. BEFORE creating any users, THE System SHALL query the database to find existing users in the admin's organization with matching emails (case-insensitive)
2. IF an email in the import file matches an existing user in the organization, THEN THE System SHALL mark that row as failed with a duplicate error message
3. WHEN processing multiple rows with the same email in the import file, THE System SHALL mark all but the first occurrence as duplicate
4. IF all rows are duplicates of existing users, THEN THE System SHALL reject the entire import without creating any users

### Requirement 4: Default Password Assignment

**User Story:** As an admin, I want to specify a default password for imported users, so that I can control the initial credentials and provide them to team members securely.

#### Acceptance Criteria

1. WHEN the admin initiates a bulk import, THE System SHALL require the admin to provide a default password
2. WHEN validating the default password, THE System SHALL enforce the same password strength requirements as single-user creation (minimum 6 characters)
3. IF the default password does not meet strength requirements, THEN THE System SHALL reject the import request and return password validation error
4. WHEN creating imported users, THE System SHALL hash the default password using bcryptjs before storage
5. WHEN creating imported users, THE System SHALL use the same password hashing algorithm and salt rounds as existing single-user creation

### Requirement 5: Batch User Creation

**User Story:** As an admin, I want the system to create multiple user accounts in a single operation, so that onboarding is fast and efficient.

#### Acceptance Criteria

1. WHEN all validation checks pass (file format, row data, duplicates, password strength), THE System SHALL create user accounts for all valid rows
2. WHEN creating bulk imported users, THE System SHALL assign the `member` role to all imported users
3. WHEN creating bulk imported users, THE System SHALL assign the admin's organization ID to all imported users
4. WHEN creating bulk imported users, THE System SHALL set the user's `emailVerified` field to `false`
5. WHEN creating bulk imported users, THE System SHALL set the user's `lastLoginTimestamp` to `null`
6. WHEN creating a bulk imported user, THE System SHALL trigger password hash middleware before storage (same as single-user creation)
7. WHEN creating bulk imported users, THE System SHALL increment the organization's memberCount atomically for each user created
8. IF creating a user would exceed the organization's member limit, THEN THE System SHALL reject that user and mark as failed
9. WHEN a user creation fails due to member limit, THE System SHALL continue processing remaining rows and report the failure

### Requirement 6: Organization Member Limit Enforcement

**User Story:** As an organization manager, I want the system to enforce member limits during bulk import, so that we stay within our subscription tier.

#### Acceptance Criteria

1. WHEN the admin initiates bulk import, THE System SHALL check the organization's current member count against the member limit
2. BEFORE creating each user, THE System SHALL verify the organization has capacity for additional member
3. IF creating a user would exceed the organization member limit, THEN THE System SHALL mark that user as failed with "Organization member limit exceeded" error
4. IF the entire import would exceed the member limit with zero users created, THEN THE System SHALL reject the import entirely
5. WHERE the import is partially blocked due to member limit, THE System SHALL create users up to the limit and report which rows were blocked

### Requirement 7: Import Success/Error Reporting

**User Story:** As an admin, I want detailed feedback about the import results, so that I know which users were created and which ones failed with reasons.

#### Acceptance Criteria

1. WHEN import processing completes, THE System SHALL return an import report to the admin
2. WHEN import is successful, THE System SHALL include total row count, successful count, and failed count in the report
3. FOR EACH successfully created user, THE System SHALL include: user ID, name, email, and role in the report
4. FOR EACH failed row, THE System SHALL include: row number, name, email, and error reason in the report
5. WHEN the import has both successes and failures, THE System SHALL return HTTP status 207 (Multi-Status) with detailed breakdown
6. WHEN the import is completely successful (all rows created), THE System SHALL return HTTP status 201 (Created)
7. WHEN the import fails validation before any users are created, THE System SHALL return HTTP status 400 (Bad Request) with validation errors
8. WHEN import processing encounters a system error, THE System SHALL return HTTP status 500 with error details

### Requirement 8: Audit Logging of Bulk Import

**User Story:** As a system administrator, I want all bulk import actions to be logged, so that I have an audit trail for compliance and troubleshooting.

#### Acceptance Criteria

1. WHEN an admin initiates a bulk import, THE System SHALL log the import start event with admin ID, organization ID, and file metadata
2. WHEN bulk import completes, THE System SHALL log the import completion with total users created and any errors encountered
3. WHEN each user is created via bulk import, THE System SHALL log the user creation event with user ID, email, and import batch ID
4. WHEN a bulk import fails, THE System SHALL log the failure with reason and which users (if any) were created before failure
5. WHEN logging bulk import events, THE System SHALL include IP address of the admin initiating the import

### Requirement 9: Preserve Single-User Creation Workflow

**User Story:** As an admin, I want the existing single-user creation method to remain unchanged, so that I can continue using it as an alternative to bulk import.

#### Acceptance Criteria

1. WHEN an admin uses the existing `/api/v1/auth/users` POST endpoint, THE System SHALL continue to work exactly as before
2. WHEN the single-user creation endpoint is used, THE System SHALL enforce the same validation, role restrictions, and member limit checks
3. WHEN both single-user and bulk import endpoints are used, THE System SHALL not interfere with either workflow
4. WHEN single-user creation and bulk import are used concurrently, THE System SHALL maintain data consistency using atomic MongoDB operations

### Requirement 10: File Upload Endpoint

**User Story:** As an admin, I want a dedicated API endpoint to upload my Excel file, so that I can integrate it with the admin dashboard UI.

#### Acceptance Criteria

1. THE System SHALL provide a POST endpoint at `/api/v1/auth/bulk-import` for bulk user import
2. WHEN an admin POSTs to the bulk import endpoint, THE System SHALL require authentication (JWT token in Authorization header)
3. WHEN an admin POSTs to the bulk import endpoint, THE System SHALL authorize the request only for users with `admin` role
4. WHEN an admin POSTs to the bulk import endpoint, THE System SHALL accept a file upload with form-data (multipart/form-data)
5. WHEN an admin POSTs to the bulk import endpoint, THE System SHALL require a `password` parameter for the default password
6. IF the request is missing the file or password parameter, THEN THE System SHALL return HTTP 400 with error message
7. WHEN the endpoint receives a file, THE System SHALL handle .xlsx (Excel) or .csv (Comma-separated values) file types
8. IF the uploaded file is not .xlsx or .csv format, THEN THE System SHALL reject with "Unsupported file format" error

### Requirement 11: Password Reset on First Login (Recommended Feature)

**User Story:** As an admin, I want imported users to be able to change their password on first login, so that they can secure their account with a personal password.

#### Acceptance Criteria

1. WHERE a user account is created via bulk import, THE System SHALL mark the user account with a `requiresPasswordReset` flag set to `true`
2. WHEN an imported user logs in for the first time, THE System SHALL check if `requiresPasswordReset` is `true`
3. IF `requiresPasswordReset` is `true` on login, THE System SHALL include `passwordResetRequired: true` in the login response
4. WHEN a user updates their password via the `/api/v1/auth/users/:id/password` endpoint, THE System SHALL set `requiresPasswordReset` to `false`
5. WHEN a user changes their password, THE System SHALL log the password change event

---

## Special Notes

### Multi-Tenant Considerations
- Bulk import is organization-scoped: an admin can only import users into their own organization
- Email uniqueness is checked globally (across all organizations), as per existing User model constraint
- Member limit is enforced per organization (existing Organization model feature)

### Security Considerations
- File uploads will be temporary and deleted after processing
- Password strength validation matches existing single-user creation standards
- Audit logging will track all import actions for compliance
- Email enumeration attacks are mitigated through timing-consistent validation

### Implementation Notes
- Excel parsing library: `xlsx` package (commonly used with Node.js)
- CSV parsing library: `csv-parse` or `fast-csv` package
- File size limit: 2MB (consistent with backend file upload limits)
- Maximum rows per import: 1000 (to prevent system overload)
- Bulk import will use batch operations where possible for performance

