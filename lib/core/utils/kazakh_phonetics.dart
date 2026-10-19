import 'dart:math';

/// Утилита для фонетического анализа, нормализации и нечеткого сравнения
/// казахской устной речи при распознавании с микрофона (STT).
class KazakhPhonetics {
  /// Словарь фонетических соответствий специфических звуков казахского языка
  /// распространенным заменам в стандартном (или ненастроенном) системном STT.
  static const Map<String, String> _phoneticEquivalents = {
    'ә': 'а',
    'і': 'и',
    'ң': 'н',
    'ғ': 'г',
    'ү': 'у',
    'ұ': 'у',
    'қ': 'к',
    'ө': 'о',
    'һ': 'х',
    'h': 'х',
  };

  /// Очистка текста от пунктуации, лишних пробелов и приведение к нижнему регистру
  static String normalize(String text) {
    if (text.isEmpty) return '';
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0400-\u04FF]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Фонетическая свертка текста (замена казахских специфических букв на базовые аналоги)
  /// для мягкого сопоставления речи при ошибках системного STT.
  static String toPhoneticSkeleton(String text) {
    final normalized = normalize(text);
    final buffer = StringBuffer();
    for (int i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      buffer.write(_phoneticEquivalents[char] ?? char);
    }
    return buffer.toString();
  }

  /// Расстояние Левенштейна между двумя строками
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(
          v1[j] + 1, // вставка
          min(
            v0[j + 1] + 1, // удаление
            v0[j] + cost, // замена
          ),
        );
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

  /// Коэффициент сходства строк от 0.0 (полное несовпадение) до 1.0 (идеальное совпадение)
  static double similarity(String s1, String s2) {
    final norm1 = normalize(s1);
    final norm2 = normalize(s2);

    if (norm1.isEmpty && norm2.isEmpty) return 1.0;
    if (norm1.isEmpty || norm2.isEmpty) return 0.0;
    if (norm1 == norm2) return 1.0;

    // Сначала прямое сравнение
    final directDistance = levenshteinDistance(norm1, norm2);
    final maxLen = max(norm1.length, norm2.length);
    final directScore = 1.0 - (directDistance / maxLen);

    // Затем фонетическое сравнение (со сверткой специфических фонем)
    final skel1 = toPhoneticSkeleton(norm1);
    final skel2 = toPhoneticSkeleton(norm2);
    final skelDistance = levenshteinDistance(skel1, skel2);
    final maxSkelLen = max(skel1.length, skel2.length);
    final skelScore = 1.0 - (skelDistance / maxSkelLen);

    // Возвращаем максимальный балл (если распознаватель просто заменил ә на а или қ на к)
    return max(directScore, skelScore);
  }

  /// Проверка, признается ли произнесенная фраза успешной
  /// (по умолчанию порог 0.72 дает комфортную погрешность микрофона без потери смысла)
  static bool isMatch(String spoken, String target, {double threshold = 0.72}) {
    return similarity(spoken, target) >= threshold;
  }
}
