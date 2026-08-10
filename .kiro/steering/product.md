# Product Overview

## What is Task Manager?

Task Manager is a **collaborative productivity platform** designed for teams and organizations to manage work efficiently. It provides role-based task assignment, real-time communication, submission tracking, and performance analytics.

## Core Features

- **Task Management** - Create, assign, track, and manage tasks with priorities and due dates
- **Real-time Collaboration** - Socket.IO-powered live messaging and task updates
- **Submission Tracking** - Team members submit work which admins review and approve/reject
- **Performance Analytics** - Leaderboards, activity tracking, and dashboard statistics
- **File Uploads** - AWS S3 integration for task attachments and submission files
- **Push Notifications** - Firebase Cloud Messaging for instant updates
- **Role-Based Access Control** - Three roles: `member`, `admin`, `super_admin`

## Current State (v1.3.0)

- Single-organization deployment
- Backend: Node.js/Express/MongoDB REST API
- Frontend: Flutter mobile app with offline-first support
- Real-time features via Socket.IO

## Strategic Direction

**Multi-tenant SaaS Platform** - Transform into multi-organization system where:
- Super Admin manages organizations but cannot access their data
- Organization Admins manage their own teams independently
- Complete data isolation between organizations
- ITH (parent organization) remains special with full access

## Target Users

- **Organizations** needing collaborative task management
- **Teams** requiring performance tracking and accountability
- **Managers** wanting real-time visibility into team work
- **Individual Contributors** tracking assigned work and deadlines

## Success Metrics

- Team task completion rates
- Real-time collaboration engagement
- Admin oversight and reporting capabilities
- System performance and reliability
