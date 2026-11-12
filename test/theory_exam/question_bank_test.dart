import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

const sampleBankJson = '''
{"sourceVersion":"2026-07","generatedAt":"2026-11-13T00:00:00+00:00",
 "questions":[
  {"id":7,"text":"Czy wolno?","part":"basic","points":3,
   "answers":["TAK","NIE"],"correct":1,"image":"assets/theory_exam/img/7.webp"},
  {"id":9,"text":"Który?","part":"specialist","points":2,
   "answers":["a","b","c"],"correct":2,"image":null}
 ]}
''';

void main() {
  test('parses questions from the bank JSON', () {
    final bank = QuestionBank.fromJsonString(sampleBankJson);

    expect(bank.sourceVersion, '2026-07');
    expect(bank.questions, hasLength(2));

    final basic = bank.byId(7);
    expect(basic.part, TheoryPart.basic);
    expect(basic.points, 3);
    expect(basic.answers, ['TAK', 'NIE']);
    expect(basic.correctIndex, 1);
    expect(basic.image, 'assets/theory_exam/img/7.webp');

    final specialist = bank.byId(9);
    expect(specialist.part, TheoryPart.specialist);
    expect(specialist.correctIndex, 2);
    expect(specialist.image, isNull);
  });
}
