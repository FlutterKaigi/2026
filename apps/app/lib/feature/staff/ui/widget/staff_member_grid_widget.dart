import 'package:app/feature/staff/ui/widget/staff_member_card_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// Responsive grid of staff profile cards.
class StaffMemberGridWidget extends StatelessWidget {
  const StaffMemberGridWidget({
    required this.staffMembers,
    super.key,
  });

  final List<StaffMember> staffMembers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 240).floor().clamp(1, 4);
        return GridView.builder(
          padding: _paddingFor(MediaQuery.sizeOf(context).width),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: staffMembers.length,
          itemBuilder: (context, index) => StaffMemberCardWidget(
            staffMember: staffMembers[index],
          ),
        );
      },
    );
  }

  EdgeInsets _paddingFor(double width) {
    if (width < 640) {
      return const EdgeInsets.all(16);
    }
    if (width < 960) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
  }
}
