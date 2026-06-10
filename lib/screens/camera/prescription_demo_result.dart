import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PrescriptionDemoResultScreen extends StatelessWidget {
  const PrescriptionDemoResultScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  static const _items = [
    _PrescriptionDemoItem(name: '레세티갈정', detail: '항히스타민제 | 1정 | 1일 1회 | 저녁 식후'),
    _PrescriptionDemoItem(name: '코푸정', detail: '진해거담제 | 1정 | 1일 1회 | 저녁 식후'),
    _PrescriptionDemoItem(
      name: '휴온시메티딘정',
      detail: '위산분비억제제 | 1정 | 1일 1회 | 저녁 식후',
    ),
    _PrescriptionDemoItem(
      name: '부로멜라장용정',
      detail: '효소제 | 1정 | 1일 2회 | 아침 · 저녁 식후',
    ),
    _PrescriptionDemoItem(
      name: '종근당세파클러캡슐',
      detail: '항생제 | 1캡슐 | 1일 3회 | 아침 · 점심 · 저녁 식후',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '인식 결과',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          children: [
            const _SuccessMark(),
            const SizedBox(height: 26),
            const Text(
              '분석이 완료되었습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '사진 속 약 후보를 찾았습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 36),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                imageBytes,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 38),
            const Text(
              '식별된 약 후보',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            for (final item in _items) ...[
              _PrescriptionCard(item: item),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('나의 약장에 추가'),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: AppColors.primary,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 86,
        height: 86,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.primary,
          size: 48,
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.item});

  final _PrescriptionDemoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: Color(0xFF71798C), size: 28),
        ],
      ),
    );
  }
}

class _PrescriptionDemoItem {
  const _PrescriptionDemoItem({required this.name, required this.detail});

  final String name;
  final String detail;
}
