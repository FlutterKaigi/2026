import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/license/data/license_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Displays every license paragraph registered for one package.
class LicenseDetailPage extends ConsumerWidget {
  const LicenseDetailPage({required this.packageName, super.key});

  final String packageName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenses = ref.watch(licensesProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          packageName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
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
        AsyncData(:final value) => _LicenseBody(
          groups: value[packageName],
        ),
      },
    );
  }
}

class _LicenseBody extends StatelessWidget {
  const _LicenseBody({required this.groups});

  final List<List<LicenseParagraph>>? groups;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final groups = this.groups;
    if (groups == null || groups.isEmpty) {
      return Center(child: Text(t.licenses.notFound));
    }

    return AppScrollbar(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: groups.length,
            itemBuilder: (context, index) => _LicenseGroup(
              paragraphs: groups[index],
              showDivider: index > 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _LicenseGroup extends StatelessWidget {
  const _LicenseGroup({
    required this.paragraphs,
    required this.showDivider,
  });

  final List<LicenseParagraph> paragraphs;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDivider) const Divider(height: 24),
        for (final paragraph in paragraphs)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: 8,
              start: paragraph.indent == LicenseParagraph.centeredIndent ? 0 : 8.0 * paragraph.indent,
            ),
            child: Text(
              paragraph.text,
              textAlign: paragraph.indent == LicenseParagraph.centeredIndent ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: paragraph.indent == LicenseParagraph.centeredIndent ? FontWeight.w700 : null,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
