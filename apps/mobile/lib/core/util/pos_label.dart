/// 词性标签工具 —— 从 translation 字段提取词性缩写并映射为中文标签。
///
/// 之前重复实现在 `features/study/study_page.dart` 和
/// `spec/pages/spec_review_page.dart`，统计页雷达图也需要复用，
/// 故提到此处单文件管理。

/// 标准词性映射表。`startsWith` 匹配，按 map 遍历顺序检查。
/// 注意 `vt.` / `vi.` 必须排在 `v.` 前，`adj.` 排在 `a.` 前后无所谓
/// 因为 startsWith 互不冲突。
const Map<String, String> kPosMap = {
  'vt.': '及物动词',
  'vi.': '不及物动词',
  'v.': '动词',
  'n.': '名词',
  'adj.': '形容词',
  'a.': '形容词',
  'adv.': '副词',
  'prep.': '介词',
  'conj.': '连词',
  'pron.': '代词',
  'num.': '数词',
  'int.': '感叹词',
  'art.': '冠词',
};

/// 从 translation 中提取首行非空文本，去除前后空白返回。
List<String> translationLines(String? translation) {
  if (translation == null || translation.trim().isEmpty) return const [];
  return translation
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

/// 从 [translation] 提取首个词性缩写并映射为中文标签。
/// 找不到时返回空串。
String posLabel(String? translation) {
  if (translation == null || translation.isEmpty) return '';
  final first = translationLines(translation).firstOrNull ?? '';
  for (final entry in kPosMap.entries) {
    if (first.startsWith(entry.key)) return entry.value;
  }
  return '';
}

/// 雷达图 4 大类词性分类。雷达图只画名/动/形/副 4 项，
/// 把 `_posLabel` 的细粒度（及物动词/不及物动词等）合并到大类。
enum PosCategory { noun, verb, adj, adv, other }

/// 把 [translation] 分类到 4 大词性桶之一（其它 → [PosCategory.other]）。
PosCategory posCategoryOf(String? translation) {
  if (translation == null || translation.isEmpty) return PosCategory.other;
  final first = translationLines(translation).firstOrNull ?? '';
  // 注意顺序：长前缀 (vt./vi./adj./adv.) 必须先匹配，避免被短前缀 (v./a.) 误吃
  if (first.startsWith('vt.') ||
      first.startsWith('vi.') ||
      first.startsWith('v.')) return PosCategory.verb;
  if (first.startsWith('adv.')) return PosCategory.adv;
  if (first.startsWith('adj.') || first.startsWith('a.')) return PosCategory.adj;
  if (first.startsWith('n.')) return PosCategory.noun;
  return PosCategory.other;
}
