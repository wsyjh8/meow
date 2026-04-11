# R3_P3_3_FSRS_4Button_ReviewPlanning_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / P3.3 preflight input
- **Status:** ready for Room 1 review
- **Date:** 2026-04-09
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-09_v18.md` + `STATUS_updated_2026-04-09_v17.md`
- **Source handoff:** `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目的

本文件由 **Room 3** 产出，用于把 P3.3 中与：

1. FSRS 接入真实学习 / 复习页面  
2. 学习页 / 复习页 4 按钮业务语义  
3. 两字中文按钮文案的事实边界  
4. “开始做复习规划”本轮到底冻结到哪一层  

相关的 **业务规则问题**，先收成一份 `rules note`，供 Room 1 / Room 2 / Room 5 后续吸收与对齐。

本文件不是：
- Room 1 的版本范围拍板
- Room 2 的技术接入方案
- Room 5 的最终词面或最终布局定稿
- Room 4 的执行单
- 完整 SRS / 全量复习调度引擎规则正文

一句话：

> **先把“4 按钮在业务上是什么意思、能说什么不能说什么、FSRS 本轮冻结到哪层、哪些地方不能让执行层补脑”写清楚。**

---

## 1. 输入依据

### 1.1 当前治理层 / 推进层依据
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `Main_updated_2026-04-09_v18.md`
- `STATUS_updated_2026-04-09_v17.md`

### 1.2 当前 active runtime rule / contract / UI basis
- `BR-OPP-001_v0.2.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.1.md`

### 1.3 当前 code-truth / reference basis
- `背单词喵喵app_DB设计草案_v0.2.0.md`
- `UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1.md`
- `p3_3_review.md`

### 1.4 本轮 handoff basis
- `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 2. Room 3 当前判断

### 2.1 为什么需要单独做 P3.3 rules note
原因有四点：

1. 当前 active BR baseline 仍服务于 **P3.1 overall closed / runtime baseline updated**，并未自动吸收 P3.3。  
2. `UI_SPEC_P3_3_HomeEntry_and_4Button_UI_Preflight_v0.1.1.md` 已把入口、布局、候选词面收成了 UI preflight，但 Room 5 自己已明确：**不在 Room 3 / Room 2 未收口前把 4 按钮业务含义写死。**
3. Room 1 这轮明确要求 Room 3 交付的，不是泛泛而谈，而是：
   - 4 按钮各自的业务语义
   - 4 按钮与 FSRS 语义的映射关系
   - 两字中文文案是否符合业务事实
   - “开始做复习规划”本轮冻结到哪一层
   - 哪些内容仍必须保持 pending
4. 当前代码现实里，Study / Review 仍是 **2 按钮 reality**，FSRS 4 按钮能力已存在但未进入当前 runtime active contract，因此必须先做规则侧预收口，避免 Room 4 边做边猜。

### 2.2 Room 3 的一句话立场
> **P3.3 本轮先冻结“4 按钮输入语义 + FSRS 映射要求 + 中文词面事实边界 + 复习规划 preflight 边界”，不冻结完整 SRS 算法，不冻结完整复习调度产品，也不把 4 按钮直接写成 runtime 已切换事实。**

### 2.3 当前 runtime reality vs 本轮候选
1. 当前 runtime active UI / BR 现实仍是：
   - `StudyPage` / `ReviewPage` 仍以 **2 按钮 reality** 为当前运行态
   - 4 按钮属于 **P3.3 preflight candidate**
2. 当前本地代码现实中，FSRS rating 已存在 4 档：
   - `1 = Again`
   - `2 = Hard`
   - `3 = Good`
   - `4 = Easy`
3. 当前本地代码现实中，FSRS 调度、review logs、SessionBuilder 已存在；云端 `review_group` 也已存在最小业务合同。  
4. 因此 P3.3 现在能冻结的，不是“最终复习系统”，而是：
   - 4 按钮作为 **rating input** 的业务语义
   - rating 与 FSRS 4 档的顺序映射要求
   - 中文候选词面的事实边界
   - 复习规划进入 preflight 后，哪些能做、哪些仍不能脑补

---

## 3. 本轮规则范围

## 3.1 In Scope
1. 4 按钮各自的业务语义
2. 4 按钮与 FSRS 4 档的映射关系
3. 两字中文候选是否偏离业务事实
4. 首页“背单词”入口与当前 CTA 规则的关系边界
5. “开始做复习规划”本轮冻结到哪一层
6. 哪些内容仍继续 Pending
7. Room 4 当前不得自行补脑的点

## 3.2 Out of Scope
1. 不冻结完整 SRS / 全量复习调度算法
2. 不冻结 `review_group` group size / 分组算法 / priority engine
3. 不冻结最终 4 个中文词面
4. 不定义 API payload / DB schema / state flow 细节
5. 不直接改 active BR baseline
6. 不直接下发 Room 4 执行 patch

---

## 4. P3.3 本轮建议冻结的规则（Frozen for preflight）

## 4.1 RF-P3.3-001 — 4 按钮的本质是 rating input，不是结果事实
- **Status:** Frozen for preflight
- **Rule:** 学习页 / 复习页的 4 按钮，本质上是用户对“当前这张卡的回忆质量 / 难度感受”的 **rating input**，不是业务结果事实。
- **Checkable:**
  1. 任何按钮点击都不应在文案层直接等价于“已掌握 / 已完成 / 已升级 / 已到账”
  2. 按钮语义只能表达“当前回忆质量 / 下一步调度信号”
  3. UI / 实现不得把按钮词面写成最终结果事实
- **Why frozen:** 这是 Room 3 本轮最基础的事实边界；不先写硬，Room 4 与 Room 5 很容易把按钮文案做成结果文案

## 4.2 RF-P3.3-002 — 4 按钮必须保持单调顺序映射到 FSRS 4 档
- **Status:** Frozen for preflight
- **Rule:** P3.3 若采用 4 按钮方案，则其内部语义顺序必须与 FSRS 4 档保持一致，不允许乱序或跳义。
- **Canonical mapping order:**
  1. **最低档** = `Again` = 失败 / 几乎没想起 / 需要最强回退
  2. **次低档** = `Hard` = 想起了但很吃力 / 记忆不稳
  3. **次高档** = `Good` = 正常想起 / 可接受表现
  4. **最高档** = `Easy` = 很轻松想起 / 强正向稳定信号
- **Checkable:**
  1. 前端词面可以变化，但四档语义顺序不得变化
  2. Room 2 / Room 4 实现中不得出现“按钮顺序与 grade 值相反”的情况
  3. Study / Review 若共用 4 按钮，也必须共用同一顺序语义
- **Why frozen:** 当前本地 FSRS rating 已存在 1~4 映射；本轮至少要把“语义顺序一致”冻结，否则后续很容易出现 UI / 实现错位

## 4.3 RF-P3.3-003 — 4 按钮四档业务语义（最小冻结版）
- **Status:** Frozen for preflight
- **Rule:** 本轮 4 按钮的业务语义只冻结到“最小可检查含义”，不冻结完整算法影响。
- **四档最小语义：**
  1. **Again 档**：当前回忆失败或接近失败；应触发最强回退信号
  2. **Hard 档**：当前回忆成功但明显吃力；应触发保守推进信号
  3. **Good 档**：当前回忆正常成功；应触发常规推进信号
  4. **Easy 档**：当前回忆轻松成功；应触发更强正向推进信号
- **Must not do:**
  1. 不得把 `Hard / Good / Easy` 直接写成稳定等级、掌握等级或最终熟练度事实
  2. 不得把 `Again` 直接写成永久不会 / 永久忘记
  3. 不得把四档词面解释成“系统已经为你确定的学习结果”
- **Why frozen:** Room 1 handoff 要求 Room 3 交付“4 按钮各自业务语义”；Room 3 本轮可以且应该冻结到这层

## 4.4 RF-P3.3-004 — 两字中文要求本轮冻结，但最终词面暂不冻结
- **Status:** Frozen for preflight
- **Rule:** 本轮“**4 个按钮统一为两个字的汉字**”属于已 pin 范围；但四个具体词面，当前只收事实边界，不直接冻结为最终 active copy。
- **Frozen part:**
  1. 必须是两个字
  2. 必须能表达 rating input，而不是结果事实
  3. 必须在 4 档顺序上可比较，不能让用户看不出从低到高
- **Pending part:**
  1. 四个最终词面的最终定稿
  2. 是否 Study / Review 完全共用同一套汉字
- **Why frozen:** Room 1 已明确“两字中文要求属于本轮冻结范围”；但 final wording 需 Room 3 + Room 5 对齐，Room 1 未单方拍板

## 4.5 RF-P3.3-005 — 首页“背单词”入口的规则边界
- **Status:** Frozen for preflight
- **Rule:** 本轮首页增加“背单词”主入口，是 **P3.3 范围已 pin 的产品入口动作**；但它不自动改写当前 active BR 中与 Today / CTA winner / review continuation 相关的既有规则。
- **Frozen part:**
  1. 首页可以新增“背单词”主入口
  2. 该入口是学习主线强入口，不是弱埋点入口
  3. 默认入口容器按 Room 5 preflight 先指向 `SpecHomePage`
- **Must not do:**
  1. 不得因为首页新增入口，就自动宣布“首页最强主 CTA 规则已经正式切换”
  2. 不得越过现有 CTA winner 相关 active BR，直接把“背单词优先”写成 runtime active truth
  3. Room 4 不得仅凭 UI preflight 默认建议，就把 review continuation 相关既有规则抹掉
- **Why frozen:** 这是 Room 1 已 scope pin 的入口范围，但它与 BR 里的 CTA / review 规则仍需后续正式吸收

---

## 5. 两字中文候选的事实边界判断

## 5.1 Room 3 总判断
> **当前可以冻结“什么样的词面安全 / 不安全”，但不建议本轮直接冻结最终四个词。**

### 5.1.1 候选集 A
- 不会 / 模糊 / 记得 / 熟练

**Room 3 判断：部分可用，但不建议直接冻结。**
- `不会`：可表达最低档失败感，但略带“能力事实”绝对化
- `模糊`：较安全，可表达 recall unstable
- `记得`：有一定结果色彩，但风险可控
- `熟练`：**风险偏高**，容易被读成“已掌握 / 已熟练”

### 5.1.2 候选集 B
- 很难 / 一般 / 较好 / 很好

**Room 3 判断：不推荐作为最终业务词面。**
- 太偏主观程度词
- 更像“做题感觉评分”，弱化了记忆 / recall 语义
- 与 FSRS 4 档的记忆输入关系不够直

### 5.1.3 候选集 C
- 重来 / 再想 / 想起 / 掌握

**Room 3 判断：不推荐直接冻结。**
- `重来`：动作意味太重，不像评分输入
- `掌握`：**事实越界**，容易被理解成“系统确认你已经掌握”

## 5.2 Room 3 当前推荐
> **当前不冻结最终 4 个词面，只冻结以下 fact-boundary：**
1. 不得出现“掌握 / 完成 / 升级 / 解锁 / 到账”这类结果事实词
2. 不得出现会让用户误以为“系统已经判定最终熟练度”的词
3. 词面应尽量表达“当前回忆质量 / 难度感受”，而不是长期结论

### 5.2.1 推荐下一轮对齐方向
若 Room 5 需要一套更安全的下一轮对齐输入，Room 3 更倾向采用：

- **忘记**
- **困难**
- **良好**
- **轻松**

**说明：**
- 这组不是本轮硬冻结
- 只是 Room 3 认为更接近“rating input”的候选方向
- 若 Room 5 / Room 2 后续发现交互层或算法层仍有歧义，再通过 delta patch 收紧

---

## 6. “开始做复习规划”本轮冻结边界

## 6.1 Room 3 结论
> **本轮“开始做复习规划”只冻结到 preflight 边界，不冻结完整复习调度产品。**

### 6.1.1 本轮可以冻结的
1. `review_group` 仍是当前 active 云端最小复习批次合同
2. 本地 FSRS 已是代码现实中的独立调度能力
3. P3.3 可以开始把“真实页面评分输入”与 FSRS 调度连接起来
4. 4 按钮语义与 FSRS 4 档映射，可以作为当前轮规则输入冻结
5. 首页入口、学习页、复习页、4 按钮与复习规划之间的页面承接关系，可以进入 preflight 冻结

### 6.1.2 本轮继续 Pending 的
1. 完整 SRS / review priority / review_group 分组算法
2. 云端 `review_group` 与本地 FSRS 的最终融合策略
3. 是否由 `StudyPage` 与 `ReviewPage` 共用一套统一学习页
4. 首页点击“背单词”后是否进入新词 session / 复习 session / 混合 session / 自动分流
5. 4 按钮提交后的最小返回字段集合
6. 4 按钮防重 / 幂等 / 失败重试的最终技术策略

### 6.1.3 Room 4 当前不得补脑的点
1. 不得自己决定首页点击“背单词”后自动分流到哪种 session
2. 不得自己决定 4 按钮最终中文词面
3. 不得自己决定 `review_group` 与本地 FSRS 谁是最终权威复习引擎
4. 不得自己把 4 按钮接入写成“完整复习规划已完成”
5. 不得自己把 `today_primary_action / review_summary` 等 implemented reality 直接升格为长期 frozen business rule

---

## 7. Impact Matrix（最小版）

## 7.1 对 Room 2 的影响
Room 2 后续 technical preflight 至少应回答：
1. 4 按钮前端词面如何映射到内部 grade / rating
2. Study / Review 页接入 4 按钮后，现有 state flow / service / contract 需要改哪些点
3. 首页入口点击后的 session 启动合同
4. 4 按钮提交后的最小返回信息
5. 按钮防重与幂等风险

## 7.2 对 Room 5 的影响
Room 5 后续若要继续出 UI delta：
1. 不得把按钮词面写成结果事实
2. 首页“背单词”为最强主 CTA只属于 preflight 默认建议，不自动覆盖 active CTA 规则
3. `SpecHomePage` 仍是本轮默认首页容器落点
4. 两字中文 requirement 已冻结，但 final copy 仍需再收口

## 7.3 对 Room 4 的影响
Room 4 在 Room 1 未完成 cross-room 吸收前，不得直接实现：
1. runtime 4 按钮切换
2. 首页 session 自动分流
3. 最终词面 hardcode
4. 完整 FSRS / 完整复习规划产品化接入

---

## 8. Room 3 最终结论

> **P3.3 这轮，Room 3 当前最该冻结的不是“完整 FSRS 产品”，而是“4 按钮作为 rating input 的业务语义 + 与 FSRS 4 档的顺序映射要求 + 两字中文词面的事实边界 + 复习规划只进入 preflight 冻结层，不让执行层补脑”。**

---

## 9. 下一步建议

### 建议给 Room 1
- 先将本 note 与 Room 5 UI preflight、Room 2 tech preflight 一起做 cross-room 吸收
- 吸收后再判断是否形成 `execution-ready` 范围

### 建议给 Room 2
- technical preflight 里显式补：grade 枚举映射、session 启动合同、返回字段、按钮幂等

### 建议给 Room 5
- 保持 2 字 requirement
- 暂不冻结 final wording
- 按 Room 3 的 fact-boundary 再收一轮更稳的 copy set

### 建议给 Room 4
- 当前不自行开工接 4 按钮 runtime 切换
- 等 Room 1 完成一次 P3.3 cross-room 吸收再进 execution gate
