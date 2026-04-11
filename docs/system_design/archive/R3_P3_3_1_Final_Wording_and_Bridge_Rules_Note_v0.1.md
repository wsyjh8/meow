# R3_P3_3_1_Final_Wording_and_Bridge_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / wording freeze + bridge semantics
- **Status:** ready for Room 1 absorption
- **Date:** 2026-04-10
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-10_v19.md` + `STATUS_updated_2026-04-10_v18.md`
- **Direct upstream input:** `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`

---

## 0. 文档目标

本稿只做两件事：

1. 作为 **Room 3 的 rules / copy freeze 输入**，给出 Study / Review 4 按钮的最终两字中文词面建议；
2. 给出 **ReviewPage FSRS bridge** 在 P3.3.1 本轮的业务语义边界，供 Room 1 判断是否已足够收口。

本稿不是：
- 新 BR 主文档
- Room 2 技术方案正文
- Room 5 UI SPEC 正文
- Room 4 执行 patch
- 完整 SRS / 完整复习调度规则正文

一句话：

> **P3.3.1 在 Room 3 视角，是把“最终两字中文词面”与“ReviewPage bridge 的业务语义边界”写硬，而不是重写学习系统。**

---

## 1. 输入依据

### 1.1 当前推进层 / 治理层基线
- `Main_updated_2026-04-10_v19.md`
- `STATUS_updated_2026-04-10_v18.md`
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 当前 active / review basis
- `BR-OPP-001_v0.2.2.md`
- `UI_SPEC_v0.2.2.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 1.3 P3.3.1 直接相关输入
- `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`
- `R2_P3_3_1_PreviewDurations_and_FSRS_Bridge_Tech_Note_v0.1.md`
- `UI_SPEC_P3_3_1_Copy_Polish_and_PreviewDurations_Delta_v0.1.md`
- `R4_P3_3_Test_Draft_v0.1.md`

---

## 2. Room 3 总判断

### 2.1 本轮规则收口目标
Room 3 认为，P3.3.1 当前最需要收口的，不是完整 FSRS 产品，而是以下两层：

1. **按钮词面层**
   - 最终两字中文词面是什么
   - 是否仍然符合 `rating input` 事实边界
   - 哪些词一定不能用

2. **bridge 语义层**
   - ReviewPage 本地 FSRS bridge 本轮是否允许继续 best-effort
   - 如果允许，最低必须守到哪一层
   - 哪些用户可见表达绝对不能出现

### 2.2 Room 3 一句话立场
> **本轮允许冻结 final wording，也允许 ReviewPage bridge 继续保留在“可控 best-effort”层；但不允许把按钮词面写成结果事实，也不允许把 bridge 成功/失败写成用户可依赖的计划事实。**

---

## 3. 4 按钮最终两字中文词面（Room 3 提交给 Room 1 的收口版）

## 3.1 Room 3 推荐最终词面
Room 3 当前建议，StudyPage 与 ReviewPage 最终统一采用：

1. **不认识**
2. **模糊**
3. **记得**
4. **秒答**

### 3.1.1 与 FSRS canonical order 的映射
固定映射为：

- `Again` → **不认识**
- `Hard` → **模糊**
- `Good` → **记得**
- `Easy` → **秒答**

### 3.1.2 固定顺序
Study / Review 两页顺序必须保持一致，不得一页一套：

- 左上：不认识
- 右上：模糊
- 左下：记得
- 右下：秒答

---

## 4. 每个词面的业务语义判断

## 4.1 不认识
- **Room 3 judgment:** 可接受
- **Why:** 在当前单词卡片任务场景中，它更接近“这题当前不认识 / 想不起来”，而不是长期能力结论。
- **Allowed meaning:** 当前回忆失败或接近失败，对应最低档 rating input。
- **Must not imply:** 不得被解释成“我永远不会 / 以后都不会”。

## 4.2 模糊
- **Room 3 judgment:** 可接受
- **Why:** 它表达的是当前回忆不稳、犹豫、低确信度，属于过程态词，不像结果词。
- **Allowed meaning:** 当前想起了部分或很吃力，对应次低档 rating input。
- **Must not imply:** 不得被解释成“系统已判定你掌握不牢”的长期诊断。

## 4.3 记得
- **Room 3 judgment:** 可接受
- **Why:** 它表达“这次想起来了”，比“会了 / 已会 / 掌握”更轻，更符合输入态。
- **Allowed meaning:** 当前正常想起，对应常规正向 rating input。
- **Must not imply:** 不得被解释成“系统已确认你已经学会”。

## 4.4 秒答
- **Room 3 judgment:** 可接受
- **Why:** 它表达的是“这次几乎秒回”，强调当前回忆流畅度，而不是长期 mastery。
- **Allowed meaning:** 当前轻松想起，对应最高档 rating input。
- **Must not imply:** 不得被解释成“永久掌握 / 已熟练 / 以后一定会”。

---

## 5. 绝对不能用的词（Fact Copy 禁区）

以下词在 P3.3.1 当前轮，Room 3 明确列为 **不建议 / 禁止作为 final wording**：

1. **掌握**
2. **已会**
3. **会了**
4. **完成**
5. **熟练**
6. **记住了**
7. **奖励到账**
8. **已更新计划**
9. **已同步复习安排**

### 5.1 原因
这些词的问题不是“不好看”，而是它们会跨过 `rating input` 的边界，直接滑到：
- 结果事实
- 长期能力判断
- 系统已确认的计划变更
- 账本 / 奖励事实

Room 3 不允许把这类语义直接放在 4 按钮本体或其点击后的主反馈里。

---

## 6. ReviewPage FSRS bridge 的规则层立场

## 6.1 Room 3 结论
> **本轮允许 ReviewPage FSRS bridge 继续保留为 best-effort，但只能是“可控 best-effort”，不允许继续是无边界、无语义约束的 silent drift。**

### 6.1.1 为什么允许本轮继续 best-effort
原因有三点：

1. 当前云端 `review_group` 仍是 ReviewPage 主队列 / 主真相层  
2. Room 2 已明确：本轮不改 planner owner、不改 `review_group` 最小合同、不把 bridge 升格为强合同  
3. P3.3.1 本轮定位是“收尾补强”，不是第二次大扩 scope  

因此，Room 3 不要求本轮把 ReviewPage bridge 提升成 must-succeed。

## 6.2 Room 3 对本轮最低要求
如果本轮继续允许 best-effort，则最低必须满足以下 5 条：

### RF-P3.3.1-001 — Cloud-first remains hard rule
- 云端 `submitReviewAttempt()` 仍是主写入
- 本地 bridge 不得先于 cloud submit
- 不得因为本地 bridge 想做得更强，就反向提升本地 planner owner

### RF-P3.3.1-002 — 本地 ensure / init 可以补，但只能是 idempotent
- 允许在 ReviewPage bridge 前增加本地 `initCardForWord()` / ensure-local-card-state
- 该逻辑必须是幂等
- 它的目的只是减少 bridge miss，不是改权威来源

### RF-P3.3.1-003 — 本地 bridge failure 继续 non-blocking
- 若 cloud submit 已成功，而本地 bridge 失败：
  - 不得回滚 cloud submit
  - 不得阻断 next item
  - 不得阻断 group completion
  - 不得阻断 settlement 既有流程

### RF-P3.3.1-004 — failure 不能再是“无边界 silent drift”
- Room 3 不要求 user-facing error
- 但至少要求它在 dev / test 侧是：
  - 可调试
  - 可观察
  - 可验证 fallback 分支存在
- 也就是：允许用户无感，但不允许治理层无感

### RF-P3.3.1-005 — 不得产生用户可见的假事实
无论 bridge 成功还是失败，都不得新增或保留以下用户可见假事实：

- 已掌握
- 已完成今日任务
- 奖励已到账
- 已更新你的复习计划
- 下次将在 X 天后复习（当前轮）
- 已同步复习安排
- 学习模型已更新

---

## 7. previewDurations 的 Room 3 立场

## 7.1 Room 3 结论
> **Room 3 接受 Room 2 当前判断：`previewDurations` 在 P3.3.1 继续保持 deferred，不进入 active contract。**

### 7.1.1 Room 3 为什么接受 deferred
因为当前如果把它升格，会在业务语义层制造两类误导：

1. 用户会把 preview 当成“系统已经稳定承诺的下次安排”
2. 实现层会被诱导继续补脑：
   - 这个时间是本地算的还是后端给的
   - Study / Review 是否共用同一来源
   - bridge 成功与否是否影响 preview 可见性

这些都超出了 P3.3.1 当前范围。

### 7.1.2 Room 3 当前要求
- 不进入当前 active BR / UI fact copy
- 不在按钮下方展示稳定预估文案
- 不把“解释性增强”写成“系统已确认的时间安排”

---

## 8. Room 3 可直接给 Room 1 的决策句

### 8.1 Final wording freeze decision sentence
> **Room 3 judgment：P3.3.1 当前建议将 Study / Review 4 按钮最终两字中文词面冻结为 `不认识 / 模糊 / 记得 / 秒答`。这四个词在当前场景下均可被解释为 `rating input`，不直接夸大成结果事实；同时应继续明确禁止使用 `掌握 / 已会 / 会了 / 完成 / 熟练 / 记住了` 等容易越界成 mastery/result fact 的词。**

### 8.2 Bridge semantic decision sentence
> **Room 3 judgment：ReviewPage FSRS bridge 在 P3.3.1 本轮可以继续保留为 `controlled best-effort`，不必升格为强合同；但最低必须守住 cloud-first、不阻断 `review_group` 主链路、不把本地 bridge 成功/失败写成用户可见计划事实、并让 fallback 在 dev/test 侧可观察。**

### 8.3 previewDurations decision sentence
> **Room 3 judgment：`previewDurations` 当前继续 deferred；在双真相层未统一、ReviewPage bridge 仍处于收尾补强阶段前，不应把它升格为 active contract 或用户可依赖的稳定事实。**

---

## 9. 对 Room 4 的禁止补脑项（Room 3 版）

Room 4 在 Room 1 未统一吸收前，不得自行决定：

1. 替换成另一套按钮词面
2. 把 `秒答` 写成 mastery / 熟练度结论
3. 把 bridge success 写成“已更新计划 / 已同步复习安排”
4. 在 ReviewPage 显示 `previewDurations`
5. 因 bridge 补强而改 `review_group` 的主队列 / 主真相层地位
6. 把本轮写成“完整 FSRS 产品已完成”

---

## 10. Room 3 最终一句话

> **P3.3.1 本轮，Room 3 推荐将 4 按钮 final wording 冻结为 `不认识 / 模糊 / 记得 / 秒答`，并接受 ReviewPage bridge 继续作为 `controlled best-effort` 保留；但同时明确禁止把按钮词面、bridge side-effect 或 deferred preview 写成任何用户可依赖的结果事实或稳定计划事实。**
