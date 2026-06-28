import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/daily_summary.dart';
import '../models/macro_nutrient.dart';
import '../models/user.dart';
import '../providers/user_providers.dart';
import '../providers/meal_providers.dart';
import '../providers/stats_providers.dart';
import '../widgets/kudal_card.dart';
import '../widgets/macro_summary_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Color _statusColor(DayStatus status) {
    switch (status) {
      case DayStatus.success:
        return const Color(0xFF5CB85C);
      case DayStatus.warning:
        return const Color(0xFFFFCC00);
      case DayStatus.over:
        return const Color(0xFFFF6B6B);
      case DayStatus.empty:
        return const Color(0xFFCCC5BF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final macroAsync = ref.watch(todayMacroProvider);
    final calendarAsync = ref.watch(
      calendarDataProvider((_focusedDay.year, _focusedDay.month)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(userAsync),
              const SizedBox(height: 20),
              _buildCalendar(calendarAsync),
              const SizedBox(height: 16),
              _buildMacroCard(macroAsync),
              const SizedBox(height: 16),
              _buildQuickButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<User> userAsync) {
    final name = userAsync.whenOrNull(data: (u) => u.name) ?? '...';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안녕, $name! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A2E2A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '오늘도 건강하게 보내자!',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF3A2E2A).withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const KudalCard(message: '오늘 단백질 굿!', size: 72),
      ],
    );
  }

  Widget _buildCalendar(AsyncValue<List<DailySummary>> calendarAsync) {
    final calendarData = calendarAsync.valueOrNull ?? [];

    DayStatus getStatus(DateTime day) {
      try {
        return calendarData
            .firstWhere((d) => isSameDay(d.date, day))
            .status;
      } catch (_) {
        return DayStatus.empty;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A7B9).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2025, 1, 1),
        lastDay: DateTime(2027, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) => setState(() => _focusedDay = focused),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(color: Color(0xFF3A2E2A), fontSize: 13),
          weekendTextStyle: const TextStyle(color: Color(0xFFF4A7B9), fontSize: 13),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFFF4A7B9),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFFF4A7B9).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Color(0xFF3A2E2A),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          markerDecoration: const BoxDecoration(shape: BoxShape.circle),
          markersMaxCount: 1,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3A2E2A),
          ),
          leftChevronIcon:
              const Icon(Icons.chevron_left_rounded, color: Color(0xFFF4A7B9)),
          rightChevronIcon:
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFF4A7B9)),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Color(0xFF3A2E2A),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: Color(0xFFF4A7B9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, _) {
            final status = getStatus(day);
            if (status == DayStatus.empty) return const SizedBox.shrink();
            return Positioned(
              bottom: 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor(status),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMacroCard(AsyncValue<MacroNutrient> macroAsync) {
    return macroAsync.when(
      data: (macro) => MacroSummaryCard(macro: macro),
      loading: () => const _MacroLoadingCard(),
      error: (_, __) => const _MacroLoadingCard(),
    );
  }

  Widget _buildQuickButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 기록',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3A2E2A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickButton(
              icon: Icons.restaurant_rounded,
              label: '식단 기록',
              color: const Color(0xFFF4A7B9),
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _QuickButton(
              icon: Icons.fitness_center_rounded,
              label: '운동 기록',
              color: const Color(0xFFFFD1A9),
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _QuickButton(
              icon: Icons.monitor_weight_rounded,
              label: '체중 기록',
              color: const Color(0xFFE8D5C4),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

// ── 로딩 플레이스홀더 ────────────────────────────────────────

class _MacroLoadingCard extends StatelessWidget {
  const _MacroLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A7B9).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4A7B9)),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A2E2A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
