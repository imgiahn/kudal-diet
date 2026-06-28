import 'package:flutter/material.dart';
import '../models/macro_nutrient.dart';

class MacroSummaryCard extends StatelessWidget {
  final MacroNutrient macro;

  const MacroSummaryCard({super.key, required this.macro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 영양',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A2E2A),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A7B9).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${macro.calories} kcal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF4A7B9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CalorieBar(
            label: '탄수화물',
            value: macro.carb,
            max: 150,
            color: const Color(0xFFFFD1A9),
            unit: 'g',
          ),
          const SizedBox(height: 10),
          _CalorieBar(
            label: '단백질',
            value: macro.protein,
            max: 120,
            color: const Color(0xFFF4A7B9),
            unit: 'g',
          ),
          const SizedBox(height: 10),
          _CalorieBar(
            label: '지방',
            value: macro.fat,
            max: 60,
            color: const Color(0xFFE8D5C4),
            unit: 'g',
          ),
        ],
      ),
    );
  }
}

class _CalorieBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String unit;

  const _CalorieBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3A2E2A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: const Color(0xFFF5F0EB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            '${value.toInt()}$unit',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A2E2A),
            ),
          ),
        ),
      ],
    );
  }
}
