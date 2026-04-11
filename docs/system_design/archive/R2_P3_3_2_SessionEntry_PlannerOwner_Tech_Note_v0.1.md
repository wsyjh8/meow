# R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** active / technical framing first pass / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round basis:** `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.3.md`
  - `UI_SPEC_v0.2.3.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`

---

## 0. 文档目的

本文件不是：
- 新 DB 主文档
- 新 API 主文档
- 新 BR 主文档
- Room 4 执行单
- 完整复习算法设计稿

本文件只做一件事：

> **从 Room 2 视角，先把 `P3.3.2 — Review Planning Deepening / Contract Gate` 的技术边界、owner split、最小可进入层与不该越线处收口。**

一句话：

> **先决定“入口怎么定、谁是 planner owner、最低能进入哪层 contract”，再决定要不要让 Room 4 做。**

---

## 1. 输入依据与读法

### 1.1 本轮直接输入
- `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 规则与页面参考
- `BR-OPP-001_v0.2.3.md`
- `UI_SPEC_v0.2.3.md`

### 1.3 当前 active 技术基线
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 1.4 Room 2 读法
Room 2 本轮不重做完整复习系统设计，而是只回答以下 6 件事：
1. 当前 dual-store 下，session entry 的技术分流现实是什么
2. planner owner 当前最合理是谁
3. `review_group` 与本地 FSRS 的最低稳定分工是什么
4. 如果进入 next-layer review planning contract，最小可进入层是什么
5. 当前轮若进入，会不会触碰 DB / API / planner owner / `review_group` 最小合同
6. Room 2 推荐 keep preflight 还是 enter next-layer minimal contract

---

## 2. Room 2 总判断

### 2.1 总结论
> **Room 2 推荐：进入 `next-layer minimal contract`，但只进入一层很窄的合同；不进入完整 review planning contract，不进入实现层。**

这层最小合同只应该冻结两件事：
1. **`session_entry_policy_v1`**
2. **`planner_owner_split_v1`**

而以下内容继续保持 pending：
- 完整 SRS / 完整复习调度算法
- 完整 session 自动分流
- complete planner merge
- `previewDurations` / interval preview
- stronger ReviewPage bridge contract
- unified Study / Review page

### 2.2 为什么不是继续纯 preflight
如果继续只停在“讨论 review planning”，Room 4 以后还是会在以下点上被迫补脑：
1. 首页“背单词”到底是不是未来的自动分流入口
2. active `review_group` continuation 到底只是 CTA 优先级，还是会吞掉 `/study` 入口
3. 云端 `review_group` 与本地 FSRS 到底谁在复习页说了算
4. 本地 FSRS 到底只是 side-effect，还是未来已默认接近 planner

这些问题已经足够影响后续 BR / UI / TEST / implementation framing，继续完全不写，会留下推进空洞。

### 2.3 为什么也不能一下子进入更深合同
因为再往下走，就会立刻撞上当前 round 明确 out-of-scope 的内容：
- DB schema 改动
- API core semantics 改动
- `review_group` 最小合同改动
- 本地 FSRS 升格成唯一 planner owner
- 首页 CTA winner 重写成完整状态驱动系统
- preview / schedule explanation 重新打开

所以本轮可以前进一步，但只能是 **窄一步**。

---

## 3. 必答问题逐项回答

## 3.1 Q1 — 当前 dual-store 下，session entry 的技术分流现实是什么

### 3.1.1 当前实现现实
当前代码与文档现实里，首页“背单词”主入口是：
- **点击后进入 `/study` / StudyPage**
- 既有“5 分钟快速复习”入口仍单独进入 `/review`
- 当前不存在已冻结的首页点击后自动分流 contract
- 当前也不存在已冻结的“点击背单词后，根据 active `review_group` / due cards / mixed mode 自动改路由”合同

### 3.1.2 Room 2 正式表述
因此，当前 dual-store 下的 session entry 技术现实应表述为：

> **`home_word_entry = study_default` 仍是当前最稳定 reality；review continuation 与 review priority 仍通过独立 review path / CTA path 承接，而不是通过对“背单词”入口做 silent reroute 来承接。**

### 3.1.3 这意味着什么
这意味着：
1. 首页“背单词”目前是 **default study entry**，不是 review planner dispatcher
2. `active_review_group` 的优先级问题，当前属于 **decision-support / CTA / product policy** 问题，不是现成的入口自动分流合同
3. 若未来要进入自动分流，必须单独 pin 一轮 contract，而不是把现有首页入口解释成“其实已经是动态规划入口”

---

## 3.2 Q2 — planner owner 当前最合理是谁

### 3.2.1 Room 2 结论
> **当前最合理的不是单一 planner owner，而是“分层 owner split”。**

### 3.2.2 当前推荐 owner split
#### A. Cloud `review_group` owner（当前 ReviewPage 主 owner）
负责：
- review queue
- active group continuation
- group completion
- settlement trigger on review path
- readiness / next-item serving on review path

#### B. Local FSRS owner（当前设备侧 card scheduling owner）
负责：
- local card state
- interval / scheduling calculation on local memory layer
- review logs
- local ensure / init / side-effect after submit
- future preview candidate inputs（仅候选，不是当前 active contract）

### 3.2.3 Room 2 正式判断
因此本轮不能把 planner owner 写成：
- “云端完全 owner everything”
- 或“本地 FSRS 已经实际 owner everything”

当前最稳的说法是：

> **ReviewPage 的 queue / continuation / completion truth owner 仍是 cloud `review_group`；local FSRS 仍是 device-side scheduling owner，但在复习页路径上只以 side-effect / local scheduling reality 存在。**

---

## 3.3 Q3 — `review_group` 与本地 FSRS 的最低稳定分工是什么

### 3.3.1 最低稳定分工（Room 2 v0.1）
#### Cloud `review_group` 继续负责
1. 复习队列发放
2. 当前 group 的 continuation
3. group completion 判定
4. review path 下 settlement 主链路
5. 复习页主真相层

#### Local FSRS 继续负责
1. 本地 card state
2. rating → interval / stability / difficulty 的设备侧运算
3. review logs 落地
4. `init / ensure-local-card-state`
5. 作为 future preview / local planning 的候选能力来源

#### Submit 后的顺序继续保持
1. cloud submit first
2. local FSRS side-effect second
3. local failure non-blocking
4. fallback must remain observable to dev/test

### 3.3.2 一句话定义
> **Cloud owns review serving truth; local owns device scheduling truth; ReviewPage 仍然是 cloud-first + local side-effect。**

### 3.3.3 当前明确不能越界的地方
本轮不得把 local FSRS 改写成：
- ReviewPage 主队列 owner
- group continuation owner
- group completion owner
- settlement gating owner
- review readiness 最终真相源

---

## 3.4 Q4 — 如果进入 next-layer review planning contract，最小可进入层是什么

### 3.4.1 Room 2 推荐的最小进入层
> **推荐进入：`Session Entry Policy + Planner Owner Split` 双合同层。**

即只进入以下两块：

#### 合同 A：`session_entry_policy_v1`
只冻结：
1. 首页“背单词”继续是 `study_default`
2. `active_review_group` continuation 的高优先级继续存在，但当前通过独立 review path / CTA 承接，不通过 silent reroute 承接
3. 本轮不进入 mixed / auto-routing runtime contract
4. 若未来要自动分流，必须单开新 round pin

#### 合同 B：`planner_owner_split_v1`
只冻结：
1. ReviewPage 主队列 / continuation / completion / settlement truth = cloud `review_group`
2. 本地 FSRS = local scheduling / side-effect owner
3. ReviewPage 继续 `cloud-first + local side-effect`
4. local ensure / init 可继续增强，但不得改变 planner owner

### 3.4.2 为什么这就是最小可进入层
因为这层：
- 已足以给 Room 3 写语义边界
- 已足以给 Room 5 写 UI 承接边界
- 已足以阻止 Room 4 后续补脑
- 但还没有跨入 DB/API 重设计

### 3.4.3 当前不建议进入的层
本轮不建议进入：
1. planner result contract（例如统一 preview / next interval explanation）
2. merged queue contract
3. mixed planner arbitration contract
4. unified study-review session contract
5. cloud/local 双向 sync / preload / backfill contract

---

## 3.5 Q5 — 当前轮若进入，会不会触碰 DB / API / planner owner / `review_group` 最小合同

### 3.5.1 Room 2 结论
> **若按本稿推荐的 narrow contract 进入，不触碰 DB schema，不触碰 API core semantics，不改变 planner owner，也不改 `review_group` 最小合同。**

### 3.5.2 原因
因为本稿推荐进入的层级只定义：
- 入口策略
- owner split
- contract gate
- out-of-scope boundary

而不定义：
- 新 API 字段
- 新 DB 实体
- 新 planner data shape
- 新 completion semantics
- 新 queue source

### 3.5.3 一旦出现以下动作，就代表越界
以下任一动作出现，即从本轮建议范围越界为 Major：
1. 给 `/me/today` 或 review endpoints 新增必须依赖的 planner 字段
2. 新增本地 planner-ready 表达，要求 ReviewPage 依赖其成功
3. 改 `review_group` completion / continuation 语义
4. 把本地 FSRS due cards 直接接成 ReviewPage 主入口
5. 让首页“背单词”点击后 silent reroute 到 review / mixed mode
6. 把 preview / next interval 暴露成当前稳定事实

---

## 3.6 Q6 — Room 2 推荐 keep preflight 还是 enter next-layer minimal contract

### 3.6.1 Room 2 正式推荐
> **推荐：enter next-layer minimal contract。**

但要明确：
- 不是进入 next-layer execution
- 不是进入 full review planning contract
- 不是进入 planner merge
- 不是进入 DB/API expansion

### 3.6.2 推荐后的具体范围
建议 Room 1 若吸收本稿，只 pin：
1. `session_entry_policy_v1`
2. `planner_owner_split_v1`
3. 本轮不做项与越界红线

### 3.6.3 不推荐方案
不推荐方案 A：**继续完全停留在 preflight**
- 问题：会把“入口”和“planner owner”继续留成空白区，后面 Review / UI / implementation 都会反复补脑

不推荐方案 B：**直接进入更深 review planning contract**
- 问题：会过早碰到 DB / API / planner merge / review_group contract 变更，超出本轮 gate

---

## 4. Room 2 推荐方案（可供 Room 1 吸收）

## 4.1 推荐方案
### 方案名
**Narrow Contract Entry — `Session Entry Policy v1` + `Planner Owner Split v1`**

### 内容
#### `Session Entry Policy v1`
1. 首页“背单词”继续定义为 `study_default`
2. active `review_group` continuation 在规则层 / CTA 层继续可高优先，但本轮不通过 silent reroute 接管“背单词”入口
3. `/review` 继续是 review continuation 的显式路径
4. mixed / auto-routing 继续 pending

#### `Planner Owner Split v1`
1. cloud `review_group` = review serving truth owner
2. local FSRS = local scheduling owner
3. ReviewPage = `cloud-first + local side-effect`
4. stronger bridge / preview / unified planner 继续 pending

---

## 4.2 不推荐方案
### 不推荐方案 1：Pure Preflight Hold
- 保持所有点继续 pending
- 不冻结入口策略
- 不冻结 owner split

**为什么不推荐：**
会把真正已经影响跨 Room 协作的技术边界继续空置。

### 不推荐方案 2：Deep Contract Entry
- 直接冻结 mixed routing
- 直接冻结 planner merge
- 直接要求 preview / interval explanation 进入 contract
- 直接要求 ReviewPage 依赖更强 local FSRS 成功

**为什么不推荐：**
会超出本轮 scope，并逼近 DB/API/`review_group` 合同改动。

---

## 5. 风险边界（Room 2 必写）

## 5.1 本轮可以接受的风险
1. 首页“背单词”继续不是最聪明的入口，只是最稳定的入口
2. active `review_group` 的更强优先级仍留在 CTA / product 层进一步收敛
3. local FSRS 与 cloud `review_group` 继续并存，不追求本轮统一成一个 planner

## 5.2 本轮不能接受的风险
1. 让 ReviewPage 的主队列 owner 变得模糊
2. 让本地 FSRS 被误写成已接管 review planning
3. 让首页“背单词”偷偷变成 auto-routing dispatcher
4. 让 UI 出现“已更新复习计划 / 下次 X 天后复习”之类超前事实
5. 让 Room 4 在没有新 execution handoff 的前提下开始实现更深 planner contract

---

## 6. 对 Room 3 / Room 5 的后续约束建议

## 6.1 给 Room 3
Room 3 下一轮建议只在以下层面收口：
1. `home_word_entry = study_default` 的业务语义
2. active `review_group` continuation 高优先，但当前不等于 silent reroute
3. planner owner split 的业务语义边界
4. mixed / auto-routing / unified planner 继续 pending

## 6.2 给 Room 5
Room 5 下一轮建议只在以下层面展开：
1. 首页“背单词”点击后的承接仍按 `StudyPage` 默认路径处理
2. 若要体现 active `review_group` continuation 优先，应通过独立 CTA / helper / priority block 讨论，不应默认吞掉“背单词”入口
3. 不新增依赖 planner merge 或 preview explanation 的状态表达
4. 不把 local FSRS bridge 成败写成用户可依赖结果

---

## 7. Done 对齐（对 Room 1 的直接回应）

本稿已回答：
1. 当前 dual-store 下，session entry 的技术分流现实是什么
2. planner owner 当前最合理是谁
3. `review_group` 与本地 FSRS 的最低稳定分工是什么
4. 如果进入 next-layer review planning contract，最小可进入层是什么
5. 当前轮若进入，会不会触碰 DB / API / planner owner / `review_group` 最小合同
6. Room 2 推荐：**enter next-layer minimal contract**，不建议继续 pure preflight，也不建议直接 deeper contract

---

## 8. Room 2 一句话结论

> **P3.3.2 可以前进一步，但只能前进到“入口策略 + owner split”的窄合同层：`home_word_entry` 继续保持 `study_default`，ReviewPage 继续保持 `cloud-first + local side-effect`，cloud `review_group` 与 local FSRS 继续分层共存；任何更深的 planner merge / auto-routing / preview contract 都应继续 pending。**
