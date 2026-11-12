"""Builds Drivio's category B theory question bank from the official
Ministry of Infrastructure catalogue.

Usage:
  python tool/theory_exam/build_bank.py --xlsx KATALOG.xlsx \
      --zip multimedia_do_pytan.zip --zip multimedia_cz2.zip \
      --out assets/theory_exam

Keeps category B questions without video (.wmv), converts their pictures to
WebP (max 1080 px wide) and writes questions_b.json. Source files stay
outside the repository; see README.md.
"""

import argparse
import datetime as dt
import io
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
import zipfile

SOURCE_VERSION = '2026-07'
MAX_WIDTH = 1080
WEBP_QUALITY = 75
IMAGE_EXTENSIONS = ('.jpg', '.jpeg', '.png')

_NS = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}

# Column indexes in the catalogue sheet.
COL_ID, COL_TEXT, COL_A, COL_B, COL_C = 1, 2, 3, 4, 5
COL_CORRECT, COL_MEDIA, COL_PART, COL_POINTS, COL_CATS = 6, 7, 8, 9, 10


def normalize_part(value):
    """Maps 'Zakres struktury' (with the catalogue's typos) to basic/specialist."""
    v = (value or '').strip().lower()
    if v.startswith('pod'):
        return 'basic'
    if v.startswith('spe'):
        return 'specialist'
    return None


def is_category_b(categories):
    return 'B' in [c.strip() for c in (categories or '').split(',')]


def correct_index(value, part):
    v = (value or '').strip().upper()
    mapping = {'T': 0, 'N': 1} if part == 'basic' else {'A': 0, 'B': 1, 'C': 2}
    return mapping.get(v)


def select_questions(rows):
    """Returns (questions, report) for category B rows without video.

    Each question: id, text, part, points, answers, correct, media (source
    file name or ''). The first occurrence of a duplicated id wins.
    """
    report = {'video_skipped': 0, 'duplicates': [], 'invalid': []}
    questions = []
    seen = set()
    for r in rows[1:]:
        if not r or len(r) <= COL_CATS:
            continue
        if not is_category_b(r[COL_CATS]):
            continue
        media = r[COL_MEDIA].strip()
        if media.lower().endswith('.wmv'):
            report['video_skipped'] += 1
            continue
        try:
            qid = int(str(r[COL_ID]).strip())
        except ValueError:
            continue
        if qid in seen:
            report['duplicates'].append(qid)
            continue
        part = normalize_part(r[COL_PART])
        points = str(r[COL_POINTS]).strip()
        correct = correct_index(r[COL_CORRECT], part)
        text = ' '.join(r[COL_TEXT].split())
        if part == 'basic':
            answers = ['TAK', 'NIE']
        else:
            answers = [' '.join(r[i].split()) for i in (COL_A, COL_B, COL_C)]
        if (part is None or points not in ('1', '2', '3') or correct is None
                or not text or not all(answers)):
            report['invalid'].append(qid)
            continue
        seen.add(qid)
        questions.append({
            'id': qid,
            'text': text,
            'part': part,
            'points': int(points),
            'answers': answers,
            'correct': correct,
            'media': media,
        })
    return questions, report


def read_xlsx_rows(path):
    """Reads the first sheet of an .xlsx file into lists of strings."""
    with zipfile.ZipFile(path) as z:
        shared = []
        if 'xl/sharedStrings.xml' in z.namelist():
            root = ET.fromstring(z.read('xl/sharedStrings.xml'))
            for si in root.findall('m:si', _NS):
                shared.append(''.join(
                    t.text or '' for t in si.iter('{%s}t' % _NS['m'])))
        sheet = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows = []
    for row in sheet.iter('{%s}row' % _NS['m']):
        values = {}
        for c in row.findall('m:c', _NS):
            col = 0
            for ch in re.match(r'[A-Z]+', c.get('r')).group():
                col = col * 26 + ord(ch) - 64
            kind = c.get('t')
            if kind == 'inlineStr':
                val = ''.join(x.text or '' for x in c.iter('{%s}t' % _NS['m']))
            else:
                v = c.find('m:v', _NS)
                if v is None:
                    continue
                val = shared[int(v.text)] if kind == 's' else v.text
            values[col - 1] = val
        rows.append([values.get(i, '') for i in range(max(values) + 1)]
                    if values else [])
    return rows


def index_archives(paths):
    """Maps lower-case image file names to (archive, member) pairs."""
    index = {}
    archives = [zipfile.ZipFile(p) for p in paths]
    for archive in archives:
        for info in archive.infolist():
            name = os.path.basename(info.filename).lower()
            if name.endswith(IMAGE_EXTENSIONS):
                index.setdefault(name, (archive, info.filename))
    return index


def convert_image(data, target):
    from PIL import Image  # Imported lazily so the unit tests need no Pillow.

    with Image.open(io.BytesIO(data)) as img:
        img = img.convert('RGB')
        if img.width > MAX_WIDTH:
            height = round(img.height * MAX_WIDTH / img.width)
            img = img.resize((MAX_WIDTH, height), Image.LANCZOS)
        img.save(target, 'WEBP', quality=WEBP_QUALITY, method=6)


def build(xlsx, zips, out):
    questions, report = select_questions(read_xlsx_rows(xlsx))
    img_dir = os.path.join(out, 'img')
    os.makedirs(img_dir, exist_ok=True)
    index = index_archives(zips)
    kept, missing = [], []
    for q in questions:
        media = q.pop('media')
        q['image'] = None
        if media:
            entry = index.get(os.path.basename(media).lower())
            if entry is None:
                missing.append(q['id'])
                continue
            archive, member = entry
            target = os.path.join(img_dir, '%d.webp' % q['id'])
            convert_image(archive.read(member), target)
            q['image'] = 'assets/theory_exam/img/%d.webp' % q['id']
        kept.append(q)
    kept.sort(key=lambda q: q['id'])
    bank = {
        'sourceVersion': SOURCE_VERSION,
        'generatedAt': dt.datetime.now(dt.timezone.utc).isoformat(
            timespec='seconds'),
        'questions': kept,
    }
    with open(os.path.join(out, 'questions_b.json'), 'w',
              encoding='utf-8') as f:
        json.dump(bank, f, ensure_ascii=False, separators=(',', ':'))

    groups = {}
    for q in kept:
        key = '%s/%d' % (q['part'], q['points'])
        groups[key] = groups.get(key, 0) + 1
    image_bytes = sum(os.path.getsize(os.path.join(img_dir, f))
                      for f in os.listdir(img_dir))
    print('questions kept:', len(kept))
    print('with image:', sum(1 for q in kept if q['image']))
    print('groups:', dict(sorted(groups.items())))
    print('video skipped:', report['video_skipped'])
    print('duplicates skipped:', report['duplicates'])
    print('invalid skipped:', report['invalid'])
    print('missing image skipped:', missing)
    print('images MB: %.1f' % (image_bytes / 1e6))


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('--xlsx', required=True)
    parser.add_argument('--zip', action='append', required=True)
    parser.add_argument('--out', default='assets/theory_exam')
    args = parser.parse_args(argv)
    build(args.xlsx, args.zip, args.out)


if __name__ == '__main__':
    main(sys.argv[1:])
