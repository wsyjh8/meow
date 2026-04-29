# R1_to_R4_P3_3_15_DirectCutover_Execution_Handoff_v0.1

- **Owner:** Room 1  
- **Project:** 背单词喵喵 App  
- **Version:** v0.1  
- **Date:** 2026-04-11  
- **Status:** active / user-direct-decision / ready for Room 4  
- **Role basis:** `room1_v0.3.1.md`  
- **Round:** `P3.3.15 — Direct Cutover Round`  
- **Runtime basis:** `Main_updated_2026-04-11_v35.md` + `STATUS_updated_2026-04-11_v33.md`  
- **Direct decision source:** User via Room 1 — **本轮先不按 ORG 默认上游流程，直接进入 cutover handoff**

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于在 user 已直接拍板“这轮先不按 ORG 默认顺序、直接 cutover”后，向 **Room 4** 下发一份可以直接执行的 `P3.3.15` handoff。

本文件不是：
- ORG 默认流程示范
- Room 2 / Room 3 / Room 5 已补齐后的标准 preflight 包
- 自动宣告 full system owner shift completed
- 自动宣告 final fact owner shift

本文件只做一件事：

> **把 `P3.3.14 stop at B` 之后剩余的 direct-cutover 工作，压成 1 轮 4 块执行任务，直接交给 Room 4 做实现、测试与证据包回收。**

---

## 1. Room 1 当前判断

### 1.1 总结论
Room 1 结论：

> **可以直接发 handoff。**

但 Room 1 当前将“真正 cutover”压缩理解为 **4 块执行任务**，而不是“整条主链路一把梭全切”。

### 1.2 Room 1 对“这 4 步”的当前定义
在当前主线程事实上，若绕过 ORG 默认上游补件流程，最合理的剩余执行块为：

1. **Direct serving cutover**
   - 在 `ReviewPage` 当前 narrow serving subset 上做真正的 runtime source switch / cutover execution
2. **`review_group` true-exit absorb**
   - 把 `review_group` 从 current owner + retained anchor posture，推进到 true-exit absorbed
3. **DB / API uplift absorbed**
   - 把当前 `v0.2.1` baselines 之上的 uplift seam families，推进到 absorbed runtime baseline
4. **Cleanup / old-path purge**
   - 在证据包通过后，清理 retained anchor / old-path / historical-only / deprecated candidate 残留

### 1.3 本轮不一起偷切的部分
即使本轮叫 Direct Cutover，Room 1 当前仍 **不授权** Room 4 直接补脑扩大到：

1. 首页默认主 route 改成 planner-aware / auto-routing
2. active continuation 承接路径静默改写
3. final fact / settlement owner 从 backend/cloud 切到 local path
4. DB schema rewrite
5. API core semantics rewrite
6. unified planner / planner merge

---

## 2. 本轮 In Scope

### Track A — Direct Serving Cutover
做：
1. ReviewPage 当前 narrow serving subset 的真实 runtime cutover
2. 将当前已 additive 的 adapter / helper / summary / completion 前置说明，推进到真实 serving switch 后可运行状态
3. 保留 rollback / hold / fallback machinery，并在 cutover 后继续可触发、可观测
4. 提交可执行证据：切前 / 切后 source truth、受影响页面、rollback 条件

不做：
- 首页默认主 route 切换
- active continuation path 改写
- mixed / auto-routing runtime

### Track B — `review_group` True Exit Absorb
做：
1. 将 `review_group` 从 current owner + retained anchor + compatibility anchor + deprecated candidate，推进到 **true-exit absorbed**
2. 明确哪些 still-dependent paths 已被替代
3. 明确 rollback target 切后是否仍保留、保留多久、何时可 historical-only
4. 提供 true-exit absorb 证据位与 stop-condition

不做：
- 没有替代就硬删
- 不带证据直接把 `review_group` 写成 historical-only

### Track C — DB/API Uplift Absorbed
做：
1. 将当前 uplift seam families 从 discussion / readiness / gate，推进到 absorbed runtime baseline
2. 明确新 active DB / API baseline 应如何写回
3. 提供 no-major-change / no-core-rewrite 结论，或显式标红哪里已经越界
4. 给出 patch draft，供 Room 1 后续 pin

不做：
- schema rewrite
- API core semantics rewrite
- 无文档回写的 silent contract drift

### Track D — Cleanup / Old-Path Purge
做：
1. 清理 retained-anchor-aware 旧 wording
2. 清理 deprecated candidate / old-path / historical-only 残留
3. 清理不再需要的 guard / helper / marker（仅限本轮 direct-cutover 真正消化完的部分）
4. 输出 cleanup list：删了什么、保留什么、为什么

不做：
- 借 cleanup 偷切 final fact owner
- 借 cleanup 顺手扩大到首页主 route / active continuation / planner merge

---

## 3. Out of Scope

以下内容本轮继续 out of scope：

1. 首页 `study_default` 默认主入口改写
2. active continuation source switch / silent reroute
3. final fact owner shift
4. reward / settlement owner shift
5. `check_in / learning_day / streak` owner shift
6. DB schema rewrite
7. API core semantics rewrite
8. unified planner / planner merge
9. mixed / auto-routing runtime
10. 用户可见“已切到本地主真相 / final fact 已改由本地记账”的宣告

---

## 4. Room 4 不得补脑的已收口点

以下点 Room 4 本轮不得自行扩大解释：

1. 这轮是 **direct cutover round**，不等于整个系统所有 owner 一次性全切
2. final fact / settlement truth 当前仍默认以后端 / cloud fact layer 为准，除非 Room 1 明确追加 pin
3. 首页默认主入口当前不在本轮 cutover 范围
4. active continuation 当前不在本轮 source switch 范围
5. DB / API uplift absorbed 不等于允许 schema / endpoint core semantics rewrite
6. cleanup 只能清已经被本轮 direct cutover 真正替代的部分，不能反向制造新范围

---

## 5. 必守依据

### 5.1 推进层 / 主线程
- `Main_updated_2026-04-11_v35.md`
- `STATUS_updated_2026-04-11_v33.md`
- `R1_P3_3_15_TrueCutover_ScopePin_and_Handoff_Pack_v0.1.md`

### 5.2 当前 active 主文档
- `BR-OPP-001_v0.2.16.md`
- `UI_SPEC_v0.3.6.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 5.3 直接前序依据
- `P3.3.14_Claude_res.md`
- `R1_to_R4_P3_3_14_Execution_Handoff_v0.1.md`

---

## 6. 必测项

### 6.1 Direct Serving Cutover
1. ReviewPage 当前 narrow subset 真实发生 source switch
2. 切后主路径可运行
3. rollback / hold / fallback 可触发
4. blast radius 未误伤首页默认主 route
5. 用户端不出现 false success / false owner-shift copy

### 6.2 `review_group` True Exit Absorb
1. `review_group` current owner posture 不再保留为 runtime truth
2. 仍保留的 anchor / fallback / historical-only 身份被明确写清
3. no dangling dependency：active continuation / completion gating / settlement trigger 没有断链
4. 无 overclaim

### 6.3 DB/API Uplift Absorbed
1. absorbed 的 seam families 被列清
2. active baseline candidate patch 可读
3. 未触发 schema rewrite / API core semantics rewrite
4. 无 silent contract drift

### 6.4 Cleanup
1. cleanup list 完整
2. 删除项与保留项清晰
3. 无误删 rollback / hold 必需结构
4. cleanup 后 regression 通过

### 6.5 Fact Boundary Regression
1. final fact / settlement owner 未被偷切
2. `daily_goal` / reward / streak / learning_day / check_in 事实仍不被 local-serving 直接改写
3. 用户端无“本地已直接到账 / 已直接完成 / 已切到新主真相”类表达

---

## 7. 交付要求

Room 4 本轮交付至少包含：

1. **实现摘要**
   - 这次真切了什么
   - 没切什么
   - 哪些是 direct cutover，哪些仍保留旧真相

2. **受影响文件清单**
   - 代码文件
   - 测试文件
   - 需要 patch 的文档文件

3. **测试与自测结果**
   - analyzer / unit / widget / integration / targeted regression
   - direct cutover 前后对比

4. **风险清单**
   - 回退点
   - hold 条件
   - 是否还残留 should-follow-up 项

5. **文档 patch draft**
   - 至少覆盖 BR / UI / DB / API / Main / STATUS 的建议回写点

6. **结论标签**
   - `accept`
   - `accept with retained risks`
   - `hold`
   - `escalate`

---

## 8. Done 定义

本轮只有在以下条件同时满足时，Room 1 才会把 `P3.3.15` 当作 direct-cutover close candidate：

1. ReviewPage 当前目标 subset 已真实 cutover
2. `review_group` true exit 已具备 absorb 级证据
3. DB/API uplift 已具备 absorbed 级 patch 证据
4. cleanup 已实际完成，而不是只写计划
5. final fact owner 未被偷切
6. 首页默认主入口与 active continuation 未被误伤
7. Room 4 已给出完整证据包 + patch draft

---

## 9. Room 1 附注

本 handoff 属于：

> **user 直接拍板下的 direct-cutover exceptional round**

因此本轮：
1. Room 1 不再先等 Room 2 / Room 3 / Room 5 的标准上游输入齐备
2. 但 Room 4 仍必须把证据包与 patch draft 做完整
3. 后续是否正式 pin 为 runtime truth，仍由 Room 1 在 closeout 后统一吸收

