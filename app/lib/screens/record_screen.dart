import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal.dart';
import '../models/macro_nutrient.dart';
import '../providers/meal_providers.dart';
import '../providers/kudal_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/stats_providers.dart';

class RecordScreen extends ConsumerWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                '오늘의 기록',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A2E2A),
                ),
              ),
            ),
            Expanded(
              child: mealsAsync.when(
                data: (sections) => _MealList(sections: sections),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFF4A7B9)),
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('😢', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 12),
                      Text(
                        '데이터를 불러오지 못했어요.',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF3A2E2A).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 식사 목록 ────────────────────────────────────────────────

class _MealList extends ConsumerWidget {
  final List<MealSection> sections;
  const _MealList({required this.sections});

  Future<void> _showPhotoBottomSheet(BuildContext context, WidgetRef ref) async {
    String? selectedOption;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PhotoBottomSheet(
        onOptionSelected: (option) {
          selectedOption = option;
          Navigator.pop(sheetCtx);
        },
      ),
    );

    if (selectedOption == null || selectedOption == 'manual') return;
    if (!context.mounted) return;

    final picker = ImagePicker();
    final XFile? image = selectedOption == 'camera'
        ? await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
            maxWidth: 1920,
          )
        : await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 1920,
          );

    if (image == null || !context.mounted) return;

    // 분석 시작 (즉시 loading 상태로 전환)
    ref.read(analysisProvider.notifier).analyze(File(image.path));
    _showAnalysisPopup(context, ref);
  }

  void _showAnalysisPopup(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => _AnalysisBottomSheet(
        onSave: () async {
          try {
            await ref
                .read(analysisProvider.notifier)
                .saveToMeal(DateTime.now());
            if (!sheetContext.mounted) return;
            Navigator.pop(sheetContext);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '식단이 저장됐어요. 쿠달이가 좋아해요! 🐾',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFFF4A7B9),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            ref.read(analysisProvider.notifier).reset();
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '저장에 실패했어요. 다시 시도해주세요.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFFFF6B6B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onClose: () => Navigator.pop(sheetContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEmpty = sections.every((s) => s.meals.isEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (allEmpty)
            const _EmptyState()
          else
            ...sections.map((s) => _MealSection(section: s)),
          const SizedBox(height: 8),
          _AddPhotoButton(
            onTap: () { _showPhotoBottomSheet(context, ref); },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── 빈 상태 ────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF4A7B9).withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF4A7B9).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          const Text(
            '아직 기록이 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3A2E2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '쿠달이가 기다리고 있어요.',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF3A2E2A).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 식사 섹션 ────────────────────────────────────────────────

class _MealSection extends ConsumerWidget {
  final MealSection section;
  const _MealSection({required this.section});

  Future<void> _onDelete(BuildContext context, WidgetRef ref, Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('삭제할까요?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('${meal.name}을(를) 삭제합니다.', style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(mealRepositoryProvider).deleteMealItem(meal.id);
      ref.invalidate(mealsProvider);
      ref.invalidate(todayMacroProvider);
      ref.invalidate(calendarDataProvider);
      ref.invalidate(weeklyStatsProvider);
      ref.invalidate(kudalProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _onEdit(BuildContext context, WidgetRef ref, Meal meal) async {
    final updated = await showDialog<Meal>(
      context: context,
      builder: (ctx) => _SavedFoodEditDialog(meal: meal),
    );
    if (updated == null || !context.mounted) return;
    try {
      await ref.read(mealRepositoryProvider).updateMealItem(meal.id, updated);
      ref.invalidate(mealsProvider);
      ref.invalidate(todayMacroProvider);
      ref.invalidate(calendarDataProvider);
      ref.invalidate(weeklyStatsProvider);
      ref.invalidate(kudalProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A7B9).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MealIcon(emoji: section.emoji),
              const SizedBox(width: 10),
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A2E2A),
                ),
              ),
              const Spacer(),
              if (section.meals.isNotEmpty)
                Text(
                  '${section.totalCalories} kcal',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFF4A7B9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (section.meals.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...section.meals.map((m) => _FoodRow(
                  meal: m,
                  onDelete: () => _onDelete(context, ref, m),
                  onEdit: () => _onEdit(context, ref, m),
                )),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              '아직 기록이 없어요',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF3A2E2A).withOpacity(0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealIcon extends StatelessWidget {
  final String emoji;
  const _MealIcon({required this.emoji});

  static const _colors = {
    '🌅': Color(0xFFFFE0B2),
    '☀️': Color(0xFFFFF3CD),
    '🌙': Color(0xFFE8D5C4),
    '🍎': Color(0xFFF4A7B9),
  };

  @override
  Widget build(BuildContext context) {
    final color = (_colors[emoji] ?? const Color(0xFFE8D5C4)).withOpacity(0.4);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
    );
  }
}

class _FoodRow extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _FoodRow({required this.meal, this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete?.call();
        return false; // 실제 dismiss는 provider 갱신 후 자동으로 처리
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_rounded, color: Color(0xFFFF6B6B), size: 20),
      ),
      child: GestureDetector(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 5, color: Color(0xFFE8D5C4)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${meal.name}${meal.amount.isNotEmpty ? ' ${meal.amount}' : ''}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF3A2E2A)),
                ),
              ),
              Text(
                '${meal.calories} kcal',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF3A2E2A).withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 14, color: const Color(0xFF3A2E2A).withOpacity(0.25)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 저장된 식사 수정 다이얼로그 ──────────────────────────────────

class _SavedFoodEditDialog extends StatefulWidget {
  final Meal meal;
  const _SavedFoodEditDialog({required this.meal});

  @override
  State<_SavedFoodEditDialog> createState() => _SavedFoodEditDialogState();
}

class _SavedFoodEditDialogState extends State<_SavedFoodEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _weight;
  late final TextEditingController _kcal;
  late final TextEditingController _carb;
  late final TextEditingController _protein;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    final m = widget.meal;
    _name = TextEditingController(text: m.name);
    _weight = TextEditingController(text: m.weightG > 0 ? m.weightG.toStringAsFixed(0) : '');
    _kcal = TextEditingController(text: m.calories.toString());
    _carb = TextEditingController(text: m.carb.toString());
    _protein = TextEditingController(text: m.protein.toString());
    _fat = TextEditingController(text: m.fat.toString());
  }

  @override
  void dispose() {
    for (final c in [_name, _weight, _kcal, _carb, _protein, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('음식 수정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('음식 이름', _name),
            _field('중량 (g)', _weight, isNum: true),
            _field('칼로리 (kcal)', _kcal, isNum: true),
            _field('탄수화물 (g)', _carb, isNum: true),
            _field('단백질 (g)', _protein, isNum: true),
            _field('지방 (g)', _fat, isNum: true),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        TextButton(
          onPressed: () {
            final wg = double.tryParse(_weight.text) ?? 0.0;
            Navigator.pop(
              context,
              widget.meal.copyWith(
                name: _name.text.trim(),
                amount: wg > 0 ? '${wg.toInt()}g' : widget.meal.amount,
                weightG: wg,
                calories: int.tryParse(_kcal.text) ?? widget.meal.calories,
                carb: double.tryParse(_carb.text) ?? widget.meal.carb,
                protein: double.tryParse(_protein.text) ?? widget.meal.protein,
                fat: double.tryParse(_fat.text) ?? widget.meal.fat,
              ),
            );
          },
          child: const Text('저장', style: TextStyle(color: Color(0xFFF4A7B9), fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

// ── 사진 추가 버튼 ────────────────────────────────────────────

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4A7B9).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF4A7B9).withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: Color(0xFFF4A7B9), size: 22),
            SizedBox(width: 8),
            Text(
              '+ 사진으로 기록',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF4A7B9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 사진 선택 바텀시트 ──────────────────────────────────────

class _PhotoBottomSheet extends StatelessWidget {
  final void Function(String) onOptionSelected;
  const _PhotoBottomSheet({required this.onOptionSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5C4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '어떻게 기록할까요?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A2E2A),
                ),
              ),
              const SizedBox(height: 20),
              _BottomSheetOption(
                icon: Icons.camera_alt_rounded,
                label: '음식 사진 촬영',
                color: const Color(0xFFF4A7B9),
                onTap: () => onOptionSelected('camera'),
              ),
              const SizedBox(height: 10),
              _BottomSheetOption(
                icon: Icons.photo_library_rounded,
                label: '앨범에서 선택',
                color: const Color(0xFFFFD1A9),
                onTap: () => onOptionSelected('gallery'),
              ),
              const SizedBox(height: 10),
              _BottomSheetOption(
                icon: Icons.edit_rounded,
                label: '직접 입력',
                color: const Color(0xFFE8D5C4),
                onTap: () => onOptionSelected('manual'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A2E2A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI 분석 결과 바텀시트 ────────────────────────────────────

class _AnalysisBottomSheet extends ConsumerWidget {
  final Future<void> Function() onSave;
  final VoidCallback onClose;

  const _AnalysisBottomSheet({
    required this.onSave,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: state.value.when(
            loading: () => _LoadingContent(message: state.loadingMessage),
            error: (e, _) => _ErrorContent(
              message: '$e',
              onClose: onClose,
            ),
            data: (result) => _AnalysisContent(
              result: result,
              state: state,
              onSave: onSave,
              onClose: onClose,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 로딩 ─────────────────────────────────────────────────────

class _LoadingContent extends StatelessWidget {
  final String message;
  const _LoadingContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4A7B9)),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              message.isEmpty ? '잠시만 기다려주세요...' : message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF3A2E2A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 에러 ─────────────────────────────────────────────────────

class _ErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _ErrorContent({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😢', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF3A2E2A).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF4A7B9),
                side: const BorderSide(color: Color(0xFFF4A7B9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 분석 결과 컨텐츠 ─────────────────────────────────────────

class _AnalysisContent extends ConsumerWidget {
  final MealAnalysisResult result;
  final AnalysisState state;
  final Future<void> Function() onSave;
  final VoidCallback onClose;

  const _AnalysisContent({
    required this.result,
    required this.state,
    required this.onSave,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = result.meals;
    final totalCalories = items.fold(0, (s, m) => s + m.calories * m.quantity);
    final macro = items.fold(const MacroNutrient.zero(), (sum, m) => sum + m.macro);
    final isBusy = state.isBusy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 핸들바
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE8D5C4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 헤더: 쿠달이 메시지
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.kudalComment ?? '오늘 식단을 분석했어요!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A2E2A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 식사 타입 선택
        const _MealTypeSelector(),
        const SizedBox(height: 14),

        // 식사 목록 (스크롤 가능)
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.35,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length + 1, // +1 for add button
            itemBuilder: (ctx, i) {
              if (i == items.length) {
                return _AddFoodButton(
                  enabled: !isBusy,
                  onAdd: (meal) =>
                      ref.read(analysisProvider.notifier).addMeal(meal),
                );
              }
              return _AnalysisFoodCard(
                meal: items[i],
                enabled: !isBusy,
                onIncrement: () =>
                    ref.read(analysisProvider.notifier).updateQuantity(i, 1),
                onDecrement: () =>
                    ref.read(analysisProvider.notifier).updateQuantity(i, -1),
                onDelete: () =>
                    ref.read(analysisProvider.notifier).deleteMeal(i),
                onEdit: (updated) =>
                    ref.read(analysisProvider.notifier).updateMeal(i, updated),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // 합계 행
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4A7B9).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 $totalCalories kcal',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF4A7B9),
                ),
              ),
              Row(
                children: [
                  _MacroChip(
                    label: '탄 ${macro.carb.toInt()}g',
                    color: const Color(0xFFFFD1A9),
                  ),
                  const SizedBox(width: 5),
                  _MacroChip(
                    label: '단 ${macro.protein.toInt()}g',
                    color: const Color(0xFFF4A7B9),
                  ),
                  const SizedBox(width: 5),
                  _MacroChip(
                    label: '지 ${macro.fat.toInt()}g',
                    color: const Color(0xFFE8D5C4),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 버튼 행
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF4A7B9),
                  side: const BorderSide(color: Color(0xFFF4A7B9)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('다시 분석',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (isBusy || items.isEmpty) ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4A7B9),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFF4A7B9).withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('저장하기',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 식사 타입 선택기 ─────────────────────────────────────────

class _MealTypeSelector extends ConsumerWidget {
  const _MealTypeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType =
        ref.watch(analysisProvider.select((s) => s.mealType));

    return Row(
      children: MealType.values.map((type) {
        final isSelected = type == selectedType;
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                ref.read(analysisProvider.notifier).setMealType(type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF4A7B9)
                    : const Color(0xFFF4A7B9).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF4A7B9)
                      : const Color(0xFFE8D5C4),
                ),
              ),
              child: Column(
                children: [
                  Text(type.emoji,
                      style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF3A2E2A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 분석 음식 카드 ────────────────────────────────────────────

class _AnalysisFoodCard extends StatelessWidget {
  final Meal meal;
  final bool enabled;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final void Function(Meal) onEdit;

  const _AnalysisFoodCard({
    required this.meal,
    required this.enabled,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    required this.onEdit,
  });

  void _openEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _FoodEditDialog(
        meal: meal,
        onConfirm: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D5C4)),
      ),
      child: Row(
        children: [
          // 수정 버튼
          GestureDetector(
            onTap: enabled ? () => _openEditDialog(context) : null,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5C4).withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 14, color: Color(0xFF3A2E2A)),
            ),
          ),
          const SizedBox(width: 8),

          // 음식 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A2E2A),
                  ),
                ),
                Text(
                  '${meal.amount}  •  ${meal.calories} kcal',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF3A2E2A).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // 수량
          _CounterButton(
            icon: Icons.remove_rounded,
            onTap: enabled ? onDecrement : null,
            dimmed: meal.quantity <= 1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${meal.quantity}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3A2E2A),
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add_rounded,
            onTap: enabled ? onIncrement : null,
          ),
          const SizedBox(width: 6),

          // 삭제 버튼
          GestureDetector(
            onTap: enabled ? onDelete : null,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool dimmed;

  const _CounterButton({
    required this.icon,
    this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = dimmed
        ? const Color(0xFFF4A7B9).withOpacity(0.3)
        : const Color(0xFFF4A7B9);
    return GestureDetector(
      onTap: dimmed ? null : onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ── 음식 추가 버튼 ────────────────────────────────────────────

class _AddFoodButton extends StatelessWidget {
  final bool enabled;
  final void Function(Meal) onAdd;

  const _AddFoodButton({
    required this.enabled,
    required this.onAdd,
  });

  void _openAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _FoodEditDialog(
        meal: null,
        onConfirm: onAdd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => _openAddDialog(context) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8D5C4).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8D5C4).withOpacity(0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 16, color: Color(0xFF3A2E2A)),
            SizedBox(width: 6),
            Text(
              '음식 추가',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A2E2A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 음식 수정/추가 다이얼로그 ────────────────────────────────

class _FoodEditDialog extends StatefulWidget {
  final Meal? meal; // null = 추가 모드
  final void Function(Meal) onConfirm;

  const _FoodEditDialog({required this.meal, required this.onConfirm});

  @override
  State<_FoodEditDialog> createState() => _FoodEditDialogState();
}

class _FoodEditDialogState extends State<_FoodEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _weight;
  late final TextEditingController _kcal;
  late final TextEditingController _carb;
  late final TextEditingController _protein;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    final m = widget.meal;
    _name = TextEditingController(text: m?.name ?? '');
    _weight = TextEditingController(
      text: m != null && m.weightG > 0 ? m.weightG.toInt().toString() : '',
    );
    _kcal = TextEditingController(text: m != null ? '${m.calories}' : '');
    _carb = TextEditingController(
      text: m != null ? m.carb.toStringAsFixed(1) : '',
    );
    _protein = TextEditingController(
      text: m != null ? m.protein.toStringAsFixed(1) : '',
    );
    _fat = TextEditingController(
      text: m != null ? m.fat.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _kcal.dispose();
    _carb.dispose();
    _protein.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final wg = double.tryParse(_weight.text) ?? 0.0;
    final kcal = int.tryParse(_kcal.text) ?? 0;
    final carb = double.tryParse(_carb.text) ?? 0.0;
    final protein = double.tryParse(_protein.text) ?? 0.0;
    final fat = double.tryParse(_fat.text) ?? 0.0;

    final meal = Meal(
      id: widget.meal?.id ??
          'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      amount: wg > 0 ? '${wg.toInt()}g' : '',
      weightG: wg,
      calories: kcal,
      carb: carb,
      protein: protein,
      fat: fat,
      quantity: widget.meal?.quantity ?? 1,
    );
    widget.onConfirm(meal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.meal == null ? '음식 추가' : '음식 수정',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3A2E2A),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Field(label: '음식명', ctrl: _name),
              _Field(
                label: '중량 (g)',
                ctrl: _weight,
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
              _Field(
                label: '칼로리 (kcal)',
                ctrl: _kcal,
                inputType: TextInputType.number,
              ),
              _Field(
                label: '탄수화물 (g)',
                ctrl: _carb,
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
              _Field(
                label: '단백질 (g)',
                ctrl: _protein,
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
              _Field(
                label: '지방 (g)',
                ctrl: _fat,
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '취소',
            style: TextStyle(
              color: const Color(0xFF3A2E2A).withOpacity(0.5),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF4A7B9),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('확인',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final TextInputType inputType;

  const _Field({
    required this.label,
    required this.ctrl,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: inputType,
        inputFormatters: inputType == TextInputType.text
            ? []
            : [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        style: const TextStyle(fontSize: 14, color: Color(0xFF3A2E2A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: const Color(0xFF3A2E2A).withOpacity(0.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE8D5C4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE8D5C4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF4A7B9)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

// ── 매크로 칩 ─────────────────────────────────────────────────

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3A2E2A).withOpacity(0.8),
        ),
      ),
    );
  }
}
