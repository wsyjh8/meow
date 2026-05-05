# Audio Generation Pipeline v0.1.3 (local Windows)

- **Status:** candidate / local production pipeline
- **Scope:** 单词与例句 TTS 音频的**离线批量预生成**——本地 Windows 工作站跑脚本，输出 MP3 + `audio_assets.jsonl` + manifest，再交付到云端 / CDN。
- **Current MVP run mode:** 先跑**官方内置例句默认 voice**；单词 4 voice 可通过配置启用。
- **Counterpart:** `DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md`（schema 与客户端契约的 SSOT；本文档只描述生产侧实施）。
- **Contract SSOT:** `docs/design/audio_contract.yaml`（locale / voice / format / hash 算法 / CDN 路径模板的唯一真相）。
- **Out of scope:** 云端运行时 TTS / 客户端 TTS / 用户自定义例句按需合成 / AI 动态例句合成。
- **Owner:** Room 2

---

## 0. 文档定位

本文档仅描述 MVP 阶段的生产形态：**单台 Windows 工作站、单进程脚本、JSON/JSONL 文件做状态跟踪**。

它显式不是：

- 云端 ops 平台（无 PG `audio_generation_jobs` 表 / 无 worker 锁 / 无分布式协调）
- 实时 TTS 合成服务
- 多机并行任务调度
- 客户端播放策略文档

如果以后要升到云端批量平台，再起一份：

```text
AUDIO_GENERATION_PIPELINE_v0.2_cloud_ops.md
```

届时可把本文档中的 `generation_state` 映射成 PG job 表，把单进程脚本迁移为 worker 池；**音频 ID、CDN 路径、`audio_assets` 字段契约保持不变**。

---

## 1. 五阶段管线总览

```text
┌──────────────┐  examples.json / words.json
│ [generate]   │  + voices.yaml + audio_contract.yaml
└──────┬───────┘
       ↓ 入口强校验：stable_id / source_text_hash / contract whitelist
       ↓ 计算 audio_id（canonical JSON + sha256_24，含 audio_version）
       ↓ 写 generation_state（pending）
┌──────────────┐
│ [synthesize] │  Kokoro 本地 / OpenAI / Azure → 临时 WAV
└──────┬───────┘
       ↓
┌──────────────┐
│ [postprocess]│  WAV QC → trim → loudnorm → MP3 mono 96kbps → ffprobe → checksum
└──────┬───────┘
       ↓ 通过 → ready_to_upload
       ↓ 失败 → qc_failed / failures.json
┌──────────────┐
│ [publish]    │  上传对象存储 / CDN（URL 含 audio_version）→ 写 audio_assets.jsonl
└──────┬───────┘
       ↓
┌──────────────┐
│ [release]    │  release gate 100% 强校验 → 导入 PG → 切 content_manifest.is_active
└──────────────┘
       ↓ 客户端下次拉 manifest 看到新版本
```

每个阶段都必须支持：

- **独立重跑**
- **断点续跑**
- **幂等执行**
- **失败不污染已完成产物**

---

## 2. 工作目录结构

```text
audio-pipeline/
├── input/
│   ├── examples.json                  # 例句库；每条必须带 stable_id / word_id / en
│   ├── words.json                     # 词库；每条必须有 stable word id 或 normalized_word
│   └── voices.yaml                    # 本次生成配置，见 §3
├── state/
│   ├── generation_state.json          # 当前状态快照；写入必须 atomic
│   ├── generation_state.backup.json   # 上一次完整可读快照
│   ├── failures.json                  # QC / provider / publish 失败列表
│   └── lockfile                       # 防多进程并发跑同目录，见 §6.1
├── tmp/
│   └── wav/                           # 临时 WAV，可恢复缓存；不是可靠状态源
├── out/
│   ├── mp3/
│   │   └── {target_kind}/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3
│   ├── audio_assets.jsonl             # publish 阶段产物；每行一个 audio_assets row
│   ├── release_manifest.json          # release 阶段产物摘要
│   └── checksums.sha256               # 最终 MP3 文件校验清单
└── logs/
    └── run-{YYYYMMDD-HHMMSS}.log
```

### 2.1 关键约束

- 所有路径必须通过 `pathlib.Path` 生成，不手写 `\` 或 `/` 拼接。
- 工作目录建议放 SSD 上，避免 WAV / MP3 批处理时 IO 成为瓶颈。
- `tmp/wav/` **不允许无条件清空**。
- `tmp/wav/` 是可恢复缓存，不是可靠状态源。任何阶段读取 `wav_path` / `mp3_path` 前必须检查文件是否存在。
- 如果 `stage='synthesized'` 但 `wav_path` 不存在，必须自动回退到 `pending`，重新合成。
- 如果 `stage='ready_to_upload'` 但 `mp3_path` 不存在，必须自动回退到 `synthesized`；若 `wav_path` 也不存在，则继续回退到 `pending`。

### 2.2 状态写入规则

`generation_state.json` 可以先保留为单文件 JSON，但写入必须 atomic：

```text
1. 读取现有 generation_state.json
2. 写 generation_state.tmp.json
3. flush + fsync
4. 当前 generation_state.json 复制为 generation_state.backup.json
5. rename generation_state.tmp.json → generation_state.json
```

正式实现时可升级为 `generation_state.jsonl` 或 SQLite，但 MVP 不强制。

---

## 2.3 输入数据预处理（`scripts/prepare_examples.py`）

`audio-pipeline/input/examples.json` 不是某个原始文件直接复制，而是 `scripts/prepare_examples.py` 合并 4 个源文件并去重的产物。

### 源文件清单（实际产出 ground truth）

| 源文件 | 行数 | 备注 |
|---|---|---|
| `docs/get_examples/generated_examples.json` | 7375 | |
| `docs/get_examples/generated_examples2.json` | 1818 | 已修复，备份在 `.bak` |
| `docs/get_examples/generated_examples_gk.json` | 6125 | 高考 |
| `docs/get_examples/generated_examples_zk.json` | 8001 | 中考 |
| **合并去重后** | **23319** | |

### 去重规则（合同）

同一 `word_id` 下，下列两类视为重复，**保留先出现的，丢弃后出现的**：

1. `normalize_text(en)` 完全相同
2. 仅 `[bracket]` 高亮标记位置不同（即 strip 方括号后文本相同）

去重在 `prepare_examples.py` 中执行，结果落到 `audio-pipeline/input/examples.json`。

**理由**：不同源文件可能对同一词重复生成相似例句；不去重 → 同一 stable_id 多次出现 → audio_id 冲突 / 浪费 TTS 算力。

---

## 3. voices.yaml 配置

当前 MVP 目标是：**例句默认 voice 全量预生成**。单词 4 voice 通过配置启用，不混在本轮 example-only 任务里。

```yaml
audio_version: "v1"
content_version: "audio-meta-cet4@v1"
contract_file: "docs/design/audio_contract.yaml"

run_scope:
  targets: [example]       # 当前下载版默认只跑例句。生成单词时改为 [word] 或 [word, example]

voices:
  - id: af_bella
    locale: en-US
    gender: f
    accent: us
    provider: kokoro-local
    model_id: hexgrad/Kokoro-82M
    model_version: kokoro-82m-v1
    speed: 1.0
    is_default: true

  # 后续单词 4 voice 或例句多 voice 扩展时启用：
  # - id: am_michael
  #   locale: en-US
  #   gender: m
  #   accent: us
  #   provider: kokoro-local
  #   model_id: hexgrad/Kokoro-82M
  #   model_version: kokoro-82m-v1
  #   speed: 1.0
  #   is_default: false
  # - id: bf_emma
  #   locale: en-GB
  #   gender: f
  #   accent: uk
  #   provider: kokoro-local
  #   model_id: hexgrad/Kokoro-82M
  #   model_version: kokoro-82m-v1
  #   speed: 1.0
  #   is_default: false
  # - id: bm_george
  #   locale: en-GB
  #   gender: m
  #   accent: uk
  #   provider: kokoro-local
  #   model_id: hexgrad/Kokoro-82M
  #   model_version: kokoro-82m-v1
  #   speed: 1.0
  #   is_default: false

targets:
  - kind: word
    source: input/words.json
    enabled: false
    voice_scope: all

  - kind: example
    source: input/examples.json
    enabled: true
    voice_scope: default
```

### 3.1 配置校验

pipeline 启动时必须读取 `audio_contract.yaml`，并校验：

- `locale` 必须在 contract 白名单内
- `voice` 必须在 contract 白名单内
- `voice.locale` 必须与 contract 中定义一致
- `format` 当前只允许 `mp3`
- `audio_version` 不允许 App 硬编码，但 pipeline 需符合 contract 的 pattern，例如 `^v[0-9]+$`
- `model_id` MVP 固定为 `hexgrad/Kokoro-82M`

任一配置不合法，直接 abort，不进入 TTS 阶段。

---

## 4. 各阶段细则

## 4.0 共享工具函数

所有 ID 计算只能调用 reference implementation，不能在各阶段重复实现。

```python
import hashlib
import json
import unicodedata

class PipelineAbort(Exception):
    pass

class ReleaseGateError(Exception):
    pass


def canonical_json_array(values: list[str]) -> bytes:
    if any(v is None for v in values):
        raise ValueError("canonical JSON array must not contain null")
    return json.dumps(
        values,
        ensure_ascii=False,
        separators=(",", ":"),
    ).encode("utf-8")


def sha256_24(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()[:24]


def sha256_16(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()[:16]


def normalize_text(text: str) -> str:
    # 实际实现必须以 tests/fixtures/normalize_text.yaml 为准
    text = unicodedata.normalize("NFC", text)
    text = " ".join(text.strip().split())
    return text
```

---

## 4.1 [generate] —— 计算 audio_id 与目标列表

输入：`words.json` / `examples.json` + `voices.yaml` + `audio_contract.yaml`

### 4.1.0 入口强校验：stable_id 与 contract

进入 generate 前，必须对每条 example 做 `stable_id` 一致性核查：

```python
for ex in examples:
    expected = sha256_24(canonical_json_array([
        ex["word_id"],
        normalize_text(ex["en"]),
    ]))
    if ex["stable_id"] != expected:
        raise PipelineAbort(
            "stable_id 与文本失同步："
            f"stable_id={ex['stable_id']} expected={expected} "
            f"word_id={ex['word_id']} en={ex['en']!r}。"
            "修复源数据再跑，绝不绕过。"
        )
```

同时校验：

- `target_id` 必须能解析回源数据
- `target_kind='example'` 时，`target_id = example.stable_id`
- `target_kind='word'` 时，`target_id = word.id` 或 contract 指定的 `normalized_word`
- voice / locale / format 必须符合 `audio_contract.yaml`

任一失败，整批 abort，**不发生 TTS 调用**。

### 4.1.1 计算 audio_id 与 source_text_hash

对每个启用的 `(target_kind, target_id, locale, voice, format, audio_version)` 组合：

```python
audio_id = sha256_24(canonical_json_array([
    target_kind,
    target_id,
    locale,
    voice,
    format,
    audio_version,
]))

if target_kind == "example":
    source_text_hash = sha256_16(normalize_text(example["en"]).encode("utf-8"))
    input_text = example["en"]
elif target_kind == "word":
    source_text_hash = sha256_16(target_id.encode("utf-8"))
    input_text = word["text"] or target_id
else:
    raise PipelineAbort(f"unknown target_kind: {target_kind}")
```

为每条记录写入 `generation_state.json`：

```json
{
  "audio_id": "a3f9c1e4b8d720568f12c4d7",
  "target_kind": "example",
  "target_id": "ex_stable_id_24_hex_chars",
  "locale": "en-US",
  "voice": "af_bella",
  "format": "mp3",
  "audio_version": "v1",
  "source_text_hash": "ab8f93c21e2f9a01",
  "tts_provider": "kokoro-local",
  "tts_model": "hexgrad/Kokoro-82M",
  "tts_model_version": "kokoro-82m-v1",
  "speed": 1.0,
  "stage": "pending",
  "input_text": "He had to abandon his car in the snow.",
  "attempts": 0,
  "last_error": null
}
```

### 4.1.2 幂等规则

同一组合的 `audio_id` 唯一。重跑时：

- 如果 `audio_id` 已存在，且 `stage >= ready_to_upload`，并且 `mp3_path` 存在，跳过。
- 如果 `audio_id` 已存在，但对应文件缺失，按 §5 恢复规则回退状态。
- 不允许为同一 `audio_id` 追加重复 state 行。

---

## 4.2 [synthesize] —— TTS 调用

按 `stage='pending'` 顺序处理。每条：

1. 调用对应 provider 的 TTS。
2. 拿到 PCM / WAV。
3. 写入临时文件：`tmp/wav/{audio_id}.wav.partial`。
4. 写入完成并校验可读后，rename 为 `tmp/wav/{audio_id}.wav`。
5. 更新 stage → `synthesized`，写入 `wav_path`。
6. 失败则 `attempts++`，记录 `last_error`，stage 保持 `pending`；连续失败 N 次后改为 `permanent_fail`。

### 4.2.1 Provider 实现要点

| Provider | 关键约束 |
|---|---|
| `kokoro-local` | MVP 首选；本地跑 `hexgrad/Kokoro-82M`；零 API 成本；适合离线批量生成。 |
| `openai` | 备选；需要 token bucket 限速；按字符计费；不作为默认。 |
| `azure` | 备选；区域可选；不作为默认。 |

### 4.2.2 断点续跑

脚本启动时先扫描 `generation_state.json`：

- `stage='synthesized'` 且 `wav_path` 存在：跳过 synthesize。
- `stage='synthesized'` 但 `wav_path` 不存在：回退到 `pending`。
- `stage >= ready_to_upload`：不进入 synthesize。

---

## 4.3 [postprocess] —— QC + 编码

输入：`tmp/wav/{audio_id}.wav`

### 4.3.1 处理顺序

必须按以下顺序执行：

```text
1. 检查 wav_path 存在；不存在则按 §5 回退状态
2. WAV 可解码检查
3. 初步时长检查
4. 全静音检查
5. 首尾静音裁剪，保留头尾各 100ms padding
6. 响度归一到 -16 LUFS，允许 ±2 LUFS
7. clipping / peak 检查
8. 编码 MP3：mono / 96kbps / 22.05kHz
9. 最终 MP3 ffprobe decode 检查
10. 计算最终 MP3 的 checksum_sha256
11. 更新 state → ready_to_upload
12. 成功后可删除对应 tmp WAV
```

### 4.3.2 QC 规则

| 检查项 | 规则 | 失败处理 |
|---|---|---|
| WAV 可解码 | ffprobe 或 soundfile 能读取 | `qc_failed` |
| 时长合理性 | 词：200ms ≤ duration ≤ 3s；句：500ms ≤ duration ≤ 30s | `qc_failed` |
| 全静音 | RMS < -50 dBFS 全程 | `qc_failed` |
| 首尾静音裁剪 | 头尾各保留 100ms padding | 自动裁剪 |
| 响度归一 | 目标 -16 LUFS，允许 ±2 LUFS | 自动归一一次；仍失败则 `qc_failed` |
| 削波 | peak > -1 dBFS | 先重做归一；仍超则 `qc_failed` |
| MP3 可解码 | 最终 MP3 可被 ffprobe decode | `qc_failed` |

### 4.3.3 工具链

- 响度归一 / 静音裁剪：优先 `ffmpeg` + `loudnorm` filter。
- 削波检测：`numpy.max(abs(samples)) >= 0.99`。
- MP3 编码：

```powershell
ffmpeg -y -i in.wav -vn -ac 1 -b:a 96k -ar 22050 out.mp3
```

- 最终 MP3 decode 检查：

```powershell
ffprobe -v error -show_entries format=duration -of json out.mp3
```

### 4.3.4 输出路径

```text
out/mp3/{target_kind}/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3
```

`{shard}` = `audio_id[:2]`。

更新 state：

```json
{
  "audio_id": "a3f9c1e4...",
  "stage": "ready_to_upload",
  "mp3_path": "out/mp3/example/en-US/af_bella/v1/a3/a3f9c1e4....mp3",
  "bytes": 18432,
  "duration_ms": 2300,
  "checksum_sha256": "...",
  "qc_metrics": {
    "lufs": -16.2,
    "peak_dbfs": -3.1,
    "trimmed_head_ms": 50,
    "trimmed_tail_ms": 80,
    "mp3_decode_ok": true
  }
}
```

---

## 4.4 [publish] —— 上传 CDN + 落 audio_assets.jsonl

按 `stage='ready_to_upload'` 处理。每条：

1. 检查 `mp3_path` 存在；不存在则按 §5 回退。
2. 上传 `mp3_path` 到对象存储，路径：

```text
{cdn_origin}/audio/v1/{target_kind}s/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3
```

3. 上传完成后立即 `HEAD` 验证。
4. 追加一行到 `audio_assets.jsonl`。
5. 更新 stage → `published`。

### 4.4.1 audio_assets.jsonl 行格式

```json
{
  "id": "a3f9c1e4b8d720568f12c4d7",
  "target_kind": "example",
  "target_id": "ex_stable_id_24_hex_chars",
  "locale": "en-US",
  "voice": "af_bella",
  "accent": "us",
  "gender": "f",
  "format": "mp3",
  "audio_version": "v1",
  "checksum_sha256": "...",
  "source_text_hash": "ab8f93c21e2f9a01",
  "tts_provider": "kokoro-local",
  "tts_model": "hexgrad/Kokoro-82M",
  "tts_model_version": "kokoro-82m-v1",
  "bytes": 18432,
  "duration_ms": 2300,
  "url": "https://cdn.foo.com/audio/v1/examples/en-US/af_bella/v1/a3/a3f9c1e4....mp3",
  "status": "ready",
  "composite_label": "example:ex_stable_id_24_hex_chars:en-US:af_bella:v1",
  "generated_at": "2026-05-03T12:34:56Z"
}
```

### 4.4.2 失败 / 重试

- 上传失败：`attempts++`，stage 保持 `ready_to_upload`。
- `HEAD` 验证失败：删除远端对象并重传，防止部分上传。
- 多次失败后改为 `permanent_fail`，写入 `failures.json`。

---

## 4.5 [release] —— 切 manifest（含 release gate 第二道）

最后一步，所有目标 audio_id 都是 `published` 后才能执行。

### 4.5.1 Release self-check：4 项硬校验

正式实现不得使用 Python `assert`；必须显式抛出 `ReleaseGateError`。避免优化模式跳过校验。

```python
def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReleaseGateError(message)


def release_gate(audio_assets_jsonl, examples_table, words_table):
    rows = load_jsonl(audio_assets_jsonl)

    examples_by_stable_id = {ex["stable_id"]: ex for ex in examples_table}
    word_ids = {w["id"] for w in words_table}
    example_ids = set(examples_by_stable_id.keys())

    # 检查 1：audio_id 字段一致性，100% 重算
    for r in rows:
        expected = sha256_24(canonical_json_array([
            r["target_kind"],
            r["target_id"],
            r["locale"],
            r["voice"],
            r["format"],
            r["audio_version"],
        ]))
        require(r["id"] == expected, f"audio_id drift: id={r['id']} expected={expected}")

    # 检查 2：source_text_hash 与当前 examples.en 一致，100%
    for r in rows:
        if r["target_kind"] != "example":
            continue
        ex = examples_by_stable_id.get(r["target_id"])
        require(ex is not None, f"target_id not found in examples: {r['target_id']}")
        expected_hash = sha256_16(normalize_text(ex["en"]).encode("utf-8"))
        require(
            r["source_text_hash"] == expected_hash,
            "source_text_hash drift: "
            f"audio_id={r['id']} stored={r['source_text_hash']} expected={expected_hash}",
        )

    # 检查 3：target_id 可解析回源，100%
    for r in rows:
        if r["target_kind"] == "word":
            require(r["target_id"] in word_ids, f"word target_id not found: {r['target_id']}")
        elif r["target_kind"] == "example":
            require(r["target_id"] in example_ids, f"example target_id not found: {r['target_id']}")
        else:
            raise ReleaseGateError(f"unknown target_kind: {r['target_kind']}")

    # 检查 4：CDN URL 可达，5% 抽样 HEAD
    sample_size = max(1, len(rows) // 20)
    sample = random.sample(rows, sample_size)
    for r in sample:
        resp = requests.head(r["url"], timeout=10)
        require(resp.status_code == 200, f"CDN miss: {r['url']}")
```

任一失败：

- 整批不发布
- 不切 `content_manifest.is_active=true`
- 不允许 `--bypass-gate`
- 不允许降级为 warning
- 不允许对检查 1/2/3 做抽样

### 4.5.2 切 manifest

self-check 全过后：

1. 把 `audio_assets.jsonl` 批量导入云端 PG `audio_assets` 表。
2. 在 `content_manifest` 表里新建一行：

```text
id = audio-meta-cet4@v1
package_name = audio-meta-cet4
content_version = v1
file_url = ...
checksum_sha256 = ...
is_active = false
```

3. staging build 拉 manifest，抽样播放 N 条。
4. 通过后切 active：

```sql
UPDATE content_manifest SET is_active = false WHERE package_name = 'audio-meta-cet4';
UPDATE content_manifest SET is_active = true WHERE id = 'audio-meta-cet4@v1';
```

5. 客户端下次启动拉 manifest 看到新版本。

### 4.5.3 严格 vs 宽松发布

- **严格模式**：任一目标未 `published` → 拒绝 release。
- **宽松模式（MVP 可用）**：允许少量 `qc_failed`，但这些资产必须显式写入 manifest：

```json
{
  "status": "qc_failed",
  "target_kind": "example",
  "target_id": "...",
  "fallback": "disabled"
}
```

客户端遇到缺失或 `qc_failed` 资产：灰掉播放按钮，不调用系统 TTS。

重要：宽松模式只放宽“资产覆盖率”，**不放宽 §4.5.1 的 4 项 release gate**。

---

## 5. 状态机与恢复规则

```text
pending
   ↓ synthesize 成功
synthesized
   ↓ postprocess 成功
ready_to_upload
   ↓ publish 成功
published
   ↓ release 成功
released

任意阶段连续失败 N 次 → permanent_fail
postprocess QC 不过 → qc_failed
```

### 5.1 文件缺失恢复

每次启动时先跑一次 state repair：

| 当前 stage | 需要文件 | 文件缺失时 |
|---|---|---|
| `synthesized` | `wav_path` | 回退到 `pending` |
| `ready_to_upload` | `mp3_path` | 若 `wav_path` 存在，回退到 `synthesized`；否则回退到 `pending` |
| `published` | 远端 URL | publish 阶段重新 HEAD；失败则回退到 `ready_to_upload` |
| `released` | manifest row | 不自动回退，需人工处理 |

---

## 6. Windows 工程注意事项

### 6.1 单进程并发保护

```python
import msvcrt
import sys

lockfile = open("state/lockfile", "w")
try:
    msvcrt.locking(lockfile.fileno(), msvcrt.LK_NBLCK, 1)
except OSError:
    print("Pipeline already running in this directory.")
    sys.exit(1)
```

防止误开两个 PowerShell 窗口同时跑同一目录。

### 6.2 长路径

Windows 默认 `MAX_PATH=260` 通常够用，但工作目录不要放太深。必要时启用长路径支持：

```powershell
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
  -Name LongPathsEnabled -Value 1 -PropertyType DWORD -Force
```

### 6.3 工具链推荐

```text
Python 3.11+，建议 conda 环境
  ├── torch / torchaudio
  ├── kokoro or kokoro-tts wrapper
  ├── soundfile
  ├── numpy
  ├── pyloudnorm
  ├── librosa 或 pydub，可选
  ├── pydantic
  ├── PyYAML
  ├── requests
  └── boto3 / aliyun-oss2 / qcloud-cos，按对象存储 provider 选

ffmpeg / ffprobe
  - 加入 PATH
  - 用于 loudnorm、MP3 编码、最终 decode 检查
```

### 6.4 GPU vs CPU

MVP 可以先 CPU 跑过夜，不必一开始折腾 GPU。

参考估算：

```text
5500 词 + 25000 例句 ≈ 30500 条
平均 2s 音频 → 61000s 真实音频
GPU 5x realtime → 约 3–4 小时
CPU 0.4x realtime → 约 40 小时
```

实际耗时以本机 CPU/GPU、Kokoro 实现、ffmpeg 后处理耗时为准。

### 6.5 OpenAI / Azure 作为备选

如 Kokoro 质量不达标，OpenAI / Azure 可以作为生产备选，但不是默认路线。

```text
OpenAI / Azure 用于：
- 少量人工补音频
- 特定例句 Kokoro 效果不好时替换
- 临时救急
```

不要在默认 MVP pipeline 里把运行时 TTS 作为用户点击播放的兜底。

---

## 7. 各阶段命令示例

```powershell
# 全流程
python pipeline.py all

# 分阶段
python pipeline.py generate
python pipeline.py synthesize
python pipeline.py postprocess
python pipeline.py publish
python pipeline.py release

# 当前状态
python pipeline.py status

# 修复状态文件与本地文件不一致
python pipeline.py repair-state

# 重跑某个失败 audio_id
python pipeline.py retry --audio-id a3f9c1e4b8d720568f12c4d7

# 只跑例句
python pipeline.py all --target example

# 只跑默认 voice
python pipeline.py all --voice-scope default
```

---

## 8. failures.json 格式

```json
{
  "generated_at": "2026-05-03T12:34:56Z",
  "audio_version": "v1",
  "items": [
    {
      "audio_id": "...",
      "target_kind": "example",
      "target_id": "ex_stable_id_24_hex_chars",
      "input_text": "He had to abandon his car in the snow.",
      "stage": "qc_failed",
      "reason": "duration_too_short",
      "qc_metrics": {
        "duration_ms": 180,
        "lufs": -45.2
      },
      "last_error": null
    }
  ]
}
```

失败项不 silent drop。宽松发布时也必须进入 manifest，以便客户端灰按钮和埋点。

---

## 9. 与 DB 文档的接口契约

本流水线不是 SSOT。schema 真相在：

```text
DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md
```

本流水线产物必须满足：

1. hash 算法严格走 `canonical_json_array`，不得用字符串拼接。
2. 不得在 pipeline 各阶段重复实现 hash / normalize，必须 import reference functions。
3. `audio_assets` row 字段与 DB §4.6 schema 一一对应，NOT NULL 字段不得遗漏，包括 `source_text_hash`。
4. CDN 路径必须包含 `audio_version`。
5. 失败资产写 `status='qc_failed'`，不要 silent drop。
6. release 阶段切 manifest 后才视为发布完成；单纯产出 MP3 不算发布完成。
7. 必须通过 §4.5.1 release gate，且不得 bypass。
8. 配置必须引用 `docs/design/audio_contract.yaml`，不准在脚本中 inline voice / locale / format 白名单。
9. Python reference implementation 必须跑通：

```text
tests/fixtures/canonical_json.yaml
tests/fixtures/normalize_text.yaml
tests/fixtures/normalize_word.yaml
tests/fixtures/stable_id.yaml
tests/fixtures/audio_id.yaml
```

10. App 端运行时不计算 `audio_id`，不拼 CDN URL，只消费 manifest 中的 `id`、`target_id`、`url`、`checksum_sha256`。

---

## 10. 升级到云端 ops 形态的迁移路径

当本地形态扛不住时，按下述步骤迁移：

1. `generation_state.json` → 云端 PG `audio_generation_jobs` 表。
2. 单进程脚本 → worker 池 + queue，例如 Celery / BullMQ / Sidekiq。
3. 本地 ffmpeg → Docker image with ffmpeg + Python deps。
4. CDN 上传 → 接入 ops 平台 artifact registry。
5. release gate 保持一致，不因云端化而降级。

接口不变：本地形态产出的 `audio_assets.jsonl` 与云端形态产出的 PG `audio_assets` row 字段完全一致。

---

## 11. 版本历史

| 版本 | 日期 | 变更 |
|---|---|---|
| v0.1 | 2026-05-03 | 从 DB 目标架构中分离出本地 Windows 单进程 pipeline。 |
| v0.1.1 | 2026-05-03 | 与 DB doc r6 同步：canonical JSON、`source_text_hash`、release gate。 |
| v0.1.2 | 2026-05-03 | 整理为下载版：修复 `tmp/` 清空与断点续跑冲突；补 `enabled` / `voice_scope`；修正 `am_michael`；要求 state atomic write；release gate 禁用 Python `assert`；postprocess 增加最终 MP3 ffprobe decode；Kokoro 模型钉死为 `hexgrad/Kokoro-82M`。 |
| v0.1.3 | 2026-05-03 | 应 Codex 实施反馈补 §2.3 输入数据预处理：明文化 4 源文件合并 + 去重规则（normalize 相同 / 只差 `[bracket]` 视为重复），合同总数 23319 条。 |
