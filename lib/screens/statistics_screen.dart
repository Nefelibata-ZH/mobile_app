import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/statistics_provider.dart';
import '../utils/formatters.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, double> byCategory =
        ref.watch(currentMonthByCategoryProvider);
    final List<MapEntry<String, double>> entries = byCategory.entries.toList()
      ..sort(
        (MapEntry<String, double> a, MapEntry<String, double> b) =>
            b.value.compareTo(a.value),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: entries.isEmpty
          ? const Center(child: Text('本月暂无支出'))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (BuildContext context, int index) {
                final MapEntry<String, double> e = entries[index];
                return ListTile(
                  title: Text(e.key),
                  trailing: Text(Formatters.currency(e.value)),
                );
              },
            ),
    );
  }
}
