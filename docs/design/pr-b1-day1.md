# v0.3 PR-B1 · Day 1 — `orphan-scan` 子命令

## Context

PR-B1 Day 1。第一个交付物：扫 FS 找 PG 没指向的物理孤儿。

**核实事实**（探索后修正，与 v0.3_PR-B_scope_v0.1.md §1.2.1 一致）：

| 类别 | FS 根目录 | 对应 PG 字段 | 实际数据格式 |
|---|---|---|---|
| audio orphan | `apps/api/cdn-mock/` | `audio_assets.url` | `local://cdn/...` 或 `file:///D:/.../cdn-mock/...` |
| package orphan | `apps/api/audio-pipeline-staging/` | `content_manifest.file_url` | `file:///D:/.../audio-pipeline-staging/...@vN.jsonl.gz` |

字段名核实：`audio_assets.url`（migration 004:66），不是 `file_path` 或 `local_path`。
`content_manifest.file_url`（migration 007:84，pipeline.py:158-159 实际写入逻辑）。

工作分支：`feat/v0.3-pr-b1-publish-side-completion` @ `b072eb3`（PR-A merge）
worktree：`D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b1`

## 实施

### Step 1：新文件 `orphan_scan.py`

文件：`apps/api/scripts/content_pipeline/orphan_scan.py`（约 200 行）

复用 `gc_stale.py` 的 `_resolve_local_path()`（gc_stale.py:31-56）—— 同一签名
直接 import，避免双 SSOT。

**算法**：

```python
def run(
    *,
    cdn_mock_dir: Path,        # cdn-mock root（默认 ./cdn-mock）
    staging_dir: Path,         # audio-pipeline-staging root
    dry_run: bool,             # 默认 True
    clean: bool,               # 与 dry_run 互斥
    scope: str = "all",        # {audio, packages, all}
) -> int:
    # ── 0. 互斥 + 范围参数验证 ──────────────────────────
    # mutex / scope ∈ {audio, packages, all}，否则退出码 2

    # ── 1. 扫 audio orphans（cdn-mock 范围）─────────────
    if scope in ("audio", "all"):
        audio_orphans = _scan_audio(conn, cdn_mock_dir)
        # walk cdn_mock_dir 拿全部 .mp3 文件路径（绝对）
        # SELECT url FROM audio_assets WHERE url IS NOT NULL AND status != 'deleted'
        #   - 跳过 http(s):// 类（真 CDN，无本地对应）
        #   - 用 _resolve_local_path 转成绝对路径
        # diff = FS - PG_referenced
        # 白名单过滤（见下）

    # ── 2. 扫 package orphans（staging 范围）────────────
    if scope in ("packages", "all"):
        pkg_orphans = _scan_packages(conn, staging_dir)
        # walk staging_dir 拿全部 .gz / .br / .jsonl 文件路径
        # SELECT file_url FROM content_manifest WHERE file_url IS NOT NULL
        #   - 跳过 http(s):// 类
        #   - 用 _resolve_local_path 转成绝对路径
        #     注：content_manifest 的 file:/// 直接是绝对路径，无需 cdn_mock_dir 拼接
        # diff = FS - PG_referenced
        # 白名单过滤

    # ── 3. 输出 + 决策 ───────────────────────────────
    # 输出 audio_orphans count + sizes + (dry-run 时各 file 路径前 30 行)
    # 输出 pkg_orphans count + sizes
    # 异常告警：staging 里"似 manifest 命名但不在 PG"的（可能漏 publish）

    if dry_run or not (audio_orphans or pkg_orphans):
        return 0  # 不删

    # ── 4. clean 模式删除 ──────────────────────────────
    # 逐个删；删失败（权限错）跳过 + log；逐项打印 [del]/[skip]
    return 0
```

**白名单过滤规则**（防误删，**核心安全护栏**）：

```python
def _is_safe_to_delete(path: Path, root: Path) -> bool:
    """Conservative whitelist; reject anything we don't recognize."""
    # 1. 必须在 root 子树（防 symlink 逃逸）
    try:
        path.resolve().relative_to(root.resolve())
    except ValueError:
        return False
    # 2. 必须是文件（不删目录、symlink）
    if not path.is_file() or path.is_symlink():
        return False
    # 3. 后缀白名单
    if path.suffix.lower() not in {".mp3", ".gz", ".br", ".jsonl"}:
        return False
    # 4. 不删隐藏文件 / .gitkeep / index.json 等
    if path.name.startswith(".") or path.name in {"index.json", "manifest.json"}:
        return False
    return True
```

**返回码语义**：
- 0：成功（dry-run 或 clean 完成）
- 2：参数错误（mutex / scope / dirs 不存在）
- 1：FS 操作失败（个别 unlink 失败时局部成功，整体仍 0；但目录扫不通时返 1）

### Step 2：pipeline.py 接 `cmd_orphan_scan` + subparser

参照现有 `cmd_gc_stale` (pipeline.py:559) 的 mutex / 参数结构：

```python
def cmd_orphan_scan(args: argparse.Namespace) -> int:
    if args.dry_run and args.clean:
        print("ERROR: --dry-run and --clean are mutually exclusive", file=sys.stderr)
        return 2
    if args.scope not in ("audio", "packages", "all"):
        print(f"ERROR: --scope must be {{audio,packages,all}}, got {args.scope!r}",
              file=sys.stderr)
        return 2
    from orphan_scan import run as run_orphan_scan
    return run_orphan_scan(
        cdn_mock_dir=Path(args.cdn_mock_dir).resolve(),
        staging_dir=Path(args.staging_dir).resolve(),
        dry_run=not args.clean,  # clean 反向 default-on
        clean=args.clean,
        scope=args.scope,
    )
```

subparser：

```python
p_orphan = sub.add_parser(
    "orphan-scan",
    help="Scan FS for files not referenced by PG (filesystem orphan)",
)
p_orphan.add_argument("--dry-run", action="store_true",
                      help="(default) print orphan candidates only")
p_orphan.add_argument("--clean", action="store_true",
                      help="Actually delete orphans (mutually exclusive with --dry-run)")
p_orphan.add_argument("--cdn-mock-dir", default="cdn-mock",
                      help="CDN mock root for audio_assets URLs (default cdn-mock)")
p_orphan.add_argument("--staging-dir", default="audio-pipeline-staging",
                      help="Staging dir for content_manifest URLs (default audio-pipeline-staging)")
p_orphan.add_argument("--scope", default="all",
                      choices=["audio", "packages", "all"],
                      help="Limit scan target (default 'all')")
p_orphan.set_defaults(func=cmd_orphan_scan)
```

文档头加入：
```
orphan-scan [--dry-run|--clean]         # PR-B1 Day 1 (FS 物理孤儿)
```

### Step 3：e2e cases（pg-regression）

文件：`apps/api/test/pg-regression.e2e-spec.ts`

加一个 describe 块（在现有 Day 5 块之后），仅做轻量 smoke 验证 SQL 路径，
**不**真创建 FS 文件 / 真调用 Python（按 PR-A Day 5 的方针，避免在 jest 里
spawn Python 子进程）：

```typescript
describe('orphan-scan SQL contract (PR-B1 Day 1)', () => {
  // FS-side 行为由 Step 4 必跑 PowerShell smoke 覆盖（plan 验收强制）
  // 这里只测 PG 查询契约：哪些 url/file_url 应被纳入"已引用"集合

  it('SELECT audio_assets.url WHERE url IS NOT NULL AND status != deleted', ...);

  it('SELECT content_manifest.file_url WHERE file_url IS NOT NULL', ...);
});
```

期望 e2e：34 + 2 = **36** 通过。

### Step 4：必跑 FS smoke（PowerShell）—— 必须覆盖两类孤儿

> **评审采纳 P1**：原 8 步只造 audio orphan，package 扫坏掉也不会被发现。
> 现扩为 **12 步**，audio 与 package 各自有"造 → dry-run 检出 → clean 删除"完整链。

```powershell
cd D:\code\AI\startUp\meow\.claude\worktrees\v0.3-pr-b1\apps\api
$env:PGPASSWORD="<your-local-password>"

# ── 准备：fresh dev 状态基线 ─────────────────────────────────
# 1. dry-run 全部 scope，预期无孤儿
python scripts\content_pipeline\pipeline.py orphan-scan
# 期望: audio_orphans=0, pkg_orphans=0

# ── audio orphan 测试链 ──────────────────────────────────────
# 2. 制造 audio 孤儿（cdn-mock 下放 .mp3，PG 无对应 audio_assets 行）
$audioOrphan = "cdn-mock\audio\v1\examples\en-US\test\v1\zz\zzzzzzzzzzzzzzzzzzzzzzzz.mp3"
New-Item -ItemType Directory -Force (Split-Path $audioOrphan)
[System.IO.File]::WriteAllBytes($audioOrphan, [byte[]](0xFF,0xFB,0x00))

# 3. dry-run 检测出 1 个 audio 孤儿
python scripts\content_pipeline\pipeline.py orphan-scan
# 期望: audio_orphans=1，列出 zzzzzzzzzz... 路径；pkg_orphans=0

# 4. mutex 校验
python scripts\content_pipeline\pipeline.py orphan-scan --dry-run --clean
# 期望: 退出码 2

# 5. clean 真删 audio 孤儿
python scripts\content_pipeline\pipeline.py orphan-scan --clean --scope audio
# 期望: [del] zzzzzzzzz...，FS 文件没了
Test-Path $audioOrphan
# 期望: False

# ── package orphan 测试链（评审采纳 P1 新增）──────────────────
# 6. 制造 package 孤儿（staging 下放 .jsonl.gz，PG 无对应 content_manifest 行）
$pkgOrphan = "audio-pipeline-staging\examples-test-orphan@v999.jsonl.gz"
[System.IO.File]::WriteAllBytes($pkgOrphan, [byte[]](0x1F, 0x8B, 0x08, 0x00))

# 7. dry-run 检测出 1 个 package 孤儿
python scripts\content_pipeline\pipeline.py orphan-scan
# 期望: pkg_orphans=1，列出 examples-test-orphan@v999.jsonl.gz 路径；audio_orphans=0

# 8. clean 真删 package 孤儿
python scripts\content_pipeline\pipeline.py orphan-scan --clean --scope packages
# 期望: [del] examples-test-orphan@v999.jsonl.gz
Test-Path $pkgOrphan
# 期望: False

# ── 综合：scope 隔离 + 白名单 ───────────────────────────────
# 9. 制造跨类双孤儿，验 --scope 隔离
$audioOrphan2 = "cdn-mock\audio\v1\examples\en-US\test\v1\yy\yyyyyyyyyyyyyyyyyyyyyyyy.mp3"
$pkgOrphan2 = "audio-pipeline-staging\examples-test-iso@v998.jsonl.gz"
New-Item -ItemType Directory -Force (Split-Path $audioOrphan2)
[System.IO.File]::WriteAllBytes($audioOrphan2, [byte[]](0xFF,0xFB,0x00))
[System.IO.File]::WriteAllBytes($pkgOrphan2, [byte[]](0x1F,0x8B,0x08,0x00))

python scripts\content_pipeline\pipeline.py orphan-scan --scope audio
# 期望: audio_orphans=1（仅 yy 那个），pkg_orphans 不报告

python scripts\content_pipeline\pipeline.py orphan-scan --scope packages
# 期望: pkg_orphans=1（仅 iso 那个），audio_orphans 不报告

# 10. clean 全部清理 + 反查
python scripts\content_pipeline\pipeline.py orphan-scan --clean
# 期望: 两个孤儿都删
Test-Path $audioOrphan2; Test-Path $pkgOrphan2
# 期望: False / False

# ── 白名单测试 ──────────────────────────────────────────────
# 11. 放 .txt 假"孤儿"（cdn-mock + staging 各一），应被忽略
echo "fake" > cdn-mock\readme.txt
echo "fake" > audio-pipeline-staging\notes.txt
python scripts\content_pipeline\pipeline.py orphan-scan --clean
# 期望: 0 删除（.txt 不在白名单 .mp3 / .gz / .br / .jsonl）
Test-Path cdn-mock\readme.txt; Test-Path audio-pipeline-staging\notes.txt
# 期望: True / True
Remove-Item cdn-mock\readme.txt, audio-pipeline-staging\notes.txt

# 12. 终态确认（应回到 fresh dev 基线）
python scripts\content_pipeline\pipeline.py orphan-scan
# 期望: 0 / 0
```

**12 步全过 = Day 1 done**。任意一步失败修复后重跑全段。

## 关键文件

### 新建
- `apps/api/scripts/content_pipeline/orphan_scan.py`（约 200 行）

### 修改
- `apps/api/scripts/content_pipeline/pipeline.py`（+1 cmd + 1 subparser，约 30 行）
- `apps/api/test/pg-regression.e2e-spec.ts`（+2 light cases）

### 不动
- `gc_stale.py`（仅 import 其 `_resolve_local_path`，不改）
- `content_release_repo.py`（Day 1 不动 release 状态机）
- README（Day 4 才统一更新）
- 任何 mobile / migration / API controller

## 评审吸收（P1 修正）

| # | 评审建议 | 处置 |
|---|---|---|
| P1 | scope doc 写"扫 cdn-mock"漏 staging | ✅ Step 1 算法明确两根 + 表格列出对应字段 |
| P1 | pr-b1.md 写 audio_assets.file_path 字段名错 | ✅ 全文改 audio_assets.url（migration 004:66 核实） |
| P1 | smoke 缺 package orphan 真 FS 验证 | ✅ Step 4 从 8 步扩到 12 步，audio + package 各完整链 |

## 评审 pre-set（猜可能被提的）

预留这几条预防外部评审：
1. `_resolve_local_path` 复用 vs 复制：✅ 直接 import，避免 SSOT 漂
2. `audio_assets WHERE status != 'deleted'`：✅ 已在 Step 1 算法注释，状态为 deleted 的行不应被视作"引用 FS"（FS 已被 gc-stale 删了）
3. 白名单 vs 黑名单：✅ 用白名单（保守），防误删未识别格式
4. symlink 逃逸：✅ `_is_safe_to_delete` 第 1/2 条守
5. 大目录性能：✅ 仅 walk 一次，PG 查询单次 SELECT，set 差 O(n+m)；当前规模 < 1万行，无忧
6. concurrent 执行（多人同时跑）：🟡 不加 lock；评审若提，回应 "运维工具，非高频，预期单人单次"
7. dry-run 默认 + 显式 --clean：✅ 与 gc-stale 一致语义
8. staging in-flight build 文件被误判：🟡 文档化在风险表，运维约定"无 build 在跑时跑"

## 验收清单

- [ ] `orphan_scan.py` 新建，复用 gc_stale `_resolve_local_path`
- [ ] `pipeline.py orphan-scan` 子命令工作（mutex / scope / dry-run / clean）
- [ ] 白名单严格（symlink 拒绝 / .txt 拒绝 / hidden 拒绝）
- [ ] 跳过 audio_assets.status='deleted' 行
- [ ] 跳过 url scheme=http(s):// 行
- [ ] e2e 36/37 通过（pre-existing /me/today 仍 1 个不阻塞）
- [ ] PowerShell smoke **12 步全过**（audio + package 两类各完整链）
- [ ] flutter analyze 可选兜底（不动 mobile）

## 风险

| 风险 | 缓解 |
|---|---|
| 误删 cdn-mock 外文件 | 白名单第 1 条 `path.resolve().relative_to(root.resolve())` 拒绝逃逸 |
| 误删用户放在 cdn-mock 的非 PG 文件（手测样本） | 后缀白名单（仅 .mp3 / .gz / .br / .jsonl）+ dry-run 默认 |
| 误把 status='deleted' 行的 url 当成"已引用" | SELECT 显式 `WHERE status != 'deleted'` 排除 |
| `_resolve_local_path` 对 http(s):// 给假路径 | 显式 skip http(s) 类（PR-B3 后续真 CDN 才用 https，那时 orphan-scan 反正用不到） |
| Day 1 工作量超 1 天 | helper 短（200 行）+ subparser 短（30 行）+ smoke 是手测；预期 ≤ 4 小时 |
| staging 里的 in-flight build 文件被误判孤儿 | 文档化：orphan-scan 只在"无 build 在跑时"运行；Day 4 README 加 troubleshooting |

## 不做的事

- **不**改 schema
- **不**改 gc_stale.py（仅消费 `_resolve_local_path`）
- **不**写 cron / 自动调度
- **不**清 audio-pipeline-staging 旧 build 中间文件（那是 build_examples_package 的责任）
- **不**触碰 release 状态机（Day 2 才动）
