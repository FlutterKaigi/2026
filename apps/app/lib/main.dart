import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/provider/environment.dart';
import 'feature/news/provider/news_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final environment = Environment.fromEnvironment();
  final firestoreHostParts = environment.firestoreHost.split(':');
  await FirebaseInitializer.ensureInitialized(
    projectId: environment.firebaseProjectId,
    host: firestoreHostParts.first,
    firestorePort: firestoreHostParts.length > 1
        ? int.parse(firestoreHostParts[1])
        : 8080,
  );

  runApp(const ProviderScope(child: NewsSampleApp()));
}

class NewsSampleApp extends ConsumerWidget {
  const NewsSampleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(environmentProvider);
    return MaterialApp(
      title: environment.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EE)),
        useMaterial3: true,
      ),
      home: const NewsSamplePage(),
    );
  }
}

class NewsSamplePage extends ConsumerWidget {
  const NewsSamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(environmentProvider);
    final news = ref.watch(newsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(environment.appName),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(newsProvider),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: news.when(
          data: (news) {
            if (news.isEmpty) {
              return const _MessagePane(
                icon: Icons.article_outlined,
                title: 'No news yet',
                body: 'Seed Firestore and refresh this screen.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: news.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _NewsTile(news: news[index]),
            );
          },
          error: (error, stackTrace) => _MessagePane(
            icon: Icons.cloud_off,
            title: 'Firebase Emulator is not reachable',
            body: error.toString(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.news});

  final News news;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              news.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              news.startsAt.toLocal().toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (news.url case final url?) ...[
              const SizedBox(height: 8),
              Text(
                url.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
