// PR-C S1=β: API base URL environment switch.
//
// `String.fromEnvironment` is a compile-time constant resolved by
// `--dart-define=API_BASE=...`. mobile 4 service全切到 [apiV1Base]:
//
//   - `core/manifest/manifest_client.dart`     ManifestClient.baseUrl
//   - `core/api/api_client.dart`               ApiClient.baseUrl
//   - `core/audio/example_audio_service.dart`  ExampleAudioService._baseUrl
//   - `core/audio/pronunciation_service.dart`  PronunciationService._baseUrl
//
// **Build commands**:
//   - dev / debug / `flutter run`: 不传 dart-define, fallback
//     `http://10.0.2.2:3000/api/v1` (与 PR-A 起的 hardcode 行为完全一致)
//   - release / profile:
//     ```
//     flutter build apk --release \
//       --dart-define=API_BASE=https://api.<your-domain>/api/v1
//     ```
//
// **Forgetting `--dart-define` on release build**:
// 4 service 全 fallback `http://10.0.2.2:3000/api/v1` → release 用户启动
// 后 manifest sync + audio + api + pronunciation 全 timeout (NOT silent
// failure; sub-smoke A + F1 立刻撞错).
//
// **完整 base 含 `/api/v1` 前缀**: 与既有 hardcode 一致, 调用方直接拼
// `'$apiV1Base/content/manifest'` 等 endpoint suffix.
//
// **PR-C R4 caveat (留 PR-D, scope §0.5.1)**:
// 切 mobile baseUrl 后 metadata API 走真域名 ✓, 但 audio_assets.url
// 字段值 (server-side ingest 写) 仍是 `http://10.0.2.2:3000/cdn/...` →
// release 用户拿 metadata 200 后 GET mp3 timeout. PR-D 范围:
//   (a) `partial_publish.py` / `ingest-audio-assets.ts` 改用 production
//       cdnOrigin 重 ingest audio_assets.url
//   (b) audio mp3 + pronunciation wav 接 COS public-read URL
const String apiV1Base = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:3000/api/v1',
);
