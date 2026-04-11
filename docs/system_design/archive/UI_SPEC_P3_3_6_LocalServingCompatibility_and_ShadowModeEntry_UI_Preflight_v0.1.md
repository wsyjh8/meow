# UI_SPEC_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.6 — Local-Serving Compatibility Contract / Shadow-Mode Entry Round`
- **Direct upstream input:** `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md` + `BR-OPP-001_v0.2.7.md` + `UI_SPEC_v0.2.7.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.6 当前轮需要回答的 6 个 compatibility / shadow 问题，翻成可被 Room 1 判断是否 pin 的最小 UI 合同层。**

本稿不是：
- 新 UI 主文档
- 新 BR / DB / API 主文档
- Room 4 执行单
- runtime owner shift 完成宣告
- ReviewPage local-serving cutover 方案书
- unified planner / planner merge 直接落地稿

一句话：

> **P3.3.6 在 Room 5 视角，不是“本地已接管”的切换轮，而是把 local-serving candidate、`review_group` 兼容姿态、fact/settlement ingest 边界、routing 兼容层、deprecation/write-back 计划、以及 shadow/parity 测试策略，收成同边界可引用的 UI compatibility contract。**

---

## 1. 输入依据

### 1.1 主线程 handoff basis
- `R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 Room 2 本轮输入
- `R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md`

### 1.3 当前 runtime / review basis
- `BR-OPP-001_v0.2.7.md`
- `UI_SPEC_v0.2.7.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `p3.3.6_user.md`

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持本轮前进一步，但只支持进入 `Compatibility Contract v1` 的 very narrow UI contract：当前 runtime truth 不切，local-serving 先进入 shadow-compatible 的页面合同层。**

### 2.2 为什么应该前进一步
如果这轮继续停在 P3.3.5 的 target-state candidate，页面层会持续悬空以下问题：
1. future local-serving candidate 在页面层到底怎么被“看见”或“完全不被看见”
2. `review_group` 现在是 current runtime owner、compatibility anchor，还是已经只能当 deprecated 影子
3. local-serving candidate 产生的 attempt / progress / completion，哪些能写成 UI 事实，哪些只能当 evidence
4. 首页 continuation / helper / summary block 未来怎样兼容 local-serving candidate
5. 哪些文案要正式进入 deprecated candidate / compatibility-only
6. shadow / parity 阶段哪些结果可以显示给 dev/test，哪些绝不能漏到用户端

### 2.3 为什么不能走更深
本轮仍不能越界到：
- runtime owner shift completed
- ReviewPage local-serving runtime cutover
- local due queue 接管 current ReviewPage truth
- `review_group` 退出运行态
- auto-routing runtime
- unified planner / planner merge
- DB / API core rewrite
- 用户可见 shadow-mode 宣告

---

## 3. Room 5 的总护栏：三层必须分开

### 3.1 current runtime truth
当前页面必须继续服从：
1. 首页 `home_word_entry = study_default`
2. active continuation 高优先，但仍独立承接，不得 silent reroute
3. ReviewPage current serving truth 继续围绕 cloud `review_group`
4. StudyPage 继续承担当前最小 preview re-entry
5. ReviewPage / 首页继续不显示 preview
6. current fact / settlement truth 继续以后端为准

### 3.2 compatibility / shadow contract
本轮只允许把以下内容写成 **compatibility / shadow contract**：
1. local-serving candidate 的最小页面语义
2. `review_group` 的 compatibility posture
3. fact / settlement ingest 的 UI 事实边界
4. routing compatibility / shadow-only markers
5. deprecated-candidate / compatibility-only 的 copy / state / helper 清单
6. parity / regression / write-back 的最小固定集

### 3.3 forbidden overclaim
以下内容本轮不得写成 current UI 事实：
1. 本地已接管 ReviewPage
2. 当前复习队列来自 local due
3. `review_group` 已退出运行态
4. auto-routing 已开启
5. local-serving shadow 已对用户生效
6. owner shift 已完成

---

## 4. Q1 — `local_serving_candidate_contract_v1`（Room 5 页面版）

## 4.1 Room 5 结论
> **可以推进，但只推进到“最小 serving source 语义 + shadow-only 页面边界”层。**

### 4.1.1 页面层允许进入 compatibility contract 的内容
当前 Room 5 允许把以下元语义写进页面 / 状态合同：
- `source_type`
- `owner_layer`
- `shadow_only`
- `serving_eligibility_state`
- `candidate_reason`

它们的作用是：
- 供 Room 4 / 测试 / 调试理解 future local-serving candidate 如何存在
- 供 Room 5 给出 state contract matrix 与 copy 禁区
- 不直接变成当前用户可见文本

### 4.1.2 ReviewPage 的最小页面翻译
Room 5 当前建议 future queue source 只分三类来源标签：
1. `cloud_group`
2. `local_due_shadow`
3. `local_generated_shadow`

但本轮页面层必须继续满足：
- **用户当前只看到 `cloud_group` 的 serving reality**
- `local_due_shadow` / `local_generated_shadow` 只可存在于：
  - debug / dev / test 观察层
  - hidden adapter seam
  - parity evidence layer
- 不得直接成为 current ReviewPage 主队列来源说明

### 4.1.3 Room 5 不建议用户端显示的内容
本轮不建议用户端出现：
- 当前队列来源：本地
- 当前复习由本地规划提供
- Shadow 模式已开启
- 已切换到本地 serving

---

## 5. Q2 — `review_group_compatibility_posture_v1`（Room 5 页面版）

## 5.1 Room 5 结论
> **`review_group` 当前仍应保留“current runtime serving owner + compatibility anchor + deprecated candidate”三层姿态。**

### 5.1.1 当前页面层该怎么写
Room 5 当前推荐的页面口径是：

#### A. current runtime reality
- ReviewPage 继续是 cloud `review_group`
- continuation / remaining / completion / settlement 的 current copy 仍围绕 group 语义

#### B. compatibility anchor
- 允许在内部 contract / 注释 / matrix 中把 `review_group` 标为 compatibility anchor
- 用于未来与 local-serving candidate 做 parity / transition 对照
- 不要求当前 UI 直接露出“兼容层”字样

#### C. deprecated candidate
- 可以进入文档、代码注释、测试计划、patch draft 的 `deprecated candidate` 层
- 但当前页面文案不得写成：
  - 已废弃
  - 已退场
  - 即将不可用
  - 已切换新方案

### 5.1.2 Room 5 的最强护栏
> **本轮 UI 不得把“deprecated candidate”翻译成用户读得到的“当前旧方案已退出”。**

---

## 6. Q3 — `fact_settlement_ingest_contract_candidate_v1`（Room 5 页面版）

## 6.1 Room 5 结论
> **这是本轮非常值得推进的一层，但页面只承接“事实边界”，不承接 ingest 内部流程本身。**

### 6.1.1 页面层必须继续守住的 truth split
即使 future serving 向 local 靠，本轮页面仍必须继续服从：

1. **effective review fact**
   - 继续以后端为准

2. **daily goal progress impact**
   - 继续以后端为准

3. **reward settlement impact**
   - 继续以后端为准

4. **streak / learning_day / check-in 最终影响**
   - 继续以后端为准

也就是说：
- local-serving candidate 可以产出 evidence
- 但 evidence 不是 final fact
- UI 不得把 local evidence 直接翻译成：
  - 已完成有效复习
  - 今日进度已更新
  - 奖励已结算
  - 连续学习已延续

### 6.1.2 Room 5 对页面 copy 的硬限制
本轮若 future local-serving candidate 进入 shadow / compatibility，以下表达仍然禁止：
- 已记为有效复习
- 今日目标已推进
- 奖励已到账
- streak 已由本地 shadow 续上
- 学习事实已同步到云端

除非 cloud fact layer 已明确返回对应 final truth。

---

## 7. Q4 — `session_entry_and_routing_compat_v1`（Room 5 页面版）

## 7.1 Room 5 结论
> **可推进，但只推进到“shadow-aware routing compatibility”层；当前首页 runtime 继续保持 `study_default`。**

### 7.1.1 首页当前口径
首页当前必须继续保持：
- 主 CTA：背单词
- 默认入口：`StudyPage`
- active continuation 高优先，但通过独立 CTA / helper / priority block 承接
- 不得 silent reroute

### 7.1.2 compatibility-only 的 future candidate
若 future local-serving candidate 被进一步接受，页面层当前只允许定义：
- `shadow_routing_candidate`
- `planner_aware_entry_candidate`
- `continuation_local_compat_candidate`

它们的用途仅限：
- future contract naming
- parity / shadow planning
- hidden decision evidence

### 7.1.3 当前继续禁止的表达
- 系统已自动判断今天先复习
- 默认入口已改为 planner-aware
- mixed routing 已启用
- 点击背单词会按本地规划自动改路由

---

## 8. Q5 — `deprecation_markers_and_writeback_plan_v1`（Room 5 页面版）

## 8.1 Room 5 结论
> **必须推进，而且 UI 层必须单独给出“哪些可进 deprecated candidate，哪些只能进 compatibility-only”的清单。**

### 8.1.1 Room 5 建议进入 deprecated candidate 的 UI 资产
以下项目当前可以进入 `deprecated candidate`：
1. 直接绑定 cloud-group 语义的 helper wording
2. 直接把 `next review group` 写成 current-only 的 copy
3. 只服务 cloud-group explanation 的内部状态命名
4. 未来可能被 local-serving 重写的 continuation 文案

### 8.1.2 Room 5 建议进入 compatibility-only 的 UI 资产
以下项目当前更适合进入 `compatibility-only`：
1. ReviewPage 当前 group progress 呈现
2. continuation card 的现行布局
3. Home review helper 的 current wording
4. ReviewPage current settlement / completion 状态文案

原因：
- 它们现在仍在运行态真实服务
- 但 future local-serving 方向一旦前进，极可能需要重写

### 8.1.3 Write-back 最小要求
若 Room 1 后续 pin Compatibility Contract v1，Room 5 预期至少同步：
1. UI preflight 主文档
2. UI 主文档增量回写 patch
3. 页面级 State Contract Matrix 增量
4. fact-copy 禁区清单增量
5. Room 4 可执行的 UI patch draft 清单

---

## 9. Q6 — `shadow_parity_test_strategy_v1`（Room 5 页面版）

## 9.1 Room 5 结论
> **应该正式推进，而且 UI 侧最重要的是：shadow evidence 可以存在，但不能泄漏成用户事实。**

### 9.1.1 Room 5 建议的最小 UI 测试集合
#### A. 当前 truth 不漂移
1. 首页仍保持 `study_default`
2. active continuation 仍独立承接
3. ReviewPage 仍以 cloud `review_group` 为当前 serving truth
4. ReviewPage / 首页仍不显示 preview
5. StudyPage preview 仍保持当前最小边界

#### B. shadow evidence 不泄漏
6. 本轮即使启用 dev / test shadow flag，用户端也不出现：
   - 本地 serving 已启用
   - shadow mode 已开启
   - 已切换新规划
   - 已接管复习主链路

#### C. parity 结果不误写成 runtime fact
7. parity mismatch 不能变成用户错误提示
8. parity success 不能变成用户“已升级到新模式”提示
9. shadow candidate 不得直接驱动 completion / settlement 结果文案

#### D. deprecated / compatibility 标记不误伤用户
10. deprecated candidate 标记只进注释 / 内部 contract / 测试清单
11. compatibility-only 资产仍维持当前页面可用性
12. 页面不出现“旧方案即将失效”类惊扰文案

### 9.1.2 Room 5 对 dev/test 可见层的建议
如果 future Phase 2 真的进入 shadow run，Room 5 建议：
- shadow / parity evidence 默认只进：
  - debug panel
  - dev logs
  - QA evidence pack
- 不进普通用户 UI

---

## 10. P3.3.6 新增 Fact Copy 禁区（Room 5）

以下表达在 P3.3.6 当前轮继续列为页面事实禁区：

### local-serving / owner-shift 禁区
1. 本地 serving 已启用
2. ReviewPage 已切到本地队列
3. 当前复习队列来自本地 due
4. `review_group` 已退出运行态
5. owner shift 已完成
6. 当前 serving truth 已切换

### routing / planner 禁区
7. 系统已自动为你选择更优入口
8. auto-routing 已开启
9. mixed session 已启用
10. planner-aware 首页已生效

### fact / settlement 禁区
11. 本地已直接记为有效复习
12. 今日进度已因本地 shadow 更新
13. 奖励已因本地队列到账
14. streak 已由本地 shadow 续上

### shadow / parity 禁区
15. 影子模式已正式生效
16. parity 已通过，现已切换新模式
17. 当前已升级到新 serving 方案

---

## 11. Room 5 对 Room 1 的建议

### 11.1 建议 Room 1 可吸收的最小 UI 合同层
Room 1 若要 pin，本轮建议只吸收以下 6 条：

1. **`local_serving_candidate_contract_v1` 进入页面元语义层，但只作为 shadow-compatible candidate**
2. **`review_group_compatibility_posture_v1` 进入 “current runtime owner + compatibility anchor + deprecated candidate” 三层姿态**
3. **`fact_settlement_ingest_contract_candidate_v1` 进入页面事实边界层：local evidence ≠ final fact**
4. **`session_entry_and_routing_compat_v1` 只进入 shadow-aware compatibility，首页 runtime 继续 `study_default`**
5. **`deprecation_markers_and_writeback_plan_v1` 进入 UI 资产分层：deprecated candidate vs compatibility-only**
6. **`shadow_parity_test_strategy_v1` 进入最小固定 UI 测试集，但 shadow evidence 继续禁止泄漏到用户事实层**

### 11.2 不建议本轮吸收成 runtime truth 的内容
1. ReviewPage local-serving runtime cutover
2. 首页 planner-aware runtime route
3. auto-routing runtime
4. `review_group` runtime 退场
5. local evidence 直接驱动 fact / settlement UI 结果
6. 用户可见 shadow-mode 宣告

---

## 12. Room 5 一句话结论

> **P3.3.6 在 Room 5 视角，可以前进一步，但只应前进到“shadow-compatible 的 very narrow UI contract”：当前 runtime truth 继续保持 `study_default`、cloud `review_group` serving truth、以及 local evidence 不等于 final fact；本轮最该冻结的是 local-serving candidate 的页面元语义、`review_group` 的兼容姿态、deprecated / compatibility-only 清单、以及 shadow/parity 不得泄漏为用户事实的硬护栏。**
