# Susu App

A robust Flutter application for managing Susu savings groups, contributions, and withdrawals. This app streamlines the financial tracking process for organizations, providing distinct roles for Admins and Employees.

## Features

### 🔐 Authentication & Security
- **Secure Login**: Role-based authentication (Admin/Employee) using Firebase Auth.
- **Role Management**: Admins can manage staff accounts, update details, and reset passwords.
- **Secure Data**: All financial data is stored securely in Cloud Firestore.

### 💰 Financial Management (GH¢)
- **Contributions**: Track monthly Susu contributions with ease.
- **Withdrawals**: 
  - Employees can request withdrawals via the app.
  - Admins can view pending requests, history, and Approve/Reject/Process them.
  - Automatic balance updates upon approval.
- **History**: Detailed view of all past contributions and withdrawals.
- **Export**: Admins can export account statements to CSV for external reporting.

### 🔔 Notifications
- **Real-time Updates**: 
  - Admins receive notifications for new withdrawal requests.
  - Users receive notifications when their request status changes (Approved/Rejected).
- **In-App Alerts**: Dialogs appear for important updates while using the app.

### 👥 User Management
- **Admin Dashboard**: Centralized view for managing staff and approvals.
- **Staff List**: View, edit, and manage staff members.
- **Linked Accounts**: See which staff members are linked to specific Susu accounts.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions)
- **Notifications**: Firebase Cloud Messaging (FCM) & Local Notifications
- **Cloud Functions**: Node.js (TypeScript) for secure backend logic (Notifications, Email Updates).

## Getting Started

1. **Prerequisites**:
   - Flutter SDK installed.
   - Android Studio or VS Code.
   - Firebase Project setup with `google-services.json`.

2. **Installation**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Copyright © 2025 FedCo*
