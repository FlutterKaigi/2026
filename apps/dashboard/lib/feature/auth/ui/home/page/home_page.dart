import 'package:dashboard/feature/auth/ui/home/widget/menu.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterKaigi 2026 管理ダッシュボード'),
        actions: [
          Menu(),
        ],
      ),
      body: const Center(
        child: Text('ダッシュボード（実装予定）'),
      ),
    );
  }
}
