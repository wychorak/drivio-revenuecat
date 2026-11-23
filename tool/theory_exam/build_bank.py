"""Builds Drivio's category B theory question bank from the official
Ministry of Infrastructure catalogue.

Usage:
  python tool/theory_exam/build_bank.py --xlsx KATALOG.xlsx \
      --zip multimedia_do_pytan.zip --zip multimedia_cz2.zip \
      --out assets/theory_exam

Keeps category B questions, converts their pictures to WebP (max 1080 px
wide) and writes questions_b.json. With --videos-out DIR it also transcodes
the .wmv videos to MP4 for Firebase Storage; without it, video questions are
left out. Source files and videos stay outside the repository; see README.md.
"""

import argparse
import concurrent.futures
import datetime as dt
import hashlib
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile

SOURCE_VERSION = '2026-07'
MAX_WIDTH = 1080
WEBP_QUALITY = 75
IMAGE_EXTENSIONS = ('.jpg', '.jpeg', '.png')
VIDEO_EXTENSIONS = ('.wmv',)
VIDEO_MAX_WIDTH = 1024
VIDEO_CRF = 26
VIDEO_PREFIX = 'theory_exam/videos/' + SOURCE_VERSION

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


def media_kind(name):
    n = (name or '').strip().lower()
    if n.endswith(VIDEO_EXTENSIONS):
        return 'video'
    if n.endswith(IMAGE_EXTENSIONS):
        return 'image'
    return None


def video_name(data):
    """Content-addressed MP4 name: one file per source video, and a changed
    source gets a new name so no device keeps a stale copy."""
    return hashlib.sha1(data).hexdigest()[:12] + '.mp4'


def video_storage_path(name):
    return VIDEO_PREFIX + '/' + name


def ffmpeg_args(src, dst, has_audio):
    args = [
        'ffmpeg', '-v', 'error', '-y', '-i', src,
        '-vf', "scale='min(%d,iw)':-2" % VIDEO_MAX_WIDTH,
        '-c:v', 'libx264', '-preset', 'slow', '-crf', str(VIDEO_CRF),
        '-pix_fmt', 'yuv420p',
    ]
    if has_audio:
        args += ['-c:a', 'aac', '-ac', '1', '-b:a', '64k']
    else:
        args += ['-an']
    return args + ['-movflags', '+faststart', '-f', 'mp4', dst]


def has_audio(path):
    out = subprocess.run(
        ['ffprobe', '-v', 'error', '-select_streams', 'a',
         '-show_entries', 'stream=index', '-of', 'csv=p=0', path],
        capture_output=True, text=True, check=True).stdout
    return bool(out.strip())


# Topics for learning by category. The catalogue has no topic column, so a
# question gets one from its wording: ordered keyword rules, first match wins,
# patterns match at word starts. Checked by hand on samples (about 90% right);
# a wrong topic only moves a question to another learning tile.
_TOPIC_PATTERNS = [
    ('first_aid', [
        r'\bpierwsz\w* pomoc', r'\bposzkodowan', r'\brann\w', r'\bresuscytac',
        r'\buciska\w* klatk', r'\bkrwotok', r'\bkrwawi', r'\boparzen', r'\bzłaman',
        r'\bnieprzytomn', r'\bwypad(ek|k)', r'\boddech', r'\boddycha',
        r'\bpozycj\w* bezpieczn', r'\bpogotowi', r'\bnumer\w* alarmow', r'\b112\b',
        r'\bmiejsc\w* zdarzeni', r'\bkolizj\w* drogow', r'\budziel', r'\bratown',
        r'\bdefibryl', r'\bbez pomocy', r'\bleżąc\w* osob', r'\bwezwa\w* pomoc',
        r'\bpłonąc']),
    ('alcohol', [
        r'\balkohol', r'\bnarkoty', r'\bamfetamin', r'\bodurzaj', r'\bdziałając\w* podobnie',
        r'\bleki?\b', r'\bleków\b', r'\bzmęcz', r'\bsenn', r'\bsen\b', r'\btrzeźw',
        r'\bzdrowi', r'\bchorob', r'\bemocj', r'\bstres', r'\bagres', r'\bczas\w* reakcji',
        r'\bkoncentr', r'\brozprosz', r'\btelefon', r'\bsłuchawk', r'\bmikrofon',
        r'\bnawigac', r'\bpalen\w* tytoniu', r'\bjedzen']),
    ('vehicle', [
        r'\bpraw\w* jazdy', r'\bmandat', r'\bpunkt\w* karn', r'\bgrzywn',
        r'\bkar(a|y|ę|ą)\b', r'\bkarn', r'\bodpowiedzialnoś', r'\bwykroczen',
        r'\bprzestęp', r'\bubezpiecz', r'\bdow(ód|odu|odem)\b', r'\bdokument',
        r'\bbadani\w* technicz', r'\brejestracyjn']),
    ('railway', [r'\bkolejow', r'\bkolej(e|i|ą)?\b', r'\bpociąg', r'\btramwaj',
                 r'\bszynow', r'\btorowisk', r'\bzapor', r'\brogatk']),
    ('motorway', [r'\bautostrad', r'\bekspresow']),
    ('speed', [r'\bprędkoś', r'\bkm/h', r'\bhamow', r'\bdrog\w* zatrzymania', r'\bodstęp',
               r'\bodległoś\w* od (poprzedzając|pojazd|jadąc)', r'\bdystans',
               r'\bszybciej', r'\bwolniej', r'\bprzyspiesz']),
    ('parking', [
        r'\bparkow', r'\bzaparkow', r'\bpost(ój|oju|ojow)',
        r'\b(wolno|możesz|prawo)( ci)? (się )?zatrzyma', r'\bprzed (jego )?opuszczeniem',
        r'\bunieruchom', r'\bcofa', r'\bcofni', r'\bzawraca', r'\bzawróci', r'\bkopert',
        r'\bkart\w* parkingow', r'\bwysiad', r'\bdrzwi\b', r'\bopuszcz\w* pojazd',
        r'\blini\w* przystankow', r'\bzatok']),
    ('pedestrians', [
        r'\bpiesz', r'\browerzyst', r'\browe(r|ru|rem|rze)\b', r'\bhulajnog',
        r'\btransportu osobistego', r'\bdzieci', r'\bdziecko', r'\bdzieck',
        r'\bniepełnospraw', r'\bbiał\w* lask', r'\bjeźdźc', r'\bzwierz', r'\bmotorower',
        r'\bzaprzęg', r'\bograniczonej sprawności', r'\bmotocykl', r'\bszkoln',
        r'\bstarsz\w* osob']),
    ('overtaking', [
        r'\bwyprzedz', r'\bwymij', r'\bomij', r'\bomin', r'\bpas\w* ruchu', r'\bpas\w* dla',
        r'\bzmian\w* pas', r'\bzmieni\w* pas', r'\bzjecha\w* w prawo', r'\bzajmowan\w* pas',
        r'\bprawym pas', r'\blewym pas', r'\bśrodkow\w* pas']),
    ('priority', [
        r'\bpierwszeństw', r'\bskrzyżowa', r'\bustąpi', r'\brond', r'\bruch\w* okrężn',
        r'\bwłącza\w* się do ruchu', r'\buprzywilejowan', r'\bskręca', r'\bskręci',
        r'\bskręt', r'\bjezdni\w* poprzeczn', r'\bnadjeżdżając', r'\bz prawej strony',
        r'\bz lewej strony', r'\bwjecha\w* na drog', r'\bwyjeżdża']),
    ('conditions', [
        r'\bświat(ł|eł)\w* (mijania|drogow|przeciwmgł|pozycyjn|awaryjn|do jazdy dziennej|cofania)',
        r'\breflektor', r'\bkierunkowskaz', r'\boświetl', r'\bmgł', r'\bmgle\b',
        r'\bnoc(y|ą)?\b', r'\bzmierzch', r'\bzmrok', r'\bwidoczno', r'\bolśni', r'\boślepi',
        r'\bdeszcz', r'\bopad', r'\bśnie(g|żn)', r'\boblodz', r'\bgołoledź', r'\bślisk',
        r'\bpoślizg', r'\bkolein', r'\bnawierzchn', r'\bwiatr', r'\bupał', r'\bzakręt',
        r'\bwzniesieni', r'\bstrom', r'\btunel', r'\bmost', r'\bwiadukt', r'\bpogod',
        r'\bszron', r'\bkałuż', r'\bszyb', r'\bliście']),
    ('signs', [
        r'\bznak', r'\bsygnał', r'\bsygnaliz', r'\btablic', r'\bkierując\w* ruchem',
        r'\bpolicjant', r'\blini[aię]\b', r'\blinii\b', r'\bliniam', r'\boznakow',
        r'\boznaczon', r'\bstrzałk', r'\bstref', r'\bostrzega', r'\bobszar\w* zabudowan',
        r'\bświatł', r'\bodblaskow']),
    ('vehicle', [
        r'\bwyposaż', r'\bapteczk', r'\bgaśnic', r'\btrójkąt', r'\bopon', r'\bhamulc',
        r'\bamortyz', r'\bolej', r'\bsilnik', r'\bakumulator', r'\bbieżnik', r'\blusterk',
        r'\bpas\w* bezpieczeństwa', r'\bfotelik', r'\bzagłów', r'\bprzewo', r'\bładun',
        r'\bprzyczep', r'\bholow', r'\bkontroln', r'\bekonomiczn', r'\bpaliw', r'\bemisj',
        r'\bekologi', r'\babs\b', r'\besp\b', r'\bpoduszk', r'\bkierownic', r'\bpolicj',
        r'\brejestr', r'\bsprawnoś', r'\busterk', r'\bawari', r'\bbagażnik', r'\bdach',
        r'\bkatalizator', r'\bspalin', r'\bśrodowisk']),
]
_TOPIC_RULES = [(t, re.compile('|'.join(p))) for t, p in _TOPIC_PATTERNS]
DEFAULT_TOPIC = 'general'
TOPICS = sorted({t for t, _ in _TOPIC_PATTERNS} | {DEFAULT_TOPIC})


def _match_topic(s):
    for topic, rx in _TOPIC_RULES:
        if rx.search(s):
            return topic
    return None


def classify_topic(text, answers):
    """The question decides; the answers only when the question says nothing."""
    return (_match_topic(text.lower()) or _match_topic(' '.join(answers).lower())
            or DEFAULT_TOPIC)


def select_questions(rows):
    """Returns (questions, report) for category B rows.

    Each question: id, text, part, points, answers, correct, media (source
    file name or ''). The first occurrence of a duplicated id wins.
    """
    report = {'duplicates': [], 'invalid': []}
    questions = []
    seen = set()
    for r in rows[1:]:
        if not r or len(r) <= COL_CATS:
            continue
        if not is_category_b(r[COL_CATS]):
            continue
        media = r[COL_MEDIA].strip()
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
            'topic': classify_topic(
                text, answers if part == 'specialist' else []),
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
    """Maps lower-case media file names to (archive, member) pairs."""
    index = {}
    archives = [zipfile.ZipFile(p) for p in paths]
    for archive in archives:
        for info in archive.infolist():
            name = os.path.basename(info.filename).lower()
            if media_kind(name):
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


def transcode_video(data, videos_out):
    """Writes <sha>.mp4 into videos_out (skipped when it already exists) and
    returns (name, size)."""
    name = video_name(data)
    target = os.path.join(videos_out, name)
    if not os.path.exists(target):
        tmp = tempfile.mkdtemp()
        try:
            src = os.path.join(tmp, 'src.wmv')
            with open(src, 'wb') as f:
                f.write(data)
            part = target + '.part'
            subprocess.run(ffmpeg_args(src, part, has_audio(src)), check=True)
            os.replace(part, target)
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
    return name, os.path.getsize(target)


def build(xlsx, zips, out, videos_out=None, workers=3):
    questions, report = select_questions(read_xlsx_rows(xlsx))
    img_dir = os.path.join(out, 'img')
    os.makedirs(img_dir, exist_ok=True)
    if videos_out:
        os.makedirs(videos_out, exist_ok=True)
    index = index_archives(zips)
    kept, missing, video_skipped = [], [], 0
    video_jobs = {}  # archive member -> future of (name, size)
    pool = concurrent.futures.ThreadPoolExecutor(max_workers=workers)
    for q in questions:
        media = q.pop('media')
        q['image'] = None
        kind = media_kind(media)
        if kind == 'video' and not videos_out:
            video_skipped += 1
            continue
        if media:
            entry = index.get(os.path.basename(media).lower())
            if entry is None:
                missing.append(q['id'])
                continue
            archive, member = entry
            if kind == 'video':
                if member not in video_jobs:
                    video_jobs[member] = pool.submit(
                        transcode_video, archive.read(member), videos_out)
                q['_video_job'] = video_jobs[member]
            else:
                target = os.path.join(img_dir, '%d.webp' % q['id'])
                convert_image(archive.read(member), target)
                q['image'] = 'assets/theory_exam/img/%d.webp' % q['id']
        kept.append(q)
    for done, q in enumerate([q for q in kept if '_video_job' in q], 1):
        name, size = q.pop('_video_job').result()
        q['video'] = video_storage_path(name)
        q['videoBytes'] = size
        if done % 50 == 0:
            print('videos ready for', done, 'questions', flush=True)
    pool.shutdown()
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
    topics = {}
    for q in kept:
        topics[q['topic']] = topics.get(q['topic'], 0) + 1
    print('topics:', dict(sorted(topics.items(), key=lambda kv: -kv[1])))
    print('with video:', sum(1 for q in kept if q.get('video')))
    print('video files:', len(video_jobs))
    print('video skipped (no --videos-out):', video_skipped)
    print('duplicates skipped:', report['duplicates'])
    print('invalid skipped:', report['invalid'])
    print('missing media skipped:', len(missing), missing[:20])
    print('images MB: %.1f' % (image_bytes / 1e6))
    if videos_out:
        video_bytes = sum(os.path.getsize(os.path.join(videos_out, f))
                          for f in os.listdir(videos_out)
                          if f.endswith('.mp4'))
        print('videos MB: %.1f' % (video_bytes / 1e6))


def retag(out):
    """Recomputes the topic of every question in an existing bank; the same
    result as a full build, without the source archives."""
    path = os.path.join(out, 'questions_b.json')
    with open(path, encoding='utf-8') as f:
        bank = json.load(f)
    counts = {}
    for q in bank['questions']:
        q['topic'] = classify_topic(
            q['text'], q['answers'] if q['part'] == 'specialist' else [])
        counts[q['topic']] = counts.get(q['topic'], 0) + 1
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(bank, f, ensure_ascii=False, separators=(',', ':'))
    print('topics:', dict(sorted(counts.items(), key=lambda kv: -kv[1])))


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('--xlsx')
    parser.add_argument('--zip', action='append')
    parser.add_argument('--retag', action='store_true',
                        help='only recompute topics in the existing bank')
    parser.add_argument('--out', default='assets/theory_exam')
    parser.add_argument('--videos-out')
    parser.add_argument('--workers', type=int, default=3)
    args = parser.parse_args(argv)
    if args.retag:
        retag(args.out)
        return
    if not args.xlsx or not args.zip:
        parser.error('--xlsx and --zip are required for a full build')
    build(args.xlsx, args.zip, args.out, args.videos_out, args.workers)


if __name__ == '__main__':
    main(sys.argv[1:])
