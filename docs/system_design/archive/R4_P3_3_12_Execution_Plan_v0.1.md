# R4_P3_3_12_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2.md`
- **Direct upstream input:** `R1_to_R4_P3_3_12_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.12 结论，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮开工的性质
> **这是 `fuller-cutover / true-exit-gate / DB-API uplift-absorb judgment preflight` 的 very narrow judgment-preflight layer，不是 full cutover，也不是 runtime owner shift / `review_group` true exit / active DB/API uplift absorbed。**

### 1.3 Room 4 采用口径
- 继续服从 **Room 1 已 pin / 已指定的 review basis**
- 当前 runtime active truth 继续以：
  - `BR-OPP-001_v0.2.13.md`
  - `UI_SPEC_v0.3.3.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `Main_updated_2026-04-10_v32.md`
  - `STATUS_updated_2026-04-10_v30.md`
  为准
- 本轮只推进：
  - `fuller_cutover_absorb_candidate_v1`
  - `review_group_true_exit_gate_v1`
  - `db_api_uplift_absorb_judgment_v1`
  - `cutover_vs_fact_owner_boundary_v4`
  - `exit_candidate_to_true_exit_transition_v1`
  - `phase6_writeback_order_v1`
  - regression / write-back / no-major-change statement
- 本轮不推进：
  - full cutover completed
  - runtime owner shift completed
  - ReviewPage local-serving full runtime cutover
  - `review_group` true exit
  - active DB/API baseline uplift absorbed
  - homepage route switch
  - active continuation source switch
  - auto-routing runtime
  - unified planner / planner merge
  - final fact owner shift
  - cleanup / old-path purge
  - DB schema rewrite
  - API core semantics rewrite

### 1.4 本轮是否需要先升级
> **默认不需要先升级。**

但若执行层在实现中发现以下情况，必须立即升级，不得自行补脑推进：

1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 `review_group` 最小合同
4. 需要把 absorb-candidate subset 写成 ReviewPage 全量 current truth
5. 需要把首页“背单词”做成 silent reroute / auto-routing runtime
6. 需要改 active continuation 的承接路径
7. 需要让 local / stronger-ingest 直接改 final fact / settlement / ledger / daily goal / streak / learning day
8. 需要把 `review_group` 写成已退场 / 已不再使用 / 可直接清理 / fallback-only
9. 需要把本轮做成 full cutover / true exit / uplift absorbed / cleanup bundling

---

## 2. 本轮目标

完成 **P3.3.12 — Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment Round** 的 **very narrow judgment-preflight execution**，具体包括：

1. 把 `fuller_cutover_absorb_candidate_v1` 收成可执行的 absorb-candidate judgment subset
2. 把 `review_group_true_exit_gate_v1` 的资格条件与 still-dependent paths 写硬
3. 把 `db_api_uplift_absorb_judgment_v1` 收成 judgment-ready seam families + rollback / hold / migration note
4. 把 `cutover_vs_fact_owner_boundary_v4` 的 final-fact-owner 红线继续写硬
5. 把 `exit_candidate_to_true_exit_transition_v1` 的 transition 条件写硬
6. 把 `phase6_writeback_order_v1` 收成固定回写顺序
7. 交付 regression / write-back / no-major-change 的固定证据包

---

## 3. In Scope

### 3.1 `fuller_cutover_absorb_candidate_v1`
本轮纳入：
1. **ReviewPage continuity-adjacent serving-adapter family** 的 absorb-candidate judgment
2. ReviewPage helper / summary / empty-state / completion 前置说明的 fuller source-neutral judgment
3. 首页 review helper / summary / no-review-state 的 retained-anchor-aware judgment
4. rollback / hold / fallback 的中性 copy / state contract judgment
5. stronger-ingest execution-ready binding prep 的 absorb-candidate judgment

### 3.2 `review_group_true_exit_gate_v1`
本轮纳入：
1. `review_group` true-exit gate 的资格条件清单
2. still-dependent paths inventory
3. retained-anchor → true-exit-gate 的资格判断
4. rollback target / fallback scope 哪些 future-narrowable、哪些 still-fixed
5. no-cleanup / no-overclaim assertions

### 3.3 `db_api_uplift_absorb_judgment_v1`
本轮纳入：
1. uplift-absorb-judgment-ready seam families
2. seam map
3. marker / migration note
4. rollback floor
5. hold note
6. write-back order reference
7. observability / QA evidence / judgment note

### 3.4 `cutover_vs_fact_owner_boundary_v4`
本轮纳入：
1. stronger-ingest absorb-judgment candidate 的前进上限
2. no-final-fact-owner-switch assertions
3. backend-confirmed final fact 继续作为结果型反馈唯一驱动源
4. completion / reward / streak / daily goal / settlement 的事实边界禁区

### 3.5 `exit_candidate_to_true_exit_transition_v1`
本轮纳入：
1. exit-candidate → true-exit-gate 的最小 transition 条件
2. retained anchor 哪些未来才允许继续缩窄
3. rollback target / fallback scope 何时才允许未来变动
4. docs / QA / UI copy 哪些依赖需先脱离 group-only wording

### 3.6 `phase6_writeback_order_v1`
本轮纳入：
1. judgment / candidate / runtime truth 的分层
2. write-back 顺序固定化
3. 哪些可被 Room 1 吸收到下一轮 handoff
4. 哪些仍不能升格为 runtime truth

---

## 4. Out of Scope

1. full cutover completed
2. runtime owner shift completed
3. ReviewPage local-serving full runtime cutover
4. `review_group` true exit
5. active DB/API baseline uplift absorbed
6. homepage route switch
7. active continuation source switch
8. auto-routing runtime
9. unified planner / planner merge
10. final fact owner shift
11. cleanup / old-path purge
12. DB schema rewrite
13. API core semantics rewrite
14. 用户可见“已切到新主链路 / `review_group` 已退场 / uplift 已完成 / cutover 已完成”的宣告

---

## 5. 必守依据

### 要按需读文档，不需要一次性读完

### 5.1 推进层 / 主线程
- `Main_updated_2026-04-10_v32.md`
- `STATUS_updated_2026-04-10_v30.md`
- `R1_to_R4_P3_3_12_Execution_Handoff_v0.1.md`

### 5.2 规则 / 事实边界
- `BR-OPP-001_v0.2.13.md`
- `R3_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Rules_Note_v0.1.md`

### 5.3 技术边界
- `R2_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.11_Claude_res.md`

### 5.4 UI / UX 边界
- `UI_SPEC_v0.3.3.md`
- `UI_SPEC_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_UI_Preflight_v0.1.md`

### 5.5 治理依据
- `ORG_v0.3.1.md`
- `ROOM04_治理版_v0.2.md`

---

## 6. Room 4 不得补脑的已收口项

以下点本轮已被 Room 1 / 当前 review basis 收口，Room 4 不得二次发明：

1. 当前 runtime truth 继续大面积保持不变
2. ReviewPage 用户可见 serving truth 继续围绕 cloud `review_group`
3. `review_group` 当前仍是 **current owner + retained fallback anchor + compatibility anchor + deprecated candidate**
4. fuller cutover 当前最多只允许进入 **ReviewPage + 首页 review 承接层** 的 absorb-candidate judgment
5. 首页继续 `study_default`
6. active continuation 继续独立承接，不得 silent reroute
7. final fact / settlement truth 继续以后端为准
8. DB / API active baseline 继续保持 `v0.2.1`
9. 任何 absorb-candidate / true-exit-gate / uplift-absorb judgment 结果都不得冒充 runtime truth
10. 用户端不得感知“新主链路已生效”

---

## 7. Room 4 执行护栏

### 7.1 `fuller_cutover_absorb_candidate_v1` 护栏
当前允许前进一步的唯一方向：
- **ReviewPage continuity-adjacent serving-adapter family**
- **与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层**
- **首页 review helper / summary / no-review-state 的 retained-anchor-aware judgment**
- **rollback / hold / fallback 的中性 copy / state contract**
- **stronger-ingest execution-ready binding prep 的 absorb-candidate judgment**

当前禁止：
1. homepage default route 切换
2. active continuation source switch
3. user-visible planner-aware route / auto-routing runtime
4. `review_group` true exit
5. final fact owner shift
6. active DB/API baseline uplift absorbed
7. cleanup / old-path purge

### 7.2 `review_group_true_exit_gate_v1` 护栏
`review_group` 当前必须继续同时保持：
1. **current runtime serving owner**
2. **retained fallback anchor**
3. **compatibility anchor**
4. **deprecated candidate**

当前只允许执行：
- true-exit gate 的资格条件清单
- still-dependent paths inventory
- retained-anchor → true-exit-gate 的资格判断
- rollback target / fallback scope 哪些 future-narrowable

当前禁止写成：
- 已退场
- 已不再使用
- 可直接清理
- fallback-only
- old path 可回收

### 7.3 `db_api_uplift_absorb_judgment_v1` 护栏
当前允许进入：
1. uplift-absorb-judgment-ready seam families
2. seam map
3. marker / migration note
4. rollback floor
5. hold note
6. write-back order reference

当前禁止进入：
1. DB schema rewrite
2. API endpoint core semantics rewrite
3. active baseline uplift absorbed
4. 因 uplift-absorb judgment 直接改运行态事实

### 7.4 `cutover_vs_fact_owner_boundary_v4` 护栏
当前 fuller cutover 允许前进一步，但只在：
- serving-adapter family 的 very narrow absorb-candidate 层
- stronger-ingest absorb-judgment candidate 层

以下最终事实当前仍必须以后端 / cloud fact layer 为准：
1. effective review fact
2. daily goal progress / completion
3. reward settlement / ledger arrival
4. `check_in / learning_day / streak`
5. completion / 到账类主反馈

当前 stronger ingest path 最多只允许进入：
- absorb-judgment-level stronger candidate

当前不得写成：
- local evidence 已成为 final fact
- reward 已到账
- daily goal 已完成
- streak 已续上
- 学习事实已更新到最终结果

### 7.5 `exit_candidate_to_true_exit_transition_v1` 护栏
当前允许判断：
1. true-exit gate 的 transition 条件
2. retained anchor 哪些未来才允许继续缩窄
3. rollback target / fallback scope 何时才可能未来变动
4. 哪些 docs / QA / UI copy 依赖需先脱离 group-only wording

当前仍不得变动：
1. rollback target = `cloud_review_group_current_runtime_path`
2. current visible owner 身份
3. retained fallback anchor 身份
4. active continuation 当前承接路径
5. current completion gating / settlement trigger 的解释通路
6. compatibility anchor / QA baseline reference

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
- 当前已完成 uplift
- 新主链路已生效

### 7.7 Stop-condition 护栏
以下任一出现，本轮必须 hold / rollback / escalate：
1. 首页 `study_default` 被触碰
2. active continuation 被 silent reroute
3. `review_group` 被写成 fallback-only / 已退场 / 可清理
4. local stronger path 影响 final fact / settlement truth
5. 用户端出现“已切到本地规划 / 新主链路已生效 / `review_group` 已退场 / cutover 已完成 / uplift 已完成”
6. fuller-cutover / true-exit-gate / uplift-absorb judgment 被误写成 runtime truth
7. candidate framing 需要先改 DB schema / API core semantics 才能成立
8. rollback path 不存在、不可验证或不可解释

---

## 8. 本轮最小执行策略（Room 4 默认采用）

执行层本轮如果要做 P3.3.12，只允许：

1. **先做 fuller-cutover absorb-candidate subset 的资格判断，不切 runtime truth**
2. **先把 `review_group` true-exit gate 的条件、still-dependent paths 与 transition 条件写硬，不改 current owner 身份**
3. **先把 uplift-absorb-judgment-ready seam families 收成 patch-draft / seam-map / marker / rollback / hold / migration note**
4. **先把 stronger-ingest absorb-judgment candidate 的 final-fact-owner 红线继续写硬**
5. **先把 judgment / candidate / runtime truth 的回写顺序写硬**
6. **先做 runtime truth regression / write-back patch draft / no-major-change statement**
7. **不做 full cutover、不做 true exit、不做 active uplift absorbed**

---

## 9. 必测项

### 9.1 absorb-candidate subset
1. 扩大方向只落在 ReviewPage + 首页 review 承接层
2. helper / summary / empty-state / completion 前置说明只做 fuller source-neutral judgment
3. 首页 review helper / no-review-state 只做 retained-anchor-aware judgment
4. 没有越过首页 route / active continuation / final fact owner

### 9.2 `review_group` true-exit gate
1. `review_group` current runtime serving owner 仍成立
2. retained fallback anchor / compatibility anchor / deprecated candidate 仍成立
3. 只形成 true-exit-gate judgment artifacts
4. 不会写成 fallback-only / 已退场 / 可清理

### 9.3 DB / API uplift-absorb judgment
1. 只形成 uplift-absorb-judgment-ready seam families 的 patch-draft / seam-map / marker / rollback / hold / migration note
2. 未改 DB schema
3. 未改 API core semantics
4. 未做 active baseline uplift absorbed

### 9.4 fact-owner boundary
1. stronger-ingest absorb-judgment candidate 不会越过 final fact owner 边界
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
4. **absorb-candidate subset 是否仍然 very narrow**
5. **`review_group` true-exit gate judgment 是否守住**
6. **DB/API uplift-absorb judgment 是否仍停在 candidate 层**
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

1. absorb-candidate subset 已按 very narrow 的 ReviewPage + 首页 review 承接层方式落地
2. `review_group` 仍保持 current owner + retained fallback anchor + compatibility anchor + deprecated candidate
3. true-exit gate 只形成 judgment artifacts，不形成 true exit
4. DB/API uplift-absorb judgment 只形成 candidate seam / marker / rollback / hold / migration note，不形成 active uplift
5. final fact / settlement owner 未被偷切
6. runtime truth guardrails 继续全绿
7. 未触碰 DB schema / API core semantics / homepage route / active continuation / full cutover / cleanup
8. 用户端无 overclaim
9. 已交 regression / write-back / no-major-change 的固定证据包

---

## 12. 给执行层的一句话

> **请按“P3.3.12 fuller-cutover / true-exit-gate / DB-API uplift-absorb judgment preflight”的 very narrow judgment layer 推进：只把 ReviewPage + 首页 review 承接层的 absorb-candidate subset、`review_group` 的 true-exit-gate judgment、以及 DB/API uplift-absorb-judgment-ready seam families 往前推一小层，同时继续死守 current runtime truth、final fact cloud-owner、retained anchor 四层姿态、以及 no-overclaim 边界；不要把本轮做成 full cutover、`review_group` true exit 或 active DB/API uplift absorbed。**
