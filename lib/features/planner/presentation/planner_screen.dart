import 'package:flutter/material.dart';
import 'week_grid_mobile.dart';

/// PlannerScreen is now just a thin wrapper around WeekGridMobile.
/// Navigation (AppBar, FAB) is handled by DashboardScreen.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WeekGridMobile();
  }
}
