import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/add_expense_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import 'theme.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'add',
          builder: (BuildContext context, GoRouterState state) =>
              const AddExpenseScreen(),
        ),
        GoRoute(
          path: 'statistics',
          builder: (BuildContext context, GoRouterState state) =>
              const StatisticsScreen(),
        ),
        GoRoute(
          path: 'history',
          builder: (BuildContext context, GoRouterState state) =>
              const HistoryScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (BuildContext context, GoRouterState state) =>
              const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Expense Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
