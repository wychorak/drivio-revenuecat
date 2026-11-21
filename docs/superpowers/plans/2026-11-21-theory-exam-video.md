# Egzamin Teoretyczny – filmy: plan wdrożenia

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add the 1029 video questions (category B) to the theory exam module, with videos in Firebase Storage, cached on the device, and played like in WORD.

**Architecture:** The build script transcodes WMV to MP4 and writes `video` and `videoBytes` into `questions_b.json`. The app downloads videos through `firebase_storage` into a permanent local cache, plays them with `video_player`, and gets a `video` phase in `ExamClock`. The exam prepares all its videos before it starts.

**Tech Stack:** Python 3.12 + ffmpeg 9, Flutter 3.41/3.50, Riverpod 2, firebase_storage 12, video_player, Firebase rules tests (`firebase/rules-tests`).

**Spec:** `docs/superpowers/specs/2026-11-21-theory-exam-video-design.md`

## Global Constraints
- Storage path: `theory_exam/videos/2026-07/<sha1-12>.mp4`. Read only for signed-in users; no client writes.
- MP4: H.264 CRF 26, width ≤ 1024, yuv420p, `+faststart`. AAC mono 64k when the source has audio.
- Exam video question: 20 s reading (Start skips) → video once, no controls → 15 s answer. The 25 min total limit still applies. If playback does not start within 3 s, the answer phase starts immediately.
- A video is downloaded at most once per device. The exam starts only when all its videos are on the device. Offline, the user gets the "Egzamin bez filmów" variant.
- Nothing is deployed or uploaded (rules, files) without the user's yes.
- All UI copy is in Polish.

## Review Focus
1. Network drops while preparing the exam: retry works, and no half-written file is treated as complete (download to `.part`, then rename).
2. App killed during an exam with video: on restart there is no exam to resume, as before.
3. A video that fails to decode: the answer phase starts after 3 s, and the exam goes on.
4. Clearing downloaded videos during practice: the current question still plays or gets skipped, and nothing crashes.
5. The offline exam variant is recorded and shown as a variant, and the 74 point scoring does not change.

---

### Task 1: Video transcoding in the bank builder
**Files:**
- Modify: `tool/theory_exam/build_bank.py`, `tool/theory_exam/test_build_bank.py`, `tool/theory_exam/README.md`

**Interfaces:**
- Produces: `select_questions` keeps `.wmv` rows with `media_kind='video'`.
- Produces: `video_name(data: bytes) -> str` (sha1, 12 chars, plus `.mp4`).
- Produces: `ffmpeg_args(src, dst, has_audio) -> list[str]`.
- Produces: CLI `--videos-out DIR`. The JSON gets `video: "theory_exam/videos/2026-07/<name>"` and `videoBytes: int`.

- [ ] Tests (RED):
  - a video row is kept and gets `video` plus `videoBytes`;
  - two questions with the same source WMV share one file name;
  - `ffmpeg_args` contains `-crf 26`, `+faststart`, and `-an` only when there is no audio.
- [ ] Implement: transcode with `subprocess` into `--videos-out`, skipping files that already exist so a rerun is cheap.
- [ ] Run the tests (GREEN). Run the full build in the background (about 1 h). Write the report into the README. Commit `questions_b.json`; the videos stay outside the repo.

### Task 2: Storage rules
**Files:**
- Modify: `firebase/storage.rules`, `firebase/rules-tests/storage.rules.test.mjs`

- [ ] Tests (RED):
  - a signed-in user reads `theory_exam/videos/2026-07/x.mp4`;
  - an anonymous user cannot read it;
  - nobody can write it.
- [ ] Add the rule, run the emulator tests (GREEN), commit.
- [ ] **Ask the user** before `firebase deploy --only storage`.

### Task 3: Model and video cache
**Files:**
- Modify: `lib/features/theory_exam/models.dart`
- Create: `lib/features/theory_exam/video_cache.dart`
- Modify: `lib/providers/theory_exam_provider.dart`
- Test: `test/theory_exam/video_cache_test.dart`

**Interfaces:**
- `TheoryQuestion.video` (String?), `videoBytes` (int?), `hasVideo`.
- `abstract class VideoDownloader { Future<void> download(String storagePath, File target); }`, with production `FirebaseVideoDownloader`.
- `TheoryVideoCache(dir, downloader)`:
  - `File? localFile(q)`;
  - `Future<File> ensure(q)`;
  - `Stream<double> prepare(List<TheoryQuestion>)`;
  - `Future<int> sizeBytes()`;
  - `Future<void> clear()`.
- Providers: `theoryVideoCacheProvider`, `theoryVideoCacheSizeProvider`.

- [ ] Tests (RED):
  - a second `ensure` does not download again;
  - a failed download leaves no file behind (`.part` then rename);
  - `prepare` reports progress and downloads only what is missing;
  - `clear` empties the folder and `sizeBytes` returns 0.
- [ ] Implement, test (GREEN), commit.

### Task 4: Exam clock with a video phase
**Files:**
- Modify: `lib/features/theory_exam/exam_engine.dart`, `test/theory_exam/exam_engine_test.dart`

**Interfaces:**
- `QuestionPhase.video`.
- `ExamClock.startVideo(Duration length)`, `ExamClock.videoFailed()`, `ExamClock.videoEnded()`.
- `generateExam` draws from the whole pool.
- `generateExam(bank, rng, {bool withoutVideo = false})`.

- [ ] Tests (RED):
  - after 20 s the phase is `video` for the film's length, then `answering` for 15 s;
  - `videoFailed` during the 3 s wait goes straight to `answering`;
  - `withoutVideo` never picks a question with a video;
  - the blueprint still adds up to 32 questions and 74 points.
- [ ] Implement, test (GREEN), commit.

### Task 5: Video widget and practice
**Files:**
- Create: `lib/widgets/theory_exam/question_video.dart`
- Modify: `lib/widgets/theory_exam/question_card.dart`, `lib/screens/theory_exam/theory_practice_screen.dart`
- Test: `test/theory_exam/practice_screen_test.dart`
- `pubspec.yaml`: add `video_player`.

**Interfaces:**
- `QuestionVideo(file, {bool controls, VoidCallback? onEnded, ValueChanged<Duration>? onStarted, VoidCallback? onFailed})`.
- A `theoryVideoPlayerFactory` provider, overridden in tests by a fake that finishes immediately.

- [ ] Tests (RED):
  - practice plays the video and shows „Odtwórz ponownie”;
  - offline with the video missing: the question is skipped and the message reads „Brak internetu – pominięto pytanie z filmem”;
  - the next question's video and image are fetched ahead.
- [ ] Implement, test (GREEN), commit.

### Task 6: Exam with video
**Files:**
- Modify: `lib/screens/theory_exam/theory_exam_screen.dart`, `theory_exam_result_screen.dart`, `models.dart` (`ExamRecord.withoutVideo`)
- Test: `test/theory_exam/exam_screen_test.dart`

- [ ] Tests (RED):
  - the preparation screen „Przygotowuję egzamin…” shows progress, and the exam starts after it;
  - a download error shows „Spróbuj ponownie” and „Egzamin bez filmów”;
  - a video question goes reading → video (no controls) → answering 15 s;
  - the result screen shows the badge „Wersja bez filmów”.
- [ ] Implement, test (GREEN), commit.

### Task 7: Home screen and copy
**Files:**
- Modify: `lib/screens/theory_exam/theory_home_screen.dart`, `test/theory_exam/bank_integrity_test.dart`

- [ ] Tests (RED):
  - home shows „Pobrane filmy: 12 MB” and „Usuń pobrane filmy” clears the cache;
  - `theorySourceNote` no longer mentions skipping videos;
  - the integrity test requires `videoBytes` for every video and more than 2000 questions.
- [ ] Implement, test (GREEN), commit.

### Task 8: Upload, preview, final review
- [ ] **Ask the user** about the upload tool (no `gsutil`/`gcloud`), then upload `--videos-out` to `theory_exam/videos/2026-07/`. Check the file count and total size.
- [ ] Deploy the rules (after the user's yes from Task 2).
- [ ] Web preview with the fake downloader, plus screenshots. Run `flutter test` on 3.41 and 3.50, and `flutter analyze`.
- [ ] Self-review of the whole branch, open the PR into `feat/theory-exam`, and report to the user.
