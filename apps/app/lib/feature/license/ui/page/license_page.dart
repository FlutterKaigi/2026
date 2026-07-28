import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/feature/license/data/license_provider.dart';
import 'package:app/feature/license/data/license_repository.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Lists bundled OSS packages with an in-page search field, following 2025.
class OssLicensePage extends ConsumerStatefulWidget {
  const OssLicensePage({super.key});

  @override
  ConsumerState<OssLicensePage> createState() => _OssLicensePageState();
}

class _OssLicensePageState extends ConsumerState<OssLicensePage> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final licenses = ref.watch(licensesProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              const EventInfoRoute().go(context);
            }
          },
          icon: const BackButtonIcon(),
        ),
        title: Text(
          t.licenses.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: switch (licenses) {
        AsyncLoading() => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(licensesProvider),
        ),
        AsyncData(:final value) => _LicenseList(
          licenses: value,
          query: _query,
          searchController: _searchController,
          onQueryChanged: (value) => setState(() => _query = value),
        ),
      },
    );
  }
}

class _LicenseList extends StatelessWidget {
  const _LicenseList({
    required this.licenses,
    required this.query,
    required this.searchController,
    required this.onQueryChanged,
  });

  final LicenseGroups licenses;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final normalizedQuery = query.trim().toLowerCase();
    final entries = licenses.entries
        .where(
          (entry) => normalizedQuery.isEmpty || entry.key.toLowerCase().contains(normalizedQuery),
        )
        .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchBar(
                controller: searchController,
                hintText: t.licenses.searchHint,
                leading: const Icon(Icons.search),
                trailing: [
                  if (query.isNotEmpty)
                    IconButton(
                      tooltip: t.licenses.clearSearch,
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
                ],
                onChanged: onQueryChanged,
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    subtitle: Text(
                      t.licenses.licenseCount(n: entry.value.length),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => LicenseDetailRoute(
                      packageName: entry.key,
                    ).push<void>(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
