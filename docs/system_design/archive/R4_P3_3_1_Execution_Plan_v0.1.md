# R4_P3_3_1_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2`
- **Direct upstream input:** `R1_to_R4_P3_3_1_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.1 决定，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮是否需要先升级
> **默认不需要先升级。**

但若执行层在实现中发现以下情况，必须立即升级，不得自行补脑推进：
1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 `review_group` 最小合同
4. 需要改变 planner owner
5. 需要把 `previewDurations` 偷偷做成 active contract
6. 需要新增用户可见的“计划已更新 / 已同步复习安排 / 下次将在 X 天后复习”一类事实表达

---

## 2. 本轮目标

完成 **P3.3.1 — 收尾 / 体验补强** 的执行收口，具体包括：

1. 将 Study / Review 4 按钮最终词面落地为：
   - 不认识
   - 模糊
   - 记得
   - 秒答
2. 保证 Study / Review 两页按钮顺序一致：
   - 左上：不认识
   - 右上：模糊
   - 左下：记得
   - 右下：秒答
3. 将 ReviewPage FSRS bridge 从“静默 best-effort”清理到“controlled best-effort”
4. 清理用户可见假事实文案
5. 做一轮测试补强与 fallback 可观测性补强

---

## 3. In Scope

1. StudyPage 4 按钮最终文案替换
2. ReviewPage 4 按钮最终文案替换
3. Study / Review 4 按钮顺序统一
4. 提交中 disable / 防重 / 防双击
5. ReviewPage cloud submit 成功后再进入本地 bridge
6. ReviewPage bridge 前补 idempotent local ensure / init（仅在需要且可幂等时）
7. ReviewPage bridge failure 的 fallback 可调试 / 可观察 / 可测试
8. UI / copy 的 fact-copy 禁区清理
9. 测试补强
10. 必要时产出 patch draft / doc sync note（仅草案，不代替 owner 改主文档）

---

## 4. Out of Scope

1. 不做 `previewDurations`
2. 不把 `previewDurations` 写进任何当前 active contract
3. 不重写完整 SRS / 完整 review planning
4. 不改 planner owner
5. 不改 `review_group` 最小合同
6. 不改 DB schema
7. 不改 API core semantics
8. 不把 Study / Review 合并成统一学习页
9. 不补首页 CTA winner 完整状态驱动系统
10. 不新增“系统已更新计划 / 已同步复习安排 / 下次将在 X 天后复习”类解释增强

---

## 5. 必守依据

### 根据需要读，不是必须一次性读完

### 5.1 推进层 / 主线程
- `Main_updated_2026-04-10_v19.md`
- `STATUS_updated_2026-04-10_v18.md`
- `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`
- `R1_to_R4_P3_3_1_Execution_Handoff_v0.1.md`

### 5.2 规则 / 文案边界
- `BR-OPP-001_v0.2.2.md`
- `R3_P3_3_1_Final_Wording_and_Bridge_Rules_Note_v0.1.md`

### 5.3 技术边界
- `R2_P3_3_1_PreviewDurations_and_FSRS_Bridge_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 5.4 UI / UX 表达边界
- `UI_SPEC_v0.2.2.md`
- `UI_SPEC_P3_3_1_Copy_Polish_and_PreviewDurations_Delta_v0.1.1.md`

---

## 6. Room 4 执行护栏

### 6.1 文案 / 假事实护栏
以下表达，本轮不得出现在：
- 按钮本体
- 成功反馈
- bridge 反馈
- 解释性提示
- 页面副文案

禁止：
- 已掌握
- 已会
- 会了
- 完成
- 奖励到账
- 已更新你的复习计划
- 已同步复习安排
- 下次将在 X 天后复习
- 学习模型已更新

### 6.2 结构护栏
- Study / Review 继续共用同一套 canonical rating key 顺序
- 不允许一页 again/hard/good/easy，另一页重排
- 不允许本轮因为文案替换引入第二套按钮系统

### 6.3 Bridge 护栏
- ReviewPage 继续 cloud-first
- 先 `submitReviewAttempt()`，再本地 FSRS bridge
- 本地 ensure / init 只能是幂等补强
- bridge failure 继续 non-blocking
- 但 failure 不能继续“治理层无感”

### 6.4 可观察性护栏
本轮至少保留一种 dev/test 可观察手段，例如：
- debug log
- diagnostic counter
- 可断言 fallback branch
- 等价的 test-observable 标记

### 6.5 升级护栏
若执行层发现必须触碰以下任一项，立即停下并回报：
- DB schema
- API core semantics
- `review_group` 最小合同
- planner owner
- active BR 事实
- `previewDurations` 合同化

---

## 7. 必测项

### 7.1 按钮词面与顺序
1. StudyPage 4 按钮词面为：
   - 不认识 / 模糊 / 记得 / 秒答
2. ReviewPage 4 按钮词面为：
   - 不认识 / 模糊 / 记得 / 秒答
3. 两页顺序一致
4. 映射顺序未错位（Again / Hard / Good / Easy）

### 7.2 提交与防重
1. StudyPage 点击后提交中 disable
2. ReviewPage 点击后提交中 disable
3. 双击 / 连击不造成重复提交
4. 正常成功优先进入下一题，而不是叠加多余提示

### 7.3 ReviewPage bridge
1. cloud submit success + local ensure existing row
2. cloud submit success + local ensure newly created row
3. cloud submit success + local bridge success
4. cloud submit success + local bridge failure but non-blocking continue
5. fallback branch 可观察 / 可断言
6. local bridge failure 不产生用户可见假事实文案

### 7.4 文案 / 假事实清理
1. 不出现“已掌握 / 已会 / 会了 / 完成 / 奖励到账”
2. 不出现“已更新计划 / 已同步复习安排 / 下次将在 X 天后复习”
3. `previewDurations` 当前不显示
4. 首页“背单词”入口不被补成算法型 / 规划型说明

---

## 8. 执行层交付物要求

执行层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **bridge fallback 如何可观察**
5. **仍未解决的问题**
6. **是否触碰核心契约的判断**
7. **需要哪些文档回写**
   - BR / UI / Main / Status / 其他
8. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 9. Room 4 验收判断口径

只有同时满足以下条件，Room 4 才会给出 `accept / 可 closeout` 倾向：

1. Study / Review 最终词面已统一落地
2. 按钮顺序未错位
3. `previewDurations` 未被偷偷实现 / 偷偷显示
4. ReviewPage bridge 已清理到 controlled best-effort
5. fallback 分支具备 dev / test 可观察性
6. 用户可见假事实文案已清理
7. 未越界触碰 DB / API / `review_group` / planner owner
8. 测试补强已交付

---

## 10. 给执行层的一句话

> **请按“词面已冻结、preview defer、bridge 只清到 controlled best-effort、重点补 UI / copy / test”的边界推进 P3.3.1；不要把本轮做成新的主契约扩张。**
