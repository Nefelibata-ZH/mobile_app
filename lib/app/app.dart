import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../screens/add_expense_screen.dart';
import '../screens/category_management_screen.dart';
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
          routes: <RouteBase>[
            GoRoute(
              path: 'categories',
              builder: (BuildContext context, GoRouterState state) =>
                  const CategoryManagementScreen(),
            ),
          ],
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
      locale: const Locale('zh', 'CN'),
      supportedLocales: const <Locale>[
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
