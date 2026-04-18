import 'package:flutter/material.dart';

class AnalysisResult extends StatelessWidget {
  final bool isDanger = true; 

  const AnalysisResult({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('분석 결과', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 상태 요약 카드 (위험 / 안전)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Text('분석 완료', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDanger ? Icons.warning_rounded : Icons.check_circle_rounded,
                          color: isDanger ? Colors.redAccent : Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDanger ? '위험 (Danger)' : '안전 (Safe)',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDanger ? Colors.redAccent : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isDanger ? '함께 드시면 안 되는 조합이 있습니다.' : '함께 드셔도 안전합니다.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. 상세 설명 카드 (상극 성분 발견)
            if (isDanger) 
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('상극 성분 발견', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '홍삼(영양제)과 메트포르민(당뇨약)을 함께 복용 시, 저혈당 위험이 높아질 수 있습니다.',
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            
            const Spacer(),
            
            // 3. 하단 경고 문구
            Center(
              child: Text(
                '최종 판단은 반드시 의사 또는 약사와 상담하십시오.',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}