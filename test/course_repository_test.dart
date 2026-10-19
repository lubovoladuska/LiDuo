import 'package:flutter_test/flutter_test.dart';
import 'package:liduo/data/repositories/course_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CourseRepository', () {
    test('procedural milestone lesson generated properly for higher days', () async {
      final lessonDay15 = await CourseRepository.instance.getLessonForDay(15);
      expect(lessonDay15.dayNumber, equals(15));
      expect(lessonDay15.drills.isNotEmpty, isTrue);
      expect(lessonDay15.title.contains('15'), isTrue);

      final lessonDay65 = await CourseRepository.instance.getLessonForDay(65);
      expect(lessonDay65.dayNumber, equals(65));
      expect(lessonDay65.drills.isNotEmpty, isTrue);
      expect(lessonDay65.title.contains('B1/B2'), isTrue);
    });
  });
}
