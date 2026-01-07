import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/manual_entry_screen.dart';
import '../features/admin/add_contribution_screen.dart';
import '../features/admin/create_user_screen.dart'; // New Import
import '../features/admin/user_list_screen.dart';
import '../features/admin/withdrawal_approval_screen.dart';
import '../features/admin/staff_list_screen.dart';
import '../features/employee/employee_dashboard.dart';
import '../features/employee/withdrawal_request_screen.dart';
import '../features/employee/my_requests_screen.dart';
import '../features/shared/settings_screen.dart';

class AppRoutes {
  // Core Routes
  static const String login = '/';
  static const String settings = '/settings';
  
  // Admin Routes
  static const String adminDashboard = '/admin';
  static const String manualEntry = '/admin/manual_entry';
  static const String addContribution = '/admin/add_contribution';
  static const String createUser = '/admin/create_user'; // New Route
  static const String userList = '/admin/users';
  static const String staffList = '/admin/staff';
  static const String withdrawalApproval = '/admin/withdrawals';
  
  // Employee Routes
  static const String employeeDashboard = '/employee';
  static const String withdrawalRequest = '/employee/withdrawal_request';
  static const String myRequests = '/employee/my_requests';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Core
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      // Admin
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case AppRoutes.manualEntry:
        return MaterialPageRoute(builder: (_) => const ManualEntryScreen());
      case AppRoutes.addContribution:
        return MaterialPageRoute(builder: (_) => const AddContributionScreen());
      case AppRoutes.createUser: // New Case
        return MaterialPageRoute(builder: (_) => const CreateUserScreen());
      case AppRoutes.userList:
        return MaterialPageRoute(builder: (_) => const UserListScreen());
      case AppRoutes.staffList:
        return MaterialPageRoute(builder: (_) => const StaffListScreen());
      case AppRoutes.withdrawalApproval:
        return MaterialPageRoute(builder: (_) => const WithdrawalApprovalScreen());
      
      // Employee
      case AppRoutes.employeeDashboard:
        return MaterialPageRoute(builder: (_) => const EmployeeDashboard());
      case AppRoutes.withdrawalRequest:
        return MaterialPageRoute(builder: (_) => const WithdrawalRequestScreen());
      case AppRoutes.myRequests:
        return MaterialPageRoute(builder: (_) => const MyRequestsScreen());

      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                  body: Center(child: Text('No route defined for ${settings.name}')),
                ));
    }
  }
}
