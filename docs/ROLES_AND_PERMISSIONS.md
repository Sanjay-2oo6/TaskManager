# Task Manager - Roles & Permissions

**Version:** 2.0.0 (Multi-Tenant)  
**Last Updated:** July 18, 2026

---

## Role Hierarchy Overview

```
┌─────────────────────────────────────────────────────────┐
│                    SUPER ADMIN                           │
│              (Application Owner - You)                   │
│                                                          │
│  ✅ Create organizations                                │
│  ✅ Create admin accounts for organizations             │
│  ✅ Set organization member limits                      │
│  ✅ Activate/deactivate organizations                   │
│  ✅ Change organization branding                        │
│  ❌ Cannot access organization data (tasks, members)    │
└─────────────────────────────────────────────────────────┘
                           │
                           │ Creates Organizations
                           ▼
┌─────────────────────────────────────────────────────────┐
│                       ADMIN                              │
│              (Organization Admin)                        │
│                                                          │
│  ✅ Create member accounts (within limit)               │
│  ✅ Create and assign tasks                             │
│  ✅ Edit and delete tasks                               │
│  ✅ Approve/reject submissions                          │
│  ✅ View all organization data                          │
│  ✅ Change organization name and branding               │
│  ✅ View analytics and reports                          │
│  ❌ Cannot create other organizations                   │
│  ❌ Cannot change member limits                         │
└─────────────────────────────────────────────────────────┘
                           │
                           │ Creates Members
                           ▼
┌─────────────────────────────────────────────────────────┐
│                      MEMBER                              │
│              (Team Member / Worker)                      │
│                                                          │
│  ✅ View assigned tasks                                 │
│  ✅ Update task status (in-progress, submitted)         │
│  ✅ Submit work (photos, documents)                     │
│  ✅ Chat on assigned tasks                              │
│  ✅ View task history and comments                      │
│  ✅ Change own password                                 │
│  ❌ Cannot create tasks                                 │
│  ❌ Cannot view other members' tasks                    │
│  ❌ Cannot approve submissions                          │
└─────────────────────────────────────────────────────────┘
```

---

## Detailed Role Permissions

### 1. Super Admin (Application Owner)

**Role Code:** `super_admin`

**Purpose:** Application maintainer who manages the entire multi-tenant platform.

#### ✅ Can Do:

**Organization Management:**
- Create new organizations
- Create admin accounts for organizations
- Set member limits per organization (10, 50, 100, unlimited)
- Activate or deactivate organizations
- Delete organizations
- Change organization names
- Update organization branding (logo, banner, welcome message)
- View organization list and status

**Platform Management:**
- Access super admin dashboard
- View platform-wide statistics
- Manage subscription plans
- Configure system settings

#### ❌ Cannot Do:

**Data Privacy Restrictions:**
- ❌ View organization tasks
- ❌ View organization members list
- ❌ View organization messages
- ❌ View organization submissions
- ❌ Access any organization-specific data (for privacy/legal reasons)

**Use Cases:**
- You creating a new organization for "Company A"
- Setting Company A's member limit to 50 users
- Activating/deactivating organizations based on subscription
- Managing ITH (your own organization)

---

### 2. Admin (Organization Admin)

**Role Code:** `admin`

**Purpose:** Manages a single organization - team lead, manager, or company owner.

#### ✅ Can Do:

**Team Management:**
- Create member accounts (within organization's limit)
- Delete member accounts
- Reset member passwords
- View all members in organization
- Assign tasks to members

**Task Management:**
- Create new tasks
- Edit task details (title, description, priority, deadline)
- Delete tasks
- Assign/reassign tasks to members
- Update task status
- Add admin notes and reference files
- Create task dependencies (sequential workflows)

**Work Review:**
- View all submissions
- Approve or reject submissions
- Add feedback to submissions
- Add comments to submissions
- Request revisions

**Communication:**
- Send messages in any task chat
- View all messages in organization
- Mark messages as read

**Analytics:**
- View team performance metrics
- Access leaderboards
- View completion rates
- Export reports

**Organization Settings:**
- Change organization name
- Update organization logo
- Change welcome banner
- Modify welcome message
- Update organization theme color

#### ❌ Cannot Do:

**Platform Restrictions:**
- ❌ Create new organizations
- ❌ Change organization member limit
- ❌ Activate/deactivate own organization
- ❌ View other organizations' data
- ❌ Access super admin dashboard
- ❌ Create other admin accounts

**Use Cases:**
- Company A admin creating member accounts for their team
- Assigning tasks to team members
- Reviewing work submissions
- Managing team performance
- Customizing organization branding

---

### 3. Member (Team Member)

**Role Code:** `member`

**Purpose:** Executes tasks and submits work - front-line workers, field staff, team members.

#### ✅ Can Do:

**Task Execution:**
- View tasks assigned to them
- Update task status (mark as in-progress, submitted)
- Add notes to tasks
- View task details, deadlines, priorities
- View admin notes and reference files
- View task history

**Work Submission:**
- Submit proof of work (before/after photos)
- Upload documents and files
- Add description to submissions
- View own submission status
- Resubmit if rejected
- View admin feedback

**Communication:**
- Send messages in assigned task chats
- View messages in assigned tasks
- Mark messages as read
- View who has read messages
- Add comments to tasks

**Profile Management:**
- View own profile
- Change own password
- Update notification settings
- View own statistics (tasks completed, etc.)

#### ❌ Cannot Do:

**Management Restrictions:**
- ❌ Create tasks
- ❌ Edit tasks (except status updates)
- ❌ Delete tasks
- ❌ Assign tasks to others
- ❌ View other members' tasks (unless co-assigned)
- ❌ View other members' submissions
- ❌ Approve/reject submissions
- ❌ Create other accounts
- ❌ View team analytics
- ❌ Access admin dashboard
- ❌ Change organization settings

**Use Cases:**
- Field worker viewing assigned tasks
- Submitting before/after photos of completed work
- Asking questions in task chat
- Checking task deadlines and priorities
- Viewing admin feedback on submissions

---

## Permission Matrix

| Action | Super Admin | Admin | Member |
|--------|-------------|-------|--------|
| **Organizations** |
| Create organization | ✅ | ❌ | ❌ |
| View organization list | ✅ | ❌ | ❌ |
| Set member limits | ✅ | ❌ | ❌ |
| Activate/deactivate org | ✅ | ❌ | ❌ |
| Change org name | ✅ | ✅ | ❌ |
| Change org branding | ✅ | ✅ | ❌ |
| **Users** |
| Create admin accounts | ✅ | ❌ | ❌ |
| Create member accounts | ❌ | ✅ | ❌ |
| Delete users | ❌ | ✅ | ❌ |
| Reset passwords | ❌ | ✅ | Own only |
| View member list | ❌ | ✅ | ❌ |
| **Tasks** |
| Create tasks | ❌ | ✅ | ❌ |
| Edit tasks | ❌ | ✅ | Status only |
| Delete tasks | ❌ | ✅ | ❌ |
| View all tasks | ❌ | ✅ | Assigned only |
| Assign tasks | ❌ | ✅ | ❌ |
| Add admin notes | ❌ | ✅ | ❌ |
| **Submissions** |
| Submit work | ❌ | ✅ | ✅ |
| Approve/reject | ❌ | ✅ | ❌ |
| View all submissions | ❌ | ✅ | Own only |
| Add feedback | ❌ | ✅ | ❌ |
| **Messages** |
| Send messages | ❌ | ✅ | ✅ |
| View all messages | ❌ | ✅ | Assigned tasks only |
| **Analytics** |
| View team analytics | ❌ | ✅ | ❌ |
| View platform analytics | ✅ | ❌ | ❌ |
| View own stats | ❌ | ✅ | ✅ |

---

## API Authorization

### Endpoint Access by Role

#### Authentication Endpoints
```
POST /auth/login              → All (public)
POST /auth/users              → Admin only
GET /auth/users               → Admin only
GET /auth/me                  → All (authenticated)
PATCH /auth/me/password       → All (authenticated)
DELETE /auth/users/:id        → Admin only
PATCH /auth/users/:id/password → Admin only
```

#### Super Admin Endpoints (NEW)
```
POST /super-admin/organizations           → Super Admin only
GET /super-admin/organizations            → Super Admin only
GET /super-admin/organizations/:id        → Super Admin only
PATCH /super-admin/organizations/:id      → Super Admin only
DELETE /super-admin/organizations/:id     → Super Admin only
POST /super-admin/organizations/:id/toggle → Super Admin only
```

#### Task Endpoints
```
POST /tasks                   → Admin only
GET /tasks                    → All (filtered by role)
GET /tasks/:id                → Admin or assigned member
PATCH /tasks/:id              → Admin only
DELETE /tasks/:id             → Admin only
POST /tasks/:id/comments      → Admin or assigned member
```

#### Submission Endpoints
```
POST /submissions             → Admin or Member
GET /submissions              → All (filtered by role)
GET /submissions/:id          → Admin or submission owner
PATCH /submissions/:id/status → Admin only
POST /submissions/:id/comments → Admin or submission owner
```

#### Message Endpoints
```
POST /messages                → Admin or assigned member
GET /messages/task/:taskId    → Admin or assigned member
PATCH /messages/mark-read/:taskId → Admin or assigned member
```

#### Analytics Endpoints
```
GET /analytics/leaderboard    → Admin only
GET /analytics/team-activity  → Admin only
GET /analytics/dashboard-stats → All (filtered by role)
```

---

## Role-Based UI Elements

### Super Admin Dashboard
- Organization list with status
- Create organization button
- Platform statistics
- Member limit management
- Organization activation controls
- No access to task/member data

### Admin Dashboard
- Task management interface
- Team member list
- Create task button
- Submission review panel
- Analytics and reports
- Organization settings
- Member creation form

### Member Dashboard
- Assigned task list
- Submit work button
- Task details view
- Chat interface
- Own statistics
- Profile settings

---

## Migration Notes

### Old → New Role Mapping

| Old Role | New Role | Notes |
|----------|----------|-------|
| `employee` | `member` | Renamed for better clarity |
| `worker` | `member` | Consolidated into member |
| `assigner` | `admin` | Consolidated into admin |
| `admin` | `admin` | Remains same (org admin) |
| N/A | `super_admin` | NEW - Platform owner |

### Database Migration Required

```javascript
// Update existing users
db.users.updateMany(
  { role: { $in: ['employee', 'worker'] } },
  { $set: { role: 'member' } }
);

db.users.updateMany(
  { role: 'assigner' },
  { $set: { role: 'admin' } }
);

// Create super admin
db.users.updateOne(
  { username: 'sanjay' },
  { $set: { role: 'super_admin', organization_slug: null } }
);
```

---

## Security Considerations

### Super Admin Restrictions

**Why super admin cannot access organization data:**
1. **Privacy Compliance:** Legal requirement for data isolation
2. **Trust:** Organizations trust their data is private
3. **Security:** Reduces attack surface if super admin account compromised
4. **Liability:** Limits liability if data breach occurs

### Organization Data Isolation

Each organization's data is completely separate:
- Separate database collections (tasks_orgA, tasks_orgB)
- No cross-organization queries
- Admin can only see their organization's data
- Members can only see assigned tasks

### Password Requirements

All roles must use strong passwords:
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter  
- At least 1 number
- At least 1 special character

---

## Best Practices

### For Super Admins
1. **Never** try to access organization data directly
2. If support needed, ask admin to share specific info
3. Always set appropriate member limits
4. Monitor organization activity metrics only
5. Deactivate instead of delete (preserves data)

### For Admins
1. Create members with clear role understanding
2. Assign tasks with clear instructions
3. Review submissions promptly
4. Provide constructive feedback
5. Monitor team performance regularly

### For Members
1. Check tasks daily
2. Ask questions early if unclear
3. Submit work promptly
4. Include clear photos and descriptions
5. Respond to feedback quickly

---

**Document Version:** 2.0.0  
**Effective Date:** July 18, 2026  
**Last Updated:** July 18, 2026
