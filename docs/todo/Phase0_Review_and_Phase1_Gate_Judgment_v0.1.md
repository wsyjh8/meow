# OPP-001 / 背单词喵喵 App — Room 4 `R4_P3_Phase0_Review_and_Phase1_Gate_Judgment_v0.1.md`

- **Owner:** Room 4
- **Role:** Eng + QA + Debug Tech Lead
- **Date:** 2026-04-05
- **Status:** judgment note / Phase 0 close review / Phase 1 gate decision
- **Based on:** `回p3_p0.md` + `p3_phases.md` + `R4_P3_Preflight_Implementation_Plan_v0.1.1.md` + current runtime SSOT

---

## 0. Room 4 结论

> **Phase 0 = PASS / can close**
>
> **Phase 1 = NOT YET / cannot formally enter now**

这不是因为 Cursor 做得不够，而是因为：
- Phase 0 的目标是建立 guard / fallback / test seam / contract-absence regression；
- Phase 1（CTA Deepening）从一开始就被定义为 **contract-gated phase**；
- 在 Room 1 未明确 pin 本轮 CTA contract set 之前，Room 4 不能把 P3 CTA candidate contract 当成 active runtime truth 交给 Cursor 继续做 feature layer。

一句话：

> **Phase 0 已经把“安全入口”搭好了，但 Phase 1 需要的“可消费 contract”还没有被 Room 1 正式 pin。**

---

## 1. 对 Cursor 本轮交付的 Room 4 审核

## 1.1 通过项
Cursor 本轮交付符合 Phase 0 预期，主要体现在：

1. **没越界做 feature**
   - 没实现 CTA 深化
   - 没实现 Review 深化
   - 没新增 Statistics 独立页
   - 没改 streak runtime truth

2. **确实建立了 guard / fallback / seam**
   - TodayState null-safety hardening
   - P3 feature guard 常量
   - contract-absence e2e
   - shared fixtures
   - regression tests

3. **明确守住了 non-goals**
   - 没本地生成 `today_primary_action`
   - 没用 remaining count 推导 readiness
   - 没把 `learning_day` 写成当前 streak 依据
   - 没造 fake contract / dummy payload
   - 没把 candidate input 当 active baseline

4. **测试条目足够支撑 Phase 0 close**
   - flutter / backend / e2e 都有覆盖
   - 当前回传口径中没有出现“只写代码、没补测试”的问题

## 1.2 Room 4 判断
因此，Room 4 认可：

> **Phase 0 可以 close。**

---

## 2. 为什么现在还不能进入 Phase 1

## 2.1 不是 Phase 0 没完成，而是 Phase 1 本来就有 gate
Room 4 之前已经明确：
- **Phase 0 可以现在就开**；
- **Phase 1–4 不能一次性全部开**；
- 进入哪一个 phase，取决于 Room 1 是否 pin 了该块 contract set。

因此，当前问题不在实现，而在 gate。

---

## 2.2 Phase 1 的 entry gate 还没被满足
Phase 1（CTA Deepening）要正式开工，至少需要 Room 1 pin 以下内容：

1. **CTA decision-support contract 是否正式进入 active baseline**
2. **若进入，最小字段形状是什么**
   - 例如是否存在 `today_primary_action` 或等价 block
   - winner 类型 / reason / priority band / blocking helper 是否进入，进入到什么程度
3. **absent / delayed / degraded fallback 语义是什么**
4. **本轮不进入的 CTA 深化项有哪些**

当前这些内容，Room 2 / Room 3 / Room 5 都提供了 input，
但它们仍然是：
- preflight input
- rules freeze input
- UI input

而不是 Room 1 已 pin 的 runtime active truth。

---

## 2.3 Room 4 不能把“已有 seam”误当“已获授权可实现”
Cursor 在交付里写到：
- `today_page.dart:_resolveCtaWinner()` 已有 seam
- `P3FeatureGuard.isCTADecisionSupportEnabled` 将来翻 true 后可接 decision-support 消费

这说明：

> **工程入口已经准备好**

但不等于：

> **现在就可以翻 true 并开始接候选 contract**

Room 4 如果现在让 Cursor 继续做 Phase 1，就会出现两类越界风险：
1. 把未 pin 的 CTA contract 先做成事实；
2. 为了页面完整性，本地补脑 winner 逻辑 / reason line / helper 文案。

这与 Room 4 当前执行原则冲突。

---

## 3. 当前最准确的阶段判断

### 3.1 已完成
- **P3 Phase 0：PASS / 可 close**

### 3.2 仍未满足进入条件
- **P3 Phase 1（CTA Deepening）：No-go for now**

### 3.3 当前正确 next action
当前最正确的 next action 不是继续让 Cursor 开 Phase 1，而是：

> **先让 Room 1 正式 pin CTA contract set。**

---

## 4. Room 4 给 Room 1 的最小 pin 清单（CTA only）

若要让 Room 4 正式发出 Phase 1 指令，Room 1 至少要明确：

1. **是否进入 CTA decision-support block**
   - 是 / 否

2. **如果进入，最小字段集是什么**
   - 必填字段
   - 可选字段
   - 明确哪些字段本轮不进

3. **winner 允许的枚举范围**
   - 例如：`continue_review_group` / `go_review` / `go_new_words` / `go_session`
   - 还是只冻结更小集合

4. **reason / priority / helper 的边界**
   - 哪些可进入 active contract
   - 哪些仍只停在 UI 表达候选层

5. **fallback 口径**
   - absent contract 时怎么退
   - delayed / degraded 时怎么退
   - 是否仍完全回到当前 Option C CTA winner 最小层

6. **本轮明确不做的 CTA 深化项**
   - 避免 Cursor 顺手扩写

---

## 5. Room 4 最终结论

> **我认可 Cursor 已完成 Phase 0，可以 close。**
>
> **但我不同意现在直接进入下一阶段。**

原因只有一个：

> **Phase 1 不是“看起来准备好了就能开”，而是必须等 Room 1 pin CTA contract set 后，Room 4 才能正式发 Phase 1 指令。**

---

## 6. 一句话给用户的结论

- **可以确认：Phase 0 已通过。**
- **不能确认：现在立刻进入 Phase 1。**
- **当前阻塞点：不是实现，不是测试，而是 Room 1 还没有把 CTA contract set 正式 pin 成 active baseline。**

