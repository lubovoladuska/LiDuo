import 'package:flutter_test/flutter_test.dart';
import 'package:liduo/core/utils/kazakh_phonetics.dart';

void main() {
  group('KazakhPhonetics', () {
    test('normalize removes punctuation and extra spaces', () {
      expect(
        KazakhPhonetics.normalize('  Сәлем,   әлем!  '),
        equals('сәлем әлем'),
      );
    });

    test('exact match returns 1.0 similarity', () {
      expect(
        KazakhPhonetics.similarity('Рахмет', 'рахмет'),
        equals(1.0),
      );
    });

    test('phonetic skeleton normalizes specific Kazakh characters', () {
      expect(
        KazakhPhonetics.toPhoneticSkeleton('Қазақстан'),
        equals('казакстан'),
      );
      expect(
        KazakhPhonetics.toPhoneticSkeleton('Сәлеметсіз бе'),
        equals('салеметсиз бе'),
      );
    });

    test('matches phrase despite typical STT cyrillic fallback', () {
      // Когда STT возвращает русскую 'а' вместо 'ә' и 'к' вместо 'қ'
      const spokenByStt = 'Салеметсиз бе, калын калай';
      const targetKazakh = 'Сәлеметсіз бе, қалың қалай';

      expect(
        KazakhPhonetics.isMatch(spokenByStt, targetKazakh),
        isTrue,
      );
    });

    test('rejects completely different phrase', () {
      const spoken = 'Мен дүкенге барамын';
      const target = 'Бүгін ауа райы жақсы';

      expect(
        KazakhPhonetics.isMatch(spoken, target),
        isFalse,
      );
    });

    test('handles empty inputs safely', () {
      expect(KazakhPhonetics.similarity('', ''), equals(1.0));
      expect(KazakhPhonetics.similarity('сәлем', ''), equals(0.0));
    });
  });
}
