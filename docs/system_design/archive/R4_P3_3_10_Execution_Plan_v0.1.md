# R4_P3_3_10_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2.md`
- **Direct upstream input:** `R1_to_R4_P3_3_10_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.10 结论，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮开工的性质
> **这是 `very narrow judgment-driven candidate execution`，属于 fuller-cutover / exit-gate / uplift-judgment 的执行判断层，不是 full cutover，也不是 runtime owner shift / `review_group` exit / active DB/API uplift。**

### 1.3 Room 4 采用口径
- 继续服从 **Room 1 已 pin / 已指定的 review basis**
- 当前 runtime active truth 继续以：
  - `BR-OPP-001_v0.2.11.md`
  - `UI_SPEC_v0.3.1.md`
  - `DB/API v0.2.1`
  - `Main_updated_2026-04-10_v30.md`
  - `STATUS_updated_2026-04-10_v28.md`
  为准
- 本轮只推进：
  - ReviewPage continuity-adjacent serving-adapter family 的 candidate execution prep
  - `review_group` retained-anchor → exit-candidate judgment prep
  - uplift-judgment-ready seam families 的 patch-draft / seam-map / marker / rollback / hold / migration note
  - stronger-ingest candidate 的 fact-owner boundary 固化
  - UI 的 source-neutral / retained-anchor-aware prep 扩大一小层
  - runtime truth regression / write-back patch draft / no-major-change statement
- 本轮不推进：
  - full cutover completed
  - runtime owner shift completed
  - ReviewPage local-serving full runtime cutover
  - `review_group` 真退场
  - active DB/API baseline uplift absorbed
  - homepage route switch
  - active continuation source switch
  - auto-routing runtime
  - unified planner / planner merge
  - final fact owner shift
  - cleanup / old path purge
  - DB schema rewrite
  - API core semantics rewrite

### 1.4 本轮是否需要先升级
> **默认不需要先升级。**

但若执行层在实现中发现以下情况，必须立即升级，不得自行补脑推进：

1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 `review_group` 最小合同
4. 需要把 continuity-adjacent subset 写成 ReviewPage 全量 current truth
5. 需要把首页“背单词”做成 silent reroute / auto-routing runtime
6. 需要改 active continuation 的承接路径
7. 需要让 local / stronger-ingest 直接改 final fact / settlement / ledger / daily goal / streak / learning day
8. 需要把 `review_group` 写成已退场 / 已不再使用 / 可直接清理 / fallback-only
9. 需要把本轮做成 full cutover / exit / uplift absorbed / cleanup bundling

---

## 2. 本轮目标

完成 **P3.3.10 — Fuller Cutover / `review_group` Exit-Gate / DB-API Uplift Judgment Round** 的 **very narrow judgment-driven candidate execution**，具体包括：

1. 把 fuller-cutover 的下一拍扩大方向收成 **ReviewPage continuity-adjacent serving-adapter family**
2. 把 `review_group` retained-anchor → exit-candidate 的前置条件写硬
3. 把 DB/API uplift-judgment-ready seam families 收成 patch-draft / seam-map / hold-note / rollback floor
4. 把 stronger-ingest candidate 与 final fact owner 的边界继续写硬
5. 把 UI 的 source-neutral / retained-anchor-aware prep 扩大一小层
6. 交付 regression / write-back / no-major-change 的固定证据包

---

## 3. In Scope

### 3.1 Fuller-cutover subset（very narrow）
本轮纳入：
1. ReviewPage **continuity-adjacent serving-adapter family** 的 seam-map / candidate execution prep
2. ReviewPage helper / summary / empty-state / completion 前置说明的 fuller source-neutral prep
3. 首页 review helper / summary / no-review-state 的 retained-anchor-aware prep
4. rollback / hold / fallback 的中性 copy / state contract prep

### 3.2 `review_group` exit-gate judgment
本轮纳入：
1. `review_group` exit-gate 前置条件清单
2. retained-anchor → exit-candidate judgment artifacts
3. rollback target 哪些 still-fixed、哪些 future-narrowable 的判断层
4. stop conditions 仍必须保留的硬挡板

### 3.3 DB / API uplift judgment
本轮纳入：
1. uplift-judgment-ready seam families 的 patch-draft / seam-map
2. marker / migration note / rollback floor / hold note
3. DB/API candidate 层的 write-back reference
4. 但不进入 active baseline uplift、不进入 schema rewrite / endpoint core rewrite

### 3.4 fact-owner boundary / stronger-ingest candidate
本轮纳入：
1. stronger-ingest candidate 的 boundary assertions
2. no-final-fact-owner-switch assertions
3. stronger-path judgment-ready 的最小 seam 固化
4. 结果型反馈仍只允许由 backend-confirmed final fact 驱动

### 3.5 regression / write-back
本轮纳入：
1. runtime truth regression
2. source-neutral / retained-anchor-aware UI regression
3. write-back patch draft
4. rollback / hold / migration / no-major-change 证据包

---

## 4. Out of Scope

1. full cutover completed
2. runtime owner shift completed
3. ReviewPage local-serving full runtime cutover
4. `review_group` 真退场
5. active DB/API baseline uplift absorbed
6. homepage route switch
7. active continuation source switch
8. auto-routing runtime
9. unified planner / planner merge
10. final fact owner shift
11. cleanup / old path purge
12. DB schema rewrite
13. API core semantics rewrite
14. 用户可见“已切到新主链路 / `review_group` 已退场 / uplift 已生效 / cutover 已完成”的宣告

---

## 5. 必守依据

### 要按需读文档，不需要一次性读完

### 5.1 推进层 / 主线程
- `Main_updated_2026-04-10_v30.md`
- `STATUS_updated_2026-04-10_v28.md`
- `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`
- `R1_to_R4_P3_3_10_Execution_Handoff_v0.1.md`

### 5.2 规则 / 事实边界
- `BR-OPP-001_v0.2.11.md`
- `R3_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Rules_Note_v0.1.md`

### 5.3 技术边界
- `R2_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.9_Claude_res.md`

### 5.4 UI / UX 边界
- `UI_SPEC_v0.3.1.md`
- `UI_SPEC_P3_3_10_FullerCutover_ExitGate_and_DBUplift_UI_Preflight_v0.1.md`

### 5.5 治理依据
- `ORG_v0.3.1.md`
- `ROOM04_治理版_v0.2.md`

---

## 6. Room 4 不得补脑的已收口项

以下点本轮已被 Room 1 收口，Room 4 不得二次发明：

1. **P3.3.10 是 fuller-cutover judgment / exit-gate / uplift judgment round，不是 full cutover round**
2. **current runtime truth 仍大面积围绕 cloud `review_group`**
3. **首页继续 `home_word_entry = study_default`**
4. **active continuation 继续独立承接，不得 silent reroute**
5. **`review_group` 当前仍是 current runtime owner，同时也是 retained fallback anchor / compatibility anchor / deprecated candidate**
6. **final fact / settlement truth 继续以后端为准**
7. **DB / API active baseline 仍是 `v0.2.1`**
8. **本轮必须有 migration note / rollback floor / hold note / no-major-change statement**
9. **judgment、execution-ready candidate、runtime truth 三层必须显式分开**
10. **任何 candidate / uplift / exit 结果都不得被写成已生效事实**

---

## 7. Room 4 执行护栏

### 7.1 `fuller_cutover_subset_v1` 护栏
当前允许扩大的唯一方向：
- **ReviewPage continuity-adjacent serving-adapter family**
- **与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层**
- **首页 review helper / summary / no-review-state 的 retained-anchor-aware prep**
- **rollback / hold / fallback 的中性 copy / state contract**

当前禁止：
1. homepage default route 切换
2. active continuation source switch
3. 用户可见 auto-routing / planner-aware route
4. `review_group` 真退场
5. final fact owner shift
6. active DB/API baseline uplift 生效
7. cleanup / old path purge

### 7.2 `review_group_exit_gate_v2` 护栏
`review_group` 当前必须继续同时保持：
1. **current runtime serving owner**
2. **retained fallback anchor**
3. **compatibility anchor**
4. **deprecated candidate**

当前只允许执行：
- exit-gate 前置条件清单
- retained-anchor → exit-candidate 的资格判断
- rollback target / fallback scope 的判断层

当前禁止写成：
- 已退场
- 已不再使用
- 可直接清理
- 已变成 fallback-only
- 旧 cloud path 可回收

### 7.3 `db_api_uplift_judgment_v1` 护栏
当前允许进入：
1. uplift-judgment-ready seam families
2. seam map
3. marker / migration note
4. rollback floor
5. hold note
6. write-back order reference

当前禁止进入：
1. DB schema rewrite
2. API endpoint core semantics rewrite
3. active baseline uplift absorbed
4. 因 uplift judgment 直接改运行态事实

### 7.4 `cutover_vs_fact_owner_boundary_v2` 护栏
当前 fuller cutover 允许前进一步，但只在：
- serving-adapter family 的 very narrow 层
- stronger-ingest candidate 的 judgment-ready 层

以下最终事实当前仍必须以后端 / cloud fact layer 为准：
1. effective review fact
2. daily goal progress / completion
3. reward settlement / ledger arrival
4. `check_in / learning_day / streak`
5. completion / 到账类主反馈

当前 stronger ingest path 最多只允许进入：
- uplift-judgment-ready / stronger-path-ready

当前不得写成：
- local evidence 已成为 final fact
- reward 已到账
- daily goal 已完成
- streak 已续上
- 学习事实已更新到最终结果

### 7.5 `retained_anchor_to_exit_transition_v1` 护栏
当前允许判断：
1. retained anchor 何时才有资格进入 exit-candidate
2. rollback target 哪些 still-fixed、哪些 future-narrowable
3. 哪些 stop conditions 仍必须保留为硬挡板

当前仍不允许：
1. retained anchor 改成 fallback-only
2. exit candidate 直接升级成 exit execution
3. rollback target 从 `cloud_review_group_current_runtime_path` 改掉

### 7.6 UI / Copy / Overclaim 护栏
以下表达本轮不得出现于用户侧：
- 本地 serving 已启用
- ReviewPage 已切到本地队列
- owner shift 已完成
- `review_group` 已退场
- active DB / API baseline 已升级
- auto-routing 已开启
- planner-aware 首页已生效
- 本地 evidence 已直接成为 final fact
- 当前已完成 fuller cutover
- 已切到本地规划
- 已接管奖励结算

### 7.7 Stop-condition 护栏
以下任一出现，本轮必须 hold / rollback / escalate：
1. 首页 `study_default` 被触碰
2. active continuation 被 silent reroute
3. `review_group` 被写成 fallback-only / 已退场 / 可清理
4. local stronger path 影响 final fact / settlement truth
5. 用户端出现“已切到本地规划 / 新主链路已生效 / `review_group` 已退场 / cutover 已完成”
6. fuller cutover judgment 被误写成 full cutover completed
7. candidate framing 需要先改 DB schema / API core semantics 才能成立

---

## 8. 本轮最小执行策略（Room 4 默认采用）

执行层本轮如果要做 P3.3.10，只允许：

1. **先做 continuity-adjacent serving-adapter family 的 seam-map / candidate execution prep**
2. **先把 ReviewPage 与首页相关 helper / summary / empty-state 做 retained-anchor-aware 的 source-neutral prep**
3. **先把 `review_group` exit-gate 的前置条件写硬，不改 current owner 身份**
4. **先把 uplift-judgment-ready seam families 收成 patch-draft / seam-map / marker / rollback / hold / migration note**
5. **先把 stronger-ingest candidate 的 final-fact-owner 红线写硬**
6. **先做 runtime truth regression / write-back patch draft / no-major-change statement**
7. **不做 full cutover、不做 exit execution、不做 active uplift absorbed**

---

## 9. 必测项

### 9.1 fuller-cutover subset
1. 扩大方向只落在 ReviewPage continuity-adjacent serving-adapter family
2. helper / summary / empty-state / completion 前置说明只做 fuller source-neutral prep
3. 首页 review helper / summary / no-review-state 只做 retained-anchor-aware prep
4. 没有越过首页 route / active continuation / final fact owner

### 9.2 `review_group` exit-gate
1. `review_group` current runtime serving owner 仍成立
2. retained fallback anchor / compatibility anchor / deprecated candidate 仍成立
3. 只形成 exit-candidate judgment artifacts
4. 不会写成 fallback-only / 已退场 / 可清理

### 9.3 DB / API uplift judgment
1. 只形成 uplift-judgment-ready seam families 的 patch-draft / seam-map / marker / rollback / hold / migration note
2. 未改 DB schema
3. 未改 API core semantics
4. 未做 active baseline uplift absorbed

### 9.4 fact-owner boundary
1. stronger-ingest candidate 不会越过 final fact owner 边界
2. local evidence 不会直写 final fact / settlement / ledger / daily goal / streak / learning day
3. 结果型反馈仍只由 backend-confirmed final fact 驱动

### 9.5 runtime truth regression / no-major-change
1. 首页继续 `study_default`
2. active continuation 继续独立承接
3. 用户可见 serving truth 仍围绕 cloud `review_group`
4. 用户端无 overclaim
5. `no-major-change statement` 存在

---

## 10. 执行层交付物要求

执行层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **fuller-cutover subset 是否仍然 very narrow**
5. **`review_group` retained-anchor / exit-candidate judgment 是否守住**
6. **DB/API uplift judgment 是否仍停在 candidate 层**
7. **fact-owner boundary 是否守住**
8. **是否触碰核心契约的判断**
9. **rollback / hold / migration / observability 证据包**
10. **no-major-change statement**
11. **需要哪些文档回写**
    - BR / UI / Main / Status / DB / API / TEST / 其他
12. **是否可 accept / revise / escalate / hold**

---

## 11. Room 4 验收判断口径

只有同时满足以下条件，Room 4 才会给出 `accept / 可 closeout` 倾向：

1. fuller-cutover subset 已按 very narrow 的 continuity-adjacent family 方式落地
2. `review_group` 仍保持 current owner + retained fallback anchor + compatibility anchor + deprecated candidate
3. exit-gate 只形成 judgment artifacts，不形成真实退场
4. DB/API uplift 只形成 candidate seam / marker / rollback / hold / migration note，不形成 active uplift
5. final fact / settlement owner 未被偷切
6. runtime truth guardrails 继续全绿
7. 未触碰 DB schema / API core semantics / homepage route / active continuation / full cutover / cleanup
8. 用户端无 overclaim
9. 已交 regression / write-back / no-major-change 的固定证据包

---

## 12. 给执行层的一句话

> **请按“fuller-cutover / exit-gate / uplift-judgment 的 very narrow execution”推进 P3.3.10：只把 ReviewPage continuity-adjacent serving-adapter family、`review_group` retained-anchor → exit-candidate judgment、以及 DB/API uplift-judgment-ready seam families 往前推一小层，同时死守 current runtime truth、final fact cloud-owner、以及 no-overclaim 边界；不要把本轮做成 full cutover、`review_group` 真退场或 active DB/API uplift absorbed。**
