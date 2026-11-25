import 'package:jaspr/jaspr.dart';

import '../components/event_section.dart';
import '../components/exchange_counter_section.dart';
import '../components/hiring_section.dart';
import '../components/photo_album_hero.dart';
import '../components/sponsors_section.dart';
import '../components/staff_section.dart';
import '../components/timetable_section.dart';
import '../constants/generated_sessions.dart';

class Home extends StatelessComponent {
  const Home({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      // 開催後のトップは公式写真アルバムの写真ゾーン。
      const PhotoAlbumHero(),
      const EventSection(),
      const ExchangeCounterSection(),
      // スポンサー情報（JobBoards を含む）を先に並べ、スタッフは末尾に置く。
      const TimetableSection(rooms: generatedTimetableRooms, programmes: generatedTimetableByDay),
      const SponsorsSection(),
      const HiringSection(),
      const StaffSection(),
    ]);
  }
}
