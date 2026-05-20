import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('类别管理'),
            subtitle: const Text('新增、编辑、删除支出与收入类别'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('预算设置'),
            subtitle: const Text('为支出类别设置月度额度并跟踪进度'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/budgets'),
          ),
          const ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text('主题'),
            subtitle: Text('跟随系统'),
          ),
        ],
      ),
    );
  }
}
