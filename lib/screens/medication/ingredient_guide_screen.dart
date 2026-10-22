import 'package:flutter/material.dart';
import '../../services/ingredient_guide_api.dart';

class IngredientGuideScreen extends StatefulWidget {
  final IngredientGuideApi? api;
  const IngredientGuideScreen({super.key, this.api});

  @override
  State<IngredientGuideScreen> createState() => _IngredientGuideScreenState();
}

class _IngredientGuideScreenState extends State<IngredientGuideScreen> {
  late final IngredientGuideApi _api;
  final _search = TextEditingController();
  List<IngredientGuideEntry> _entries = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? IngredientGuideApi();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final entries = await _api.getGuides();
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _entries
        .where((entry) => entry.matches(_search.text))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('성분 가이드')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '선정된 5개 성분의 일반 주의사항입니다. 개인의 복용 위험을 판정하지 않으며, 처방·제품 설명서를 함께 확인하세요.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '성분명·별칭 검색',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _failed
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('성분 가이드를 불러오지 못했습니다.'),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                  ? const Center(
                      child: Text(
                        '일치하는 가이드가 없습니다.\n가이드가 없다고 안전함을 의미하지는 않습니다.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final guide = filtered[index].guide;
                        return Card(
                          child: ExpansionTile(
                            key: ValueKey(guide.code),
                            title: Text(guide.ingredientName),
                            subtitle: Text(guide.title),
                            childrenPadding: const EdgeInsets.all(16),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                guide.summary,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(guide.detail),
                              const SizedBox(height: 12),
                              SelectableText(
                                '출처: ${guide.sourceName}\n${guide.sourceUrl}\n자료 확인일: ${guide.reviewedAt}',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
