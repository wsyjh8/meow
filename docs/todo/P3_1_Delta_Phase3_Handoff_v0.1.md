# R4_to_Cursor_P3_1_Delta_Phase3_Handoff_v0.1.md

- **From:** Room 4 (Eng + QA + Debug Tech Lead)
- **To:** Cursor
- **Project:** 背单词喵喵 App
- **Stage:** P3.1 direct-scope pin delta
- **Phase:** Phase 3
- **Goal:** Download-to-local / latest snapshot apply first-shot
- **Status of this handoff:** prepared in advance; executable when Room 4 confirms Phase 2 close
- **Important:** 你读不到我们项目文件，所以以下内容已经替你补齐。请严格按这份 handoff 执行，不要自行扩写需求。

---

## 0. 这份 handoff 的使用条件

这份是 **P3.1 delta / Phase 3** 的预备指令。

只有在 Room 4 明确确认以下条件后，你才执行这份 handoff：

1. **Phase 2 已通过 / 可 close**
2. `manual upload + latest backup status` 已稳定落地
3. `upload / download / restore` 三层语义挡板仍保持成立
4. 当前实现仍未污染既有 P3.1 主线与主学习链路

如果 Phase 2 还没被 Room 4 放行，这份 handoff 先不要落代码。

---

## 1. 这轮到底做什么

这轮只做一件事：

> **把“从云端下载进度到本机”做成一个手动触发、带 pre-check / warning / confirm、并且只走 latest snapshot apply first-shot 的最小 restore 闭环。**

当前 direct-scope delta 的 3 个功能是：
1. 从云端下载进度到本机
2. 上传进度到云端
3. 设置每日学习单词数量

但 **Phase 3 只做第 1 个**。  
不要顺手碰 delete backup / clear local，也不要扩成 restore platform / sync center。

---

## 2. 你必须服从的当前事实边界

### 2.1 当前项目状态
当前推进层状态仍然是：

> **P3.1 Reviewing / Restore Gate Pending**

因此：
- 这轮 delta 已被 User / Room 1 拉进范围
- 但仍不是自动生效的 active runtime truth
- 你的实现必须继续服从 Room 4 phase gate 与当前 active versions

### 2.2 本轮功能的准确含义
本轮功能是：

> **用户手动触发，把最近一次云端备份 snapshot 下载到本机；在通过 pre-check、看过 warning、完成 confirm 后，执行 latest snapshot apply first-shot，把允许进入当前范围的 snapshot 数据恢复到当前设备本地运行态。**

这不是：
- 实时双向同步
- 后台自动恢复
- 登录即自动恢复
- snapshot picker
- partial restore
- merge engine
- 多设备自动对齐

### 2.3 当前仍成立的硬边界
你必须继续服从以下边界：

1. **manual only**
2. **warning first**
3. **confirm required**
4. **download completed != restore success**
5. **restore success != sync success**
6. **云端当前仍是 backup container，不是 runtime truth / sync truth**
7. **当前实现只走 latest snapshot apply first-shot**
8. **不做 snapshot picker**
9. **不做 partial restore**
10. **不做 merge**
11. **不做 silent overwrite**
12. **不做 destructive actions**
13. **不破坏主学习链路，不抢 Today 主 CTA**

---

## 3. 本轮允许做什么 / 不允许做什么

## 3.1 本轮允许做
1. 设置页 / 我的页中的 `从云端下载进度到本机` 入口
2. restore pre-check
3. warning
4. confirm
5. latest snapshot download
6. latest snapshot apply first-shot
7. restore result state
8. 错误提示与失败态
9. 相关测试与回归

## 3.2 本轮禁止做
1. 不做 snapshot picker
2. 不做 partial restore
3. 不做 merge
4. 不做 background sync
5. 不做 full sync
6. 不做 delete backup
7. 不做 clear local
8. 不做 destructive actions bundle
9. 不把云端写成 current runtime truth
10. 不顺手回改 Phase 1 / Phase 2 已落地逻辑

---

## 4. 你应该怎么实现

## Step A — 建 restore pre-check
不要直接点击按钮就开始 apply。

pre-check 至少要回答：
1. 当前是否存在可恢复备份
2. 备份 schema version 是否受支持
3. 当前设备是否允许进入恢复
4. 当前 restore 目标是否明确为 **current device local store**
5. 当前是否满足进入 confirm 的条件

### 推荐结果分类
- `restorable`
- `not_restorable`
- `backup_not_found`
- `version_not_supported`
- `temporarily_unavailable`

## Step B — 做 warning + confirm
warning 必须至少明确告诉用户：

1. 这是把云端备份恢复到**当前设备本机**
2. **可能覆盖当前本机相关学习进度**
3. **也可能覆盖已进入 snapshot 范围的设置项**，例如 `daily_goal`
4. 这**不是自动同步**
5. 这**不代表其他设备也自动一致**
6. 如有必要，可提示“建议先手动上传当前设备进度”

confirm 要求：
- 不确认，不执行
- 用户必须显式点确认按钮
- warning / confirm 缺一不可

## Step C — latest snapshot download
本轮只允许：
- 拉取 / 读取 **latest snapshot**
- 下载成功只代表 **download completed**

必须写硬：
- `download completed != restore success`
- download 层动作本身**不允许**改变本地 runtime state

## Step D — latest snapshot apply first-shot
apply 只允许在：
- pre-check 通过
- confirm 完成
- latest snapshot 已拿到

之后执行。

### 当前默认 apply 边界
1. 只恢复当前 snapshot scope 内已允许进入的实体
2. 当前风险提示必须覆盖：
   - progress overwrite
   - settings overwrite（例如 `daily_goal`）
3. secondary runtime state 默认继续排除在 restore-first 范围外，除非 Room 1 后续单独 pin
4. 只有 `apply success / restore success` 才允许改变本地 runtime state

### 高风险写操作要求
restore-apply 按高风险写操作处理，要求：
- request / backup_id / target 级别可追踪
- 保持幂等语义
- 避免重复 apply 造成双写或多次覆盖
- apply 失败时不能停在假成功态

## Step E — 结果态
至少要支持：
- pre-check failed
- warning shown
- confirm required
- downloading
- applying
- restore succeeded
- restore failed
- version not supported
- no backup found
- temporarily unavailable

---

## 5. UI / UX 最小要求

### 5.1 入口位置
默认优先放在：
- 设置页
- 我的页

不要放在：
- Today 主 CTA 中心
- 学习主流程中间
- Session 完成弹层主位

### 5.2 默认展示
至少应展示：
- 从云端下载进度到本机
- 必要时的副文案：`将把最近一次云端备份恢复到当前设备`
- warning / confirm
- restore 结果反馈

### 5.3 文案与状态表达边界
### 允许
- 从云端下载进度到本机
- 已完成下载
- 正在恢复
- 已恢复到本机
- 当前设备数据已更新
- 可能覆盖当前本机相关学习进度
- 也可能覆盖设置项（例如每日学习目标）

### 禁止
- 已同步
- 所有设备已一致
- 自动同步成功
- 一键全平台同步
- 无风险恢复
- 自动恢复完成

---

## 6. 你这轮应该补的测试

## A. Pre-check tests
覆盖：
1. 有可恢复备份
2. 无备份
3. 版本不支持
4. 暂不可用
5. pre-check 失败不进入 apply

## B. Warning / confirm tests
覆盖：
1. warning 出现
2. confirm 必须显式点击
3. 不确认不能执行
4. warning 明确覆盖：
   - progress overwrite risk
   - settings overwrite risk（如 `daily_goal`）
   - 这不是自动同步

## C. Download / restore semantics tests
覆盖：
1. `download completed != restore success`
2. download completed 不会改变本地 runtime state
3. 只有 `apply success / restore success` 才允许改变本地结果
4. `restore success != sync success`
5. 不出现“已同步”“所有设备已一致”

## D. Apply tests
覆盖：
1. latest snapshot apply first-shot 可成功执行
2. apply 失败不会停在假成功态
3. restore-apply 具备 request / backup_id / target 级别可追踪
4. apply 具备幂等语义
5. secondary runtime state 没被顺手带进恢复范围

## E. Regression tests
覆盖：
1. Today 主链路不受影响
2. 新词学习 / 复习 / Session / 签到不受影响
3. Phase 1 的 daily goal setting 不受影响
4. Phase 2 的 manual upload + latest backup status 不受影响
5. destructive actions 没有被顺手做出来

---

## 7. 代码改动原则

### 7.1 允许的改动风格
- small patch
- pre-check-first
- warning-first
- confirm-first
- latest-snapshot-first
- apply-minimally
- test-led
- no-sync-overclaim

### 7.2 禁止的改动风格
- 大重构
- 顺手扩成 restore platform
- 顺手做 snapshot picker
- 顺手做 partial restore
- 顺手做 merge
- 顺手做 delete backup / clear local
- 让文案先写“已同步”图省事
- 把 download / restore / sync 三层语义混写

---

## 8. 你完成后必须给出的输出

### A. 改动摘要
按文件列出：
- restore entry
- pre-check
- warning / confirm
- latest snapshot download
- apply
- result state
- tests

### B. 边界说明
请明确写：
1. 你如何保证这轮仍然只是 latest snapshot apply first-shot
2. 你如何保证 `download completed != restore success`
3. 你如何保证 warning 覆盖了 progress 与 settings（如 `daily_goal`）的覆盖风险
4. 你如何保证没有顺手做 destructive actions / merge / snapshot picker

### C. 自测结果
至少给出：
- 跑了哪些测试
- 新增哪些测试
- 总通过数 / 失败数
- 若有跳过项，说明原因

### D. 明确声明未做项
你必须明确写：
- 未做 snapshot picker
- 未做 partial restore
- 未做 merge
- 未做 delete backup
- 未做 clear local
- 未做 full sync / background sync

---

## 9. Completion bar（Room 4 验收条）

只有同时满足以下条件，我才会判 Phase 3 通过：

1. `从云端下载进度到本机` 入口已成立
2. pre-check 已成立
3. warning + confirm 已成立
4. latest snapshot apply first-shot 已成立
5. `download completed != restore success`
6. progress + settings overwrite risk 已清楚提示
7. 文案不误导成 sync
8. 既有主学习链路不受污染
9. 没有顺手做 destructive actions / picker / merge
10. 有 self-test summary

---

## 10. 最后一句

这轮你要做的不是“把恢复平台做出来”，而是：

> **先把 latest snapshot apply first-shot 这个高风险、强确认、低误导的最小闭环收稳。**

请按 **small patch + warning/confirm first + latest-only + no-sync-overclaim + test-led** 风格推进。
