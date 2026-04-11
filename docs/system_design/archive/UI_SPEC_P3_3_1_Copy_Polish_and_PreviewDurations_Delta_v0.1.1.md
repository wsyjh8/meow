# UI_SPEC_P3_3_1_Copy_Polish_and_PreviewDurations_Delta_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1.1
- **Date:** 2026-04-10
- **Status:** incremental absorption patch / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Runtime basis:** `Main_updated_2026-04-10_v19.md` + `STATUS_updated_2026-04-10_v18.md`
- **Direct upstream input:** `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`
- **Related inputs:** `UI_SPEC_v0.2.2.md` + `BR-OPP-001_v0.2.2.md` + `R2_P3_3_1_PreviewDurations_and_FSRS_Bridge_Tech_Note_v0.1.md`

---

## 0. 文档目标

本稿只做四件事：

1. 给出 **4 按钮最终两字中文词面在 UI 上的推荐落位方案**
2. 给出 **4 按钮文案替换后的页面表达 delta**
3. 回答 `previewDurations` 在 Room 5 视角应如何处理
4. 对 **文案 / 防误报 / 低阻力交互** 做一轮专项补强

本稿不是：
- 最终业务语义裁决稿
- 新主 UI baseline 全量重写稿
- Room 2 的 active contract 文档
- Room 4 的执行 patch

一句话：

> **P3.3.1 在 Room 5 视角，是一轮“把已跑通的 4 按钮体验做得更稳、更不误导、更像正式产品”的 UI polish delta。**

---

## 1. 当前判断（Room 5）

### 1.1 当前不应做的事
本轮不应该：
1. 把 `previewDurations` 写成当前已稳定可见的系统事实
2. 把 ReviewPage 本地 FSRS bridge 的 side-effect 写成用户可依赖的主反馈
3. 把 4 按钮点击写成“已掌握 / 已完成 / 奖励到账”这类结果事实
4. 因为做 polish，就顺手重写首页结构、Study/Review 产品结构或完整 planner

### 1.2 当前应该做的事
本轮应该：
1. 把 4 按钮最终词面在视觉层、节奏层、误导风险层收口
2. 统一 Study / Review 两页的按钮层级、状态和行为反馈
3. 把“当前 deferred 的东西如何不误导用户”写清楚
4. 让 Room 4 拿到后，知道哪些 copy 要改、哪些 hint 不该出现、哪些状态必须补

---

## 2. 本轮范围（Room 5）

### 2.1 In Scope
1. 4 按钮最终两字中文词面的 UI 推荐
2. 4 按钮视觉顺序与页面落位
3. 点击后的即时反馈与防误报规则
4. `previewDurations` 的 UI 处理结论
5. ReviewPage bridge 风险下的用户可见行为边界
6. Study / Review / HomeEntry 的轻量 polish delta

### 2.2 Out of Scope
1. 不定义 FSRS 最终业务语义
2. 不定义 planner owner
3. 不定义 `previewDurations` active contract
4. 不重写 `UI_SPEC_v0.2.2.md`
5. 不把 Study / Review 合并成统一学习页
6. 不重做首页 CTA winner 状态驱动系统

---

## 3. 4 按钮最终中文词面（Room 5 推荐）

## 3.1 Room 5 推荐最终词面
推荐作为 **Room 5 提交给 Room 1 的最终 UI 候选集**：

1. **不认识**
2. **模糊**
3. **记得**
4. **秒答**

### 3.1.1 推荐理由
- **不认识**  
  比“不会”更贴近当前任务场景：面对单词卡片时，用户是在判断“是否认识 / 是否想得起来”，而不是泛泛地评价自己“会不会英语”。  
  它更像 rating input，不像长期能力结论。

- **模糊**  
  保持现有用户直觉最强的“中低确信度”表达。  
  它是过程感词，不像结果词。

- **记得**  
  比“会了 / 已会 / 掌握”更轻，也更接近当下回忆状态。  
  它仍是输入，不是结论。

- **秒答**  
  是四个词里最“轻快”的一个，但它表达的是“这次几乎秒回”，而不是“永久掌握”。  
  从 UI 角度，它比“熟练 / 掌握”更适合作为体验词。

## 3.2 不推荐的词
以下词不建议用于 final wording：

- **掌握**
- **已会**
- **会了**
- **完成**
- **熟练**（当前轮不推荐）
- **认识**（单独使用不推荐）

原因：
1. 太容易像结果事实
2. 太容易被理解为系统已判定 mastery
3. 与 Room 3 当前“rating input 不是结果事实”的规则边界冲突

## 3.3 若 Room 1 要保守收口
若 Room 1 倾向最小变动、避免替换用户已见词面，则次选方案可以继续保留第一拍的：
- `不认识 / 模糊 / 记得 / 秒答`

也就是说，Room 5 当前并不建议在 P3.3.1 再去做“为了新鲜而换一套”。

---

## 4. 最终落位建议（Study / Review）

## 4.1 排布
StudyPage 与 ReviewPage 继续统一采用：

- **2 × 2** 网格
- 顺序固定：
  - 左上：不认识
  - 右上：模糊
  - 左下：记得
  - 右下：秒答

## 4.2 原则
1. 两页顺序完全一致
2. 不允许一页从差到好、另一页从好到差
3. 不允许一页改颜色语义、另一页不改
4. 不允许因为 ReviewPage bridge 差异，就把 ReviewPage 做成“另一套按钮系统”

## 4.3 层级
按钮区仍然是页面底部第一强交互区：
- 不在按钮上方增加额外“算法解释标题”
- 不在按钮内部塞第二行小字
- 不在本轮加入“长按看解释”之类高阻力交互

---

## 5. 页面表达 delta

## 5.1 StudyPage
### 当前应改
1. 将 4 按钮最终词面替换为：
   - 不认识 / 模糊 / 记得 / 秒答
2. 保持按钮点击后：
   - 提交中 disable
   - 低透明禁用态
   - 成功后直接进入下一词
3. 不新增 “已掌握 / 学习完成 / 奖励到账” 类 snackbar

### 当前不应出现的文案
- 已掌握
- 学会了
- 记住了
- 奖励已到账
- 今日完成

### 可以保留的轻反馈
- 无文案，只切下一词
- 或极轻系统反馈，例如 loading / subtle transition
- 不建议再加情绪化 toast

## 5.2 ReviewPage
### 当前应改
1. 同样替换为最终词面：
   - 不认识 / 模糊 / 记得 / 秒答
2. 提交中 disable / 防重 / 顺序一致
3. 云端提交成功后正常进入下一题或组完成态
4. FSRS bridge 失败不做用户可见错误提示

### 当前不应出现的文案
- 已复习完成（当 group 未完成时）
- 已掌握
- 已完成今日任务
- 下次将在 X 天后复习（当前轮不出现）

### 允许保留的正确反馈
- group 完成时，允许出现组完成表达
- settlement 若已是当前 v0.2.2 既有正确流程，可继续保留
- 但不得把 group completion 扩写成 mastery / 奖励到账 / 今日总完成

## 5.3 SpecHomePage
### 当前应改
1. “背单词”主入口可继续保留首屏主位置
2. 文案上不建议新增过重副标题
3. 若要补一句弱提示，推荐：
   - 开始今天的学习
   - 先学一组新词

### 当前不应做
1. 不因为 P3.3.1 做 polish，就把 `previewDurations` 挂到首页 CTA 下
2. 不因为做 copy polish，就把 CTA winner 状态驱动系统提前补出来
3. 不把“背单词”入口文案改成混合型、规划型、算法型入口

---

## 6. `previewDurations` 的 Room 5 处理结论

## 6.1 Room 5 正式结论
> **本轮 `previewDurations` 不进入当前可见 UI。**

原因：
1. Room 2 已明确判定：它当前仍是 deferred，不进入 active contract
2. Study / Review 双真相层尚未统一
3. ReviewPage bridge 仍只是“可控 best-effort”，不足以支撑稳定解释型事实
4. 现在如果显示，会极大增加误导风险

## 6.2 Room 5 不建议的做法
本轮不应：
- 在按钮下方显示“1天 / 3天 / 7天 / 15天”
- 在长按按钮时显示预测间隔
- 在 ReviewPage 用本地 bridge 结果展示“下次多久后复习”
- 在任何页面把 preview 写成系统已确认安排

## 6.3 Room 5 对未来的预留建议（不是本轮实现）
若未来 Room 1 明确 pin `previewDurations` 进入 active contract，Room 5 推荐位置如下：

### 推荐位置
- **StudyPage / ReviewPage：4 按钮区下方一行极轻 secondary hint**
- 样式：
  - 小号字
  - 中性灰
  - 不抢按钮
  - 不使用亮色奖励态

### 推荐交互
- 默认隐藏，仅在“按钮 hover / press / short press state”出现 —— 不适用于当前移动端优先场景
- 对移动端更推荐：**选中态瞬时显示、提交前消失**
- 但这些都必须等 contract pin 后再说

### 推荐文案语气
- “预计复习间隔”
- “预计下次复习”
- “仅供参考”
- 禁止写成“系统已安排”或“将于 X 天后复习”

---

## 7. ReviewPage FSRS bridge 风险下的 UI 边界

## 7.1 Room 5 结论
> **本轮用户可见层只接受“云端主流程继续正确 + 本地 bridge 不额外制造误导”。**

## 7.2 用户可见规则
1. cloud submit 成功后，ReviewPage 正常继续下一题 / 下一组
2. 即使本地 bridge fallback，也不弹用户错误
3. 但也不展示任何依赖 bridge 成功的解释性增强
4. 不把 bridge 成功当成用户可见奖励点

## 7.3 Room 5 对 Room 4 的表现层约束
- 不新增“本地复习已同步”
- 不新增“已更新你的复习计划”
- 不新增“下次复习时间已刷新”
- 不新增“学习模型已更新”之类系统感过强文案
- **本地 bridge fallback 虽不弹用户错误，但必须保留 dev/test 可观测性**（例如 debug log、diagnostic counter、可断言的 fallback branch）；不得做成完全无痕、不可测试的静默吞掉

---

## 8. 文案 / 防误报补强

## 8.1 Fact Copy 禁区
以下词在 P3.3.1 当前轮继续列为 **Fact Copy 禁区**：
- 掌握
- 完成
- 已会
- 已学会
- 奖励到账
- 已更新计划
- 已同步复习安排

## 8.2 可接受的系统表达
- 提交中
- 稍后重试（仅真实失败时）
- 本组复习完成（仅 groupCompleted 为 true）
- 开始今天的学习
- 先学一组新词

## 8.3 低阻力原则
1. 点击按钮后优先进入下一题，不追加解释负担
2. Study / Review 两页不额外弹解释弹层
3. 错误只在真正阻断主链路时显示
4. 正常成功不靠 toast 强提示，靠页面连续性表达“继续学”

---

## 9. State Contract Matrix（P3.3.1 delta）

## 9.1 4 按钮最终词面
- **UI state:** Study / Review 两页显示最终 frozen wording
- **Trigger rule / BR:** 需 Room 1 基于 Room 3 + Room 5 输入做 final wording freeze
- **Required fields / API:** 无新增 API
- **Local-only or source-of-truth:** UI copy layer
- **Loading / retry / stale behavior:** 不影响提交状态逻辑
- **Fact copy:** 按钮词面本质是 rating input，不是结果事实
- **Tone copy:** 可爱度收轻，不做太游戏化
- **Gap / blocker:** 等 Room 1 做 final freeze

## 9.2 previewDurations
- **UI state:** 当前不显示
- **Trigger rule / BR:** Room 2 judgment = deferred
- **Required fields / API:** 当前无 active contract
- **Local-only or source-of-truth:** 不成立
- **Loading / retry / stale behavior:** 不适用
- **Fact copy:** 不得展示任何“预计复习间隔”事实文案
- **Tone copy:** 不适用
- **Gap / blocker:** 当前继续 deferred

## 9.3 ReviewPage FSRS bridge
- **UI state:** 用户不可见的技术补强；可见层只体现主链路继续正确
- **Trigger rule / BR:** cloud-first / review_group truth / controlled best-effort bridge
- **Required fields / API:** 不新增 active contract
- **Local-only or source-of-truth:** bridge 为 side-effect，不是页面主真相
- **Loading / retry / stale behavior:** 不因 bridge fallback 产生用户错误弹层；但 fallback 必须保留 dev/test 可观测性
- **Fact copy:** 不得写“计划已更新 / 下次复习已确认”
- **Tone copy:** 无
- **Gap / blocker:** 若后续要显示 preview，需新一轮 contract pin

---

## 10. 对 Room 1 的建议

Room 1 后续吸收本稿时，建议只吸收以下结论：

1. **Room 5 推荐 final wording 候选：**
   - 不认识 / 模糊 / 记得 / 秒答

2. **Room 5 支持 Room 2 judgment：**
   - `previewDurations` 当前继续 deferred，不进入 active UI

3. **ReviewPage bridge 的 UI 边界：**
   - 只做“可控 best-effort 风险清理”
   - 不增加 bridge 成功型用户文案
   - 不在本轮显示依赖 bridge 的解释性 preview

4. **本轮 polish 重点：**
   - Study / Review 两页最终词面替换
   - false-success 文案清理
   - 提交中 disabled / 防重 / 低阻力连续性保持
   - HomeEntry 文案微调但不重构首页

---

## 11. 一句话结论

> **Room 5 对 P3.3.1 的建议是：用 `不认识 / 模糊 / 记得 / 秒答` 作为 4 按钮 final wording 的 UI 推荐集；`previewDurations` 本轮继续 deferred，不进入可见 UI；ReviewPage FSRS bridge 只收尾到“可控 best-effort”，用户可见层不新增任何依赖 bridge 成功的结果型或解释型文案。**
