import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/feature/force_update/data/force_update_provider.dart';
import 'package:app/feature/force_update/data/force_update_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Covers [child] with an undismissable update prompt while the running
/// version is below the published minimum.
///
/// Inserted from `MaterialApp.builder` so that it blocks every route at once.
/// It is not a Navigator route, hence the Android back gesture cannot close
/// it. Being outside the Navigator also means nothing here may rely on an
/// Overlay (no [Tooltip], no [SnackBar]).
class ForceUpdateBlocker extends ConsumerWidget {
  const ForceUpdateBlocker({required this.child, this.launcher, super.key});

  final Widget child;

  /// Injected by tests; production opens the store with url_launcher.
  final ExternalUrlLauncher? launcher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forceUpdateProvider);
    if (!state.isUpdateRequired) {
      return child;
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背後の画面はタップもキーボードフォーカスもスクリーンリーダーの
        // 読み上げも対象外にする。
        ExcludeFocus(child: ExcludeSemantics(child: child)),
        const ModalBarrier(dismissible: false, color: Colors.black54),
        ForceUpdateDialog(state: state, launcher: launcher),
      ],
    );
  }
}

/// The prompt itself: one button and no way to dismiss it.
@visibleForTesting
class ForceUpdateDialog extends ConsumerWidget {
  const ForceUpdateDialog({required this.state, this.launcher, super.key});

  final ForceUpdateState state;
  final ExternalUrlLauncher? launcher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    return AlertDialog(
      // 小画面や大きな文字サイズでも本文が途切れないようスクロールさせる。
      scrollable: true,
      title: Text(t.forceUpdate.title),
      // 現在の表示言語のリモート文言を優先し、無ければ同梱の文言を使う。
      content: Text(state.messageFor(t.$meta.locale.languageCode) ?? t.forceUpdate.message),
      actions: [
        TextButton(
          onPressed: () => unawaited(_openStore(ref)),
          child: Text(t.forceUpdate.updateButton),
        ),
      ],
    );
  }

  Future<void> _openStore(WidgetRef ref) async {
    final talker = ref.read(talkerProvider);
    final uri = Uri.tryParse(state.storeUrl);
    if (state.storeUrl.isEmpty || uri == null) {
      // iOS は初回リリースまでストア URL が空。開く先が無いのでログだけ残す。
      talker.warning('No store URL configured for the forced update: "${state.storeUrl}"');
      return;
    }
    final launched = await tryLaunchExternalUrl(uri, launcher: launcher);
    if (!launched) {
      talker.warning('Could not open the store URL for the forced update: $uri');
    }
  }
}
