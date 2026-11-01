import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../l10n/strings.dart';

/// Full-width timetable event; recordings open the same details as sessions.
class TimetableEventCard extends StatelessComponent {
  const TimetableEventCard({
    required this.title,
    required this.start,
    required this.end,
    required this.gridRow,
    required this.strings,
    this.dialogId,
    super.key,
  });

  final String title;
  final String start;
  final String end;
  final String gridRow;
  final Strings strings;
  final String? dialogId;

  @override
  Component build(BuildContext context) {
    final children = [
      span(classes: 'timetable-event__time', [.text('$start – $end')]),
      span([.text(title)]),
      if (dialogId != null) span(classes: 'timetable-event__archive', [.text(strings.timetableWatchArchive)]),
    ];
    final styles = Styles(raw: {'grid-row': gridRow});
    if (dialogId case final id?) {
      return button(
        classes: 'timetable-event timetable-event--interactive',
        type: ButtonType.button,
        styles: styles,
        attributes: {'popovertarget': id},
        children,
      );
    }
    return div(classes: 'timetable-event', styles: styles, children);
  }
}
