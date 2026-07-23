import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_3d_view.dart';
import 'package:flutter/material.dart';

class VenueMapPage extends StatelessWidget {
  const VenueMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t.venueMap.title)),
      body: VenueMap3DView(languageCode: languageCode),
    );
  }
}
