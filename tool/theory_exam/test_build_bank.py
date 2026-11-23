"""Tests for build_bank.py. Run: python -I tool/theory_exam/test_build_bank.py"""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_bank as bb  # noqa: E402

HEADER = [
    'Lp', 'Numer pytania', 'Pytanie', 'Odpowiedź A', 'Odpowiedź B',
    'Odpowiedź C', 'Poprawna odp', 'Media', 'Zakres struktury',
    'Liczba punktów', 'Kategorie',
]


def row(num, *, text='Pytanie?', a='', b='', c='', correct='T', media='',
        part='PODSTAWOWY', points='3', cats='A,B,C'):
    return ['1', str(num), text, a, b, c, correct, media, part, points, cats]


class NormalizeTest(unittest.TestCase):
    def test_part_typos_and_case(self):
        self.assertEqual(bb.normalize_part('Specajlistyczny '), 'specialist')
        self.assertEqual(bb.normalize_part('Specjalistyczny'), 'specialist')
        self.assertEqual(bb.normalize_part('PODSTAWOWY'), 'basic')
        self.assertEqual(bb.normalize_part('Podstawowy'), 'basic')
        self.assertIsNone(bb.normalize_part(''))

    def test_category_b_is_exact_token(self):
        self.assertTrue(bb.is_category_b('A,B,C'))
        self.assertTrue(bb.is_category_b(' B '))
        self.assertFalse(bb.is_category_b('B1'))
        self.assertFalse(bb.is_category_b('A,B1,C1'))

    def test_correct_index(self):
        self.assertEqual(bb.correct_index('T', 'basic'), 0)
        self.assertEqual(bb.correct_index('N', 'basic'), 1)
        self.assertEqual(bb.correct_index('A', 'specialist'), 0)
        self.assertEqual(bb.correct_index('B', 'specialist'), 1)
        self.assertEqual(bb.correct_index('c', 'specialist'), 2)
        self.assertIsNone(bb.correct_index('X', 'specialist'))


class SelectTest(unittest.TestCase):
    def test_keeps_video_and_filters_category_and_duplicates(self):
        rows = [
            HEADER,
            row(1, media='film.wmv'),
            row(2, media='foto.jpg'),
            row(3, cats='A,B1'),
            row(2, text='duplikat'),
            row(4, part='Specajlistyczny', points='2', correct='C',
                a='a', b='b', c='c'),
            [],
        ]
        questions, report = bb.select_questions(rows)
        self.assertEqual([q['id'] for q in questions], [1, 2, 4])
        self.assertEqual(questions[0]['media'], 'film.wmv')
        self.assertEqual(questions[1]['text'], 'Pytanie?')
        self.assertEqual(questions[1]['answers'], ['TAK', 'NIE'])
        self.assertEqual(questions[1]['media'], 'foto.jpg')
        self.assertEqual(questions[2]['part'], 'specialist')
        self.assertEqual(questions[2]['points'], 2)
        self.assertEqual(questions[2]['answers'], ['a', 'b', 'c'])
        self.assertEqual(questions[2]['correct'], 2)
        self.assertEqual(report['duplicates'], [2])

    def test_invalid_rows_are_reported_not_kept(self):
        rows = [HEADER, row(5, points='7'), row(6, correct='')]
        questions, report = bb.select_questions(rows)
        self.assertEqual(questions, [])
        self.assertEqual(sorted(report['invalid']), [5, 6])


class TopicTest(unittest.TestCase):
    def check(self, topic, text, answers=()):
        self.assertEqual(bb.classify_topic(text, list(answers)), topic, text)

    def test_real_catalogue_questions(self):
        self.check('parking', 'Czy wolno Ci zaparkować pojazd w tej zatoce?')
        self.check('priority', 'Zamierzasz skręcić w lewo. Czy masz obowiązek '
                   'ustąpić pierwszeństwa pojazdowi nadjeżdżającemu z prawej strony?')
        self.check('railway', 'Czy w tej sytuacji wolno Ci wjechać na przejazd kolejowy?')
        self.check('first_aid', 'Czy w tej sytuacji masz obowiązek udzielić '
                   'niezbędnej pomocy ofierze wypadku?')
        self.check('vehicle', 'Za które naruszenie przepisów ruchu drogowego '
                   'policjant zatrzyma prawo jazdy?')
        self.check('vehicle', 'Jaką funkcję spełnia system przeciwblokujący (ABS)?')
        self.check('conditions', 'Kiedy masz obowiązek wyłączyć tylne światła przeciwmgłowe?')
        self.check('signs', 'Czy ten znak ostrzega o niebezpieczeństwie?')
        self.check('speed', 'Czy w przedstawionej sytuacji należy rozpocząć hamowanie pojazdu?')
        self.check('general', 'Czy w tej sytuacji masz obowiązek zachować szczególną ostrożność?')

    def test_word_starts_only(self):
        # 'kolejności' is not about railways, 'pomocy' is not about the night.
        self.check('vehicle', 'W jakiej kolejności wykonasz czynności przed jazdą?',
                   ['Ustawić fotel, lusterka i zapiąć pasy bezpieczeństwa.'])
        self.assertNotEqual(bb.classify_topic('Czy wezwiesz pomocy?', []), 'conditions')

    def test_answers_only_when_the_question_says_nothing(self):
        self.check('speed', 'Prędkość bezpieczna to prędkość :',
                   ['Po spożyciu alkoholu.', 'b', 'c'])
        self.check('alcohol', 'Która z czynności jest niedozwolona?',
                   ['Prowadzenie po spożyciu alkoholu.', 'b', 'c'])

    def test_every_topic_is_known(self):
        self.assertEqual(set(bb.TOPICS), {
            'priority', 'overtaking', 'pedestrians', 'speed', 'parking', 'signs',
            'vehicle', 'general', 'railway', 'conditions', 'first_aid', 'motorway',
            'alcohol'})

    def test_selected_questions_get_a_topic(self):
        questions, _ = bb.select_questions(
            [HEADER, row(1, text='Czy wolno Ci zaparkować tutaj?')])
        self.assertEqual(questions[0]['topic'], 'parking')


class VideoTest(unittest.TestCase):
    def test_media_kind(self):
        self.assertEqual(bb.media_kind('Film 1.WMV'), 'video')
        self.assertEqual(bb.media_kind('a.jpeg'), 'image')
        self.assertIsNone(bb.media_kind(''))

    def test_same_source_gives_same_name_and_new_source_a_new_one(self):
        a = bb.video_name(b'wmv bytes')
        self.assertEqual(a, bb.video_name(b'wmv bytes'))
        self.assertNotEqual(a, bb.video_name(b'other bytes'))
        self.assertRegex(a, r'^[0-9a-f]{12}\.mp4$')

    def test_video_path_is_versioned(self):
        self.assertEqual(bb.video_storage_path('abc.mp4'),
                         'theory_exam/videos/2026-07/abc.mp4')

    def test_ffmpeg_args(self):
        args = bb.ffmpeg_args('in.wmv', 'out.part', has_audio=False)
        joined = ' '.join(args)
        for part in ('-c:v libx264', '-crf 26', '-pix_fmt yuv420p',
                     '+faststart', '-an', '-f mp4'):
            self.assertIn(part, joined)
        self.assertIn("scale='min(1024,iw)':-2", args)
        self.assertEqual(args[-1], 'out.part')
        with_audio = ' '.join(bb.ffmpeg_args('in.wmv', 'o', has_audio=True))
        self.assertNotIn('-an', with_audio)
        self.assertIn('-c:a aac', with_audio)
        self.assertIn('-ac 1', with_audio)
        self.assertIn('-b:a 64k', with_audio)


if __name__ == '__main__':
    unittest.main()
