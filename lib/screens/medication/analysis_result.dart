import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/interaction_api.dart';

class AnalysisResult extends StatefulWidget {
  const AnalysisResult({super.key});

  @override
  State<AnalysisResult> createState() => _AnalysisResultState();
}

class _AnalysisResultState extends State<AnalysisResult> {
  final InteractionApi _interactionApi = InteractionApi();
  bool _isLoading = true;
  AiInteractionAnalysis? _analysis;
  String? _errorMessage;

  bool get isDanger {
    final risk = _analysis?.riskLevel;
    return risk == 'DANGER' || risk == 'WARNING' || risk == 'CAUTION';
  }

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final analysis = await _interactionApi.analyzeMyCabinetWithAi();
      if (mounted) {
        setState(() => _analysis = analysis);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('분석 결과', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 상태 요약 카드 (위험 / 안전)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          Text(
                            '분석 완료',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDanger
                                    ? Icons.warning_rounded
                                    : Icons.check_circle_rounded,
                                color: isDanger
                                    ? Colors.redAccent
                                    : Colors.green,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDanger ? '위험 (Danger)' : '안전 (Safe)',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDanger
                                      ? Colors.redAccent
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage ??
                                analysis?.summary ??
                                (isDanger
                                    ? '함께 드시면 안 되는 조합이 있습니다.'
                                    : '함께 드셔도 안전합니다.'),
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '상극 성분 발견',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              analysis?.warnings.isNotEmpty == true
                                  ? analysis!.warnings
                                        .map(
                                          (warning) =>
                                              warning.reason ??
                                              warning.title ??
                                              '',
                                        )
                                        .where((text) => text.isNotEmpty)
                                        .join('\n')
                                  : '상호작용 주의 항목이 확인되었습니다.',
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
