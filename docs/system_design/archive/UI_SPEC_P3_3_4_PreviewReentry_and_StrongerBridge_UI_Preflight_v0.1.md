# UI_SPEC_P3_3_4_PreviewReentry_and_StrongerBridge_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.4 — Preview Re-entry + Stronger Bridge Round`
- **Direct upstream input:** `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `p3.3.4_user.md` + `BR-OPP-001_v0.2.5.md` + `UI_SPEC_v0.2.5.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.4 当前轮需要进一步收口的 4 个问题，翻成可被 Room 1 判断是否 pin 的最小 UI 合同层。**

本稿不是：
- 新 UI 主文档
- 新 BR / DB / API 主文档
- Room 4 执行单
- 完整复习规划产品稿
- auto-routing / unified planner 方案
- 完整 preview explanation system

一句话：

> **P3.3.4 在 Room 5 视角，继续前进，但只前进到“preview 的最小回归候选 + stronger bridge 的页面边界 + 最小测试 / 回写合同”的窄合同层。**

---

## 1. 输入依据

### 1.1 主线程 handoff basis
- `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 当前 review / runtime basis
- `BR-OPP-001_v0.2.5.md`
- `UI_SPEC_v0.2.5.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 1.3 用户直接拍板输入
- `p3.3.4_user.md`

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持本轮从 pure preflight 前进一步，但只支持进入 “StudyPage 上的 preview 最小回归候选 + ReviewPage stronger bridge 的页面事实边界” 的 very narrow UI contract。**

### 2.2 为什么应该前进一步
因为 P3.3.3 结束后，当前 UI 侧已经把这些问题卡在门口：
1. `previewDurations` 未来若回来，到底落在哪一页、哪一层、什么语气
2. ReviewPage stronger bridge 如果要推进，哪些页面状态会受影响
3. 哪些话一旦出现，就会把“候选提示 / 解释增强”误写成“稳定计划事实”
4. 若本轮真进入下一层合同，测试与回写最少要写到什么程度

### 2.3 为什么不能走更深
本轮仍不能越界到：
- auto-routing runtime
- unified planner / planner merge
- unified Study / Review page
- exact group size contract
- full priority scoring
- 完整 SRS / 完整 review planning product
- 完整 preview explanation system

---

## 3. `preview_durations_reentry_contract_v1`（Room 5 页面版）

## 3.1 Room 5 当前推荐结论
> **若 P3.3.4 要让 `previewDurations` 从 deferred 前进一步，Room 5 推荐只做 StudyPage-only、hint-only、estimated-only 的最小回归候选。**

### 3.1.1 这意味着什么
1. **只进 StudyPage**
2. **只作为 secondary hint**
3. **只表达 estimated / candidate，不表达已确定安排**
4. **不进入首页**
5. **不进入 ReviewPage**
6. **不写成稳定计划事实**

---

## 4. Preview 落位建议

## 4.1 推荐落位
### StudyPage
- 位置：**4 按钮区下方一行极轻 secondary hint**
- 样式：
  - 小号字
  - 中性灰
  - 低强调
  - 不抢按钮
  - 不使用奖励色 / 高饱和强调色
- 目的：
  - 只提供“这次 rating 可能带来的大致间隔感”
  - 不承担 schedule explanation 主层职责

### Room 5 推荐示例
- `预计间隔：1 天（仅供参考）`
- `预计间隔：3 天（仅供参考）`
- `预计间隔：7 天（仅供参考）`

> 这里的“预计间隔”比“下次将在 X 天后复习”更安全，因为它更像 hint，不像承诺。

## 4.2 当前不推荐的落位
### ReviewPage
当前仍**不推荐**把 preview 放进 ReviewPage。

原因：
1. ReviewPage 当前主 truth 仍围绕 cloud `review_group`
2. stronger bridge 本轮即使推进，也仍不等于 unified planner 已成立
3. 把 preview 放进 ReviewPage，最容易被理解成：
   - 系统已重新安排复习
   - 云端已确认下次计划
   - 当前 ReviewPage 也已进入稳定解释层

### SpecHomePage
当前不推荐：
- 放在首页 CTA 下
- 放在 review summary block
- 放在 continuation 卡片里
因为这些位置都过于像“今日计划说明层”，风险太高。

---

## 5. Preview 的 source / truth 边界（UI 视角）

## 5.1 Room 5 当前建议
> **P3.3.4 若进入 preview 最小回归候选，页面层可接受的 UI 口径应是：preview 来自 local FSRS candidate output，但它不是 serving truth，也不是已确认计划。**

### 5.1.1 页面层的翻译
这意味着：
- 可以显示“预计”
- 可以显示“仅供参考”
- 不可以显示“系统已安排”
- 不可以显示“下次将在 X 天后复习”
- 不可以把 preview 当作 ReviewPage / 首页的事实来源

## 5.2 Room 5 当前最安全的写法
- **source of truth（页面事实层）不是 preview**
- preview 只是 **candidate explanation hint**
- 它必须显式带不确定性语气

---

## 6. explanation 语气与 fact-copy 边界

## 6.1 Room 5 当前正式结论
> **若 P3.3.4 允许 preview 最小回归，页面文案必须显式包含“预计 / 仅供参考”语气。**

### 6.1.1 原因
因为只要去掉这层语气，用户就会自然理解为：
- 系统已经确定安排
- 下次一定在 X 天后复习
- 当前规划已同步完成

这和当前 BR / UI 一直在守的 fact boundary 冲突。

## 6.2 允许的表达
- `预计间隔：1 天（仅供参考）`
- `预计间隔：3 天（仅供参考）`
- `预计间隔：7 天（仅供参考）`
- `仅供参考`

## 6.3 禁止的表达
以下表达在 P3.3.4 当前轮继续列为 **Fact Copy 禁区**：
1. 下次将在 X 天后复习
2. 系统已安排
3. 已更新计划
4. 已同步复习安排
5. 已为你生成复习计划
6. 学习模型已更新
7. 当前计划已确认
8. 已根据你的表现自动重排学习路径

---

## 7. `reviewpage_stronger_bridge_contract_v1`（Room 5 页面版）

## 7.1 Room 5 当前结论
> **Room 5 支持 stronger bridge 从 `controlled best-effort` 前进一步，但前进方向应该是“更稳的后台合同 + 更硬的用户事实边界”，而不是做成用户可见的新计划事实。**

## 7.2 stronger bridge 会影响哪些页面
### A. ReviewPage
直接受影响最大。

### B. StudyPage
只受间接影响：
- 若 preview 最终允许回归，StudyPage 可能因此获得更稳的 local preview candidate 来源

### C. 首页
当前不应直接受 stronger bridge 影响。

---

## 8. ReviewPage 当前页面边界（P3.3.4 候选）

## 8.1 当前仍应保持
1. ReviewPage 继续表现 `cloud-first`
2. group progress / remaining / group completion 继续围绕 cloud `review_group`
3. bridge failure 仍不弹用户错误
4. bridge 不产出用户可依赖的新计划文案

## 8.2 stronger bridge 允许带来的页面级收益
如果 stronger bridge 进入下一层合同，Room 5 只接受它带来以下“弱可见收益”：
1. 页面更少出现由本地 card 缺失导致的内部异常
2. 更少出现 dev/test 不可复现的灰区
3. 更少出现“本轮提交完后本地侧状态没补上”的隐藏一致性问题

## 8.3 stronger bridge 仍不能带来的页面效果
即使 stronger bridge 前进一步，当前仍**不能**写成：
1. 已更新你的复习计划
2. 下次将在 X 天后复习
3. 已同步复习安排
4. 已切换到最佳复习模式
5. 本地计划已接管
6. unified planner 已成立

---

## 9. ReviewPage 是否仍禁止 preview 显示

## 9.1 Room 5 正式结论
> **是。当前仍应禁止在 ReviewPage 显示 preview。**

### 9.1.1 原因
1. ReviewPage 主 truth 仍是 cloud serving layer
2. stronger bridge 即使前进一步，也只是 bridge stronger，不是 planner merge
3. 把 preview 放进 ReviewPage，会直接模糊：
   - serving truth
   - scheduling candidate
   - explanation hint
   这三层的边界

### 9.1.2 Room 5 的更直白说法
> **P3.3.4 可以尝试把 preview 作为 StudyPage 的小提示带回来，但不应借此把 ReviewPage 也拖进解释层。**

---

## 10. 最小测试与回写合同（Room 5）

## 10.1 Room 5 建议必须具备的最小断言
如果 P3.3.4 最终被 Room 1 pin 进 very narrow execution layer，Room 5 建议至少写入以下断言：

### Preview 显示 / 不显示
1. StudyPage 在 contract 满足时，preview 可显示
2. StudyPage 在 contract 不满足时，preview 不显示
3. ReviewPage 始终不显示 preview
4. 首页不显示 preview

### Preview 文案
5. preview 必须包含“预计 / 仅供参考”语气
6. preview 不得出现“下次将在 X 天后复习 / 系统已安排 / 已更新计划”

### Stronger bridge 行为
7. stronger bridge failure 仍不弹用户错误
8. stronger bridge 不得改变 cloud-first 主链路
9. stronger bridge 不得引入新的结果型用户文案
10. stronger bridge 的 dev/test 可观测性必须保留

## 10.2 最小回写要求
若 P3.3.4 后续进入 execution 并有真实 landing，Room 5 预期至少要有：
1. BR patch draft
2. UI patch draft
3. 受影响页面清单
4. preview / bridge 的文案禁区同步说明

---

## 11. Room 5 对 Room 1 的建议

### 11.1 Room 5 建议 Room 1 可吸收的最小合同层
Room 1 若要在本轮继续向前 pin，一次最多建议吸收以下 4 条：

1. **`preview_durations_reentry_contract_v1` 当前若进入，只进入 StudyPage-only + hint-only + estimated-only**
2. **preview 文案必须显式带“预计 / 仅供参考”**
3. **ReviewPage 当前继续禁止显示 preview**
4. **`reviewpage_stronger_bridge_contract_v1` 若前进，只前进到更稳的幕后合同层，不前进到新的用户计划事实层**

### 11.2 Room 5 不建议本轮吸收成 runtime truth 的内容
1. Study + Review 双页 preview
2. 首页 preview
3. planner explanation 层
4. “下次将在 X 天后复习”这类 schedule fact 文案
5. unified planner / planner merge
6. auto-routing runtime
7. 完整 preview explanation system

---

## 12. Room 5 一句话结论

> **P3.3.4 在 Room 5 视角，可以前进一步，但最稳的方向是：只把 `previewDurations` 推进到 StudyPage-only、hint-only、estimated-only 的最小回归候选，同时把 ReviewPage stronger bridge 收成更稳的后台合同与更硬的文案禁区；ReviewPage 当前仍应禁止 preview，所有会把 preview / bridge 写成完整计划事实的表达都继续禁止。**
