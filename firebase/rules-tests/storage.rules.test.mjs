import {readFile} from 'node:fs/promises';
import {after, before, test} from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {deleteObject, getMetadata, ref, uploadBytes} from 'firebase/storage';

let env;
const bucket = 'demo-drivio-rules.appspot.com';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-drivio-rules',
    storage: {
      rules: await readFile(new URL('../storage.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => env?.cleanup());

const storage = (uid, claims = {}) =>
  env.authenticatedContext(uid, claims).storage(bucket);
const bytes = new Uint8Array([1, 2, 3]);

test('admin can upload a trap photo and video; signed-in users can read', async () => {
  const admin = storage('admin', {admin: true});
  const photoPath = 'traps/admin/photo.jpg';
  const videoPath = 'traps/admin/videos/clip.mp4';
  await assertSucceeds(uploadBytes(ref(admin, photoPath), bytes,
    {contentType: 'image/jpeg'}));
  await assertSucceeds(uploadBytes(ref(admin, videoPath), bytes,
    {contentType: 'video/mp4'}));
  await assertSucceeds(getMetadata(ref(storage('viewer'), photoPath)));
  await assertSucceeds(getMetadata(ref(storage('viewer'), videoPath)));
  await assertSucceeds(deleteObject(ref(admin, photoPath)));
  await assertSucceeds(deleteObject(ref(admin, videoPath)));
});

test('non-admin and different admin cannot upload to another trap folder', async () => {
  await assertFails(uploadBytes(ref(storage('viewer'),
    'traps/viewer/photo.jpg'), bytes, {contentType: 'image/jpeg'}));
  await assertFails(uploadBytes(ref(storage('other', {admin: true}),
    'traps/admin/videos/clip.mp4'), bytes, {contentType: 'video/mp4'}));
});

test('video path rejects images and unsupported video MIME types', async () => {
  const admin = storage('admin', {admin: true});
  await assertFails(uploadBytes(ref(admin, 'traps/admin/videos/not-video.jpg'),
    bytes, {contentType: 'image/jpeg'}));
  await assertFails(uploadBytes(ref(admin, 'traps/admin/videos/clip.avi'),
    bytes, {contentType: 'video/x-msvideo'}));
});
