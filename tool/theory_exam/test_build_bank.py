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
    def test_filters_video_category_and_duplicates(self):
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
        self.assertEqual([q['id'] for q in questions], [2, 4])
        self.assertEqual(questions[0]['text'], 'Pytanie?')
        self.assertEqual(questions[0]['answers'], ['TAK', 'NIE'])
        self.assertEqual(questions[0]['media'], 'foto.jpg')
        self.assertEqual(questions[1]['part'], 'specialist')
        self.assertEqual(questions[1]['points'], 2)
        self.assertEqual(questions[1]['answers'], ['a', 'b', 'c'])
        self.assertEqual(questions[1]['correct'], 2)
        self.assertEqual(report['video_skipped'], 1)
        self.assertEqual(report['duplicates'], [2])

    def test_invalid_rows_are_reported_not_kept(self):
        rows = [HEADER, row(5, points='7'), row(6, correct='')]
        questions, report = bb.select_questions(rows)
        self.assertEqual(questions, [])
        self.assertEqual(sorted(report['invalid']), [5, 6])


if __name__ == '__main__':
    unittest.main()
