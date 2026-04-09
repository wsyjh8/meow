# R4_to_Cursor_P3_1_Delta_Phase1_Handoff_v0.1.md

- **From:** Room 4 (Eng + QA + Debug Tech Lead)
- **To:** Cursor
- **Project:** 背单词喵喵 App
- **Stage:** P3.1 direct-scope pin delta
- **Phase:** Phase 1
- **Goal:** Daily goal setting
- **Status of this handoff:** prepared in advance; executable when Room 4 confirms Phase 0 close
- **Important:** 你读不到我们项目文件，所以以下内容已经替你补齐。请严格按这份 handoff 执行，不要自行扩写需求。

---

## 0. 这份 handoff 的使用条件

这份是 **P3.1 delta / Phase 1** 的预备指令。

只有在 Room 4 明确确认以下条件后，你才执行这份 handoff：

1. **Phase 0 已通过 / 可 close**
2. delta entry / guard / regression fence 已建立
3. upload / download / restore 三层语义挡板已建立
4. 既有 P3.1 主线未被污染

如果 Phase 0 还没被 Room 4 放行，这份 handoff 先不要落代码。

---

## 1. 这轮到底做什么

这轮只做一件事：

> **把“设置每日学习单词数量”做成一个稳定、低风险、可测试的本地设置闭环。**

当前 direct-scope delta 的 3 个功能是：
1. 从云端下载进度到本机
2. 上传进度到云端
3. 设置每日学习单词数量

但 **Phase 1 只做第 3 个**。  
不要顺手碰 upload，也不要碰 download / restore。

---

## 2. 你必须服从的当前事实边界

### 2.1 当前项目状态
当前推进层状态仍然是：

> **P3.1 Reviewing / Restore Gate Pending**

因此：
- 这轮 delta 已被 User / Room 1 拉进范围
- 但不是自动生效的 active runtime truth
- 你的实现仍然必须服从当前 active versions 与 Room 4 phase gate

### 2.2 这轮功能的准确含义
本轮功能是：

> **用户点击“每日学习单词数量”，弹出数字输入组件；输入并确认后，更新当前设备本地的 daily goal 设置，并让 Today / 学习入口立即读取新值。**

这不是：
- 系统自动调参
- 智能目标推荐引擎
- 历史数据重算器
- 主业务表重构任务

### 2.3 当前仍成立的硬边界
你必须继续服从以下边界：

1. **当天即时生效**
2. **不回溯重算历史日**
3. **本地设置优先走 local settings lane**
4. **云端 snapshot 中的 `settings.daily_goal` 只会在下一次手动 upload 成功后才更新**
5. **当前 `1–500` 只是 recommended validation range，不是 frozen long-term BR**
6. **不能破坏主学习链路**
7. **不能顺手改 `daily_goal_status` 的核心业务语义**

---

## 3. 本轮允许做什么 / 不允许做什么

## 3.1 本轮允许做
1. 设置页 / 我的页中新增或接通 `每日学习单词数量` 入口
2. 数字输入弹层 / 输入框 / picker（按项目现有组件风格）
3. 正整数输入校验
4. 保存动作
5. 保存成功后本地立即生效
6. Today / 学习入口重新读取当前值
7. 错误提示
8. 相关测试与回归

## 3.2 本轮禁止做
1. 不做 upload
2. 不做 download-to-local
3. 不做 restore
4. 不做复杂推荐档位
5. 不做自适应目标引擎
6. 不做历史日重算
7. 不把 `1–500` 写死成永久业务真理
8. 不改写主学习链路已有奖励 / Session / streak 规则

---

## 4. 你应该怎么实现

## Step A — 找现有 local settings lane
先复用项目里已有的本地设置路径。

优先找：
- local settings service
- local repository / adapter
- DataStore / 等价 KV 层
- 现有设置页 / 我的页的数据绑定模式

不要为了这个功能新开一整套存储体系。

## Step B — 建立 daily goal setting 的最小读写闭环
至少要有：
1. 读取当前值
2. 展示当前值
3. 打开输入组件
4. 输入新值
5. 点击确认保存
6. 保存成功后刷新显示
7. Today / 学习入口使用新值

### 推荐命名（按项目风格可调整）
- `dailyGoal`
- `dailyGoalSetting`
- `updateDailyGoal`
- `saveDailyGoalSetting`
- `getDailyGoalSetting`

重点不是名字，而是：
- 语义清楚
- 不和“今日完成状态”混名
- 不和历史统计混名

## Step C — 输入校验
当前建议按 **Room 2 recommended validation range** 做：

- 允许：**正整数**
- 建议下限：`1`
- 建议上限：`500`

你必须显式处理以下非法输入：
1. 空值
2. 非数字
3. 小数
4. 负数
5. 0
6. 超过上限

### 要求
- 不能静默失败
- 不能自动吞掉非法值
- 不能把非法值保存成功
- 错误提示要明确，但不责备用户

## Step D — 生效边界写硬
本轮要明确做到：

1. **保存成功后，本地立即生效**
2. **Today / 学习入口重新读取当前值**
3. **历史日不回算**
4. **统计页若有历史数据，不因为这次改值而反推过去“其实完成 / 其实没完成”**
5. **云端 snapshot 的 `settings.daily_goal` 不在本轮自动更新，除非未来手动 upload 成功**

## Step E — 不污染主链路
这个功能不能导致：
- Today 主 CTA winner rule 被顺手改掉
- `daily_goal_status` 逻辑被偷偷改写
- Session 规则被影响
- `check_in / learning_day / streak` 关系被影响
- 奖励结算语义被影响

---

## 5. UI / UX 最小要求

你不需要重做视觉，只要把状态做清楚。

### 5.1 入口位置
默认优先放在：
- 设置页
- 我的页

不要把它放到：
- Today 主 CTA 中心
- 学习主流程里强打断
- Session 完成弹层里

### 5.2 默认展示
至少应展示：
- `每日学习单词数量`
- 当前值
- 可进入修改

### 5.3 输入组件
可接受：
- 数字输入框
- 弹层输入
- 底部 sheet + 数字输入
- 轻量 picker

### 5.4 成功与失败反馈
允许：
- 已更新
- 保存成功
- 当前值已生效

禁止：
- 已同步
- 所有设备已更新
- 历史数据已重算
- 今日任务已自动重置完成

---

## 6. 你这轮应该补的测试

## A. Read / write tests
覆盖：
1. 能读出当前 daily goal
2. 能保存合法新值
3. 保存后再次读取一致
4. App 重启 / 页面重进后仍能读到新值（若项目当前已有相应本地持久化能力）

## B. Validation tests
覆盖：
1. 空值报错
2. 非数字报错
3. 小数报错
4. 负数报错
5. 0 报错
6. 超过上限报错
7. 边界值 1 / 500 可通过

## C. Immediate-effect tests
覆盖：
1. 保存成功后当前显示值更新
2. Today / 学习入口读取到新值
3. 不需要重新安装 / 重登录才能生效

## D. No-history-recompute tests
覆盖：
1. 修改 daily goal 后，不重算历史日
2. 历史统计结果不被回改
3. 已有今日完成 / 未完成状态不会因为回溯逻辑被偷偷改写

## E. Regression tests
覆盖：
1. Today 主链路不受影响
2. 新词学习 / 复习 / Session / 签到不受影响
3. P3.1 既有 backup lane 不受影响
4. upload / download / restore 入口没有被顺手做出来

---

## 7. 代码改动原则

### 7.1 允许的改动风格
- small patch
- local-settings-first
- reuse-first
- explicit validation
- test-led
- regression-aware

### 7.2 禁止的改动风格
- 大重构
- 新开主业务表
- 顺手补推荐系统
- 顺手补 upload / download / restore
- 默默改 `daily_goal_status`
- 让非法输入“看起来保存成功”

---

## 8. 你完成后必须给出的输出

### A. 改动摘要
按文件列出：
- 设置页 / 我的页入口
- 本地 settings 读写
- 输入组件 / 保存动作
- validation
- tests

### B. 边界说明
请明确写：
1. 你如何保证它是“当前/后续生效”，而不是“历史日回算”
2. 你如何保证 `1–500` 只是当前实现采用的 recommended range
3. 你如何保证没有碰 upload / download / restore

### C. 自测结果
至少给出：
- 跑了哪些测试
- 新增哪些测试
- 总通过数 / 失败数
- 若有跳过项，说明原因

### D. 明确声明未做项
你必须明确写：
- 未做 upload
- 未做 download-to-local
- 未做 restore
- 未做历史日重算
- 未把 `1–500` 写成长期 frozen BR

---

## 9. Completion bar（Room 4 验收条）

只有同时满足以下条件，我才会判 Phase 1 通过：

1. `每日学习单词数量` 入口已成立
2. 输入 / 保存闭环已成立
3. 合法输入可保存，非法输入有显式反馈
4. 保存成功后本地立即生效
5. Today / 学习入口读取到新值
6. 历史日不回算
7. 既有主学习链路不受污染
8. 没有顺手做 upload / download / restore
9. 有 self-test summary

---

## 10. 最后一句

这轮你要做的不是“顺手把 delta 做大”，而是：

> **先把最小、最稳、规则最清楚的新增功能单独收稳。**

请按 **small patch + explicit validation + no-history-recompute + test-led** 风格推进。
