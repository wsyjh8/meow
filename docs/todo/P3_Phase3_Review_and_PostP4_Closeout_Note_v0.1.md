# OPP-001 / 背单词喵喵 App — Room 4 `R4_P3_Phase3_Review_and_PostP4_Closeout_Note_v0.1.md`

- **Owner:** Room 4
- **Role:** Eng + QA + Debug Tech Lead
- **Date:** 2026-04-05
- **Status:** judgment + post-Phase4 closeout handoff
- **Scope:** P3 — Main Mechanism Deepening

---

## 0. Room 4 一句话结论

**Phase 3 通过，可进入 Phase 4。**

但需要同时写清一条：

> **按当前 `p3_phases.md`，P3 没有官方独立的 `Phase 5`。**
> P3 的正式切法是：**Phase 0 + Phase 1 + Phase 2 + Phase 3 + Phase 4**。
> 因此，在 Cursor 完成 Phase 4 之后，下一步不是再开一个新的业务 phase，而是进入 **P3 final closeout / final verification round**。

所以，本文件给出的不是“新的正式 P5 业务 phase”，而是：

> **Post-Phase4 Closeout Handoff**

也就是：当 Phase 4 做完后，Cursor 应进入 **P3 总收口 / 总回归 / close bar 核验**。

---

## 1. 为什么 Phase 3 可以通过

Room 4 判断 Phase 3 可 close，理由如下：

1. **仍然走的是 `summary-first` 路径**
   - 没有新增 `/statistics` route
   - 没有新增一级导航
   - 没有把 statistics 扩成独立最小页

2. **统计事实边界没有被写坏**
   - `learning_days` 继续只代表 `learning_day`
   - `check_in` 继续独立显示
   - `streak` 继续标注为基于签到
   - 三者没有混写

3. **状态矩阵是 Room 4 认可的保守实现**
   - `stats_summary = null` → 隐藏
   - 全 0 → 空态鼓励文案
   - 正常值 → summary metrics card
   - 没有 fake 数据，没有为了“页面完整”硬造统计

4. **测试 bar 过关**
   - 新增了 summary-first safety + state matrix regression
   - 总测试 222 项全过

5. **没有污染其他 phase**
   - 没开 Phase 4
   - 没切 streak basis
   - 没新开 route
   - 没改 backend contract

---

## 2. Phase 4 可以直接执行

你现在可以直接让 Cursor 执行已经发出的：

- `R4_to_Cursor_P3_Phase4_Streak_Decision_Preparation_Handoff_v0.1.md`

Room 4 对 Phase 4 的要求继续保持不变：

1. **只做 decision / compatibility preparation**
2. **不切 `streak_basis_type`**
3. **不改历史 streak 计算口径**
4. **不写成“即将按 learning_day 算”**
5. **只建立 current truth 与 future stance 的清晰分层**

---

## 3. 为什么这里不给“正式 P5 业务 phase”

因为当前 Room 4 已经明确把 P3 拆成：

1. Phase 0 — Baseline-safe Entry / Guard / Test Seam
2. Phase 1 — CTA Deepening
3. Phase 2 — Review Structured Deepening
4. Phase 3 — Statistics Decision Path
5. Phase 4 — Streak Decision Preparation

到这里，P3 的业务主题 phase 已经完整。

所以：

- **没有新的 official Phase 5 业务主题**
- 若现在硬编一个 P5，只会越过 Room 4 的计划边界
- 正确做法是：**Phase 4 做完后，进入 P3 final closeout / final verification**

---

## 4. 给 Cursor 的 Post-Phase4 Closeout Handoff（供 Phase 4 完成后使用）

> 使用方式：
> - 现在**不要执行这份 closeout handoff**
> - 先执行 Phase 4
> - 等 Phase 4 完成并回传后，再把下面这份 handoff 发给 Cursor

---

# Room 4 → Cursor
## P3 Final Closeout / Final Verification Handoff

你现在进入的不是新的业务 feature phase，而是：

> **P3 final closeout / final verification round**

你的任务不是再扩范围，而是确认：
- P3 Phase 0–4 的最终结果是否都成立
- 是否有任何 phase 互相污染 / 回退 / 越界
- 是否达到 Room 4 可提交给 Room 1 的 close bar

### A. 你必须继续服从的硬边界
1. 不新增任何新业务功能
2. 不新增任何新 route / 新导航 / 新 contract
3. 不把 candidate / future stance 改成 current runtime truth
4. 不重构 DB / API / UI 主结构
5. 只允许：
   - final audit
   - final regression
   - final cleanup（仅限低风险、与已实现内容直接相关的 code cleanup）
   - final test evidence aggregation

### B. 你要核的 5 个主题

#### B1. Phase 0 audit
确认：
- contract absence guards 仍成立
- selector / feature guard / route guard 没被后续 phase 打穿
- fallback 行为仍能回到 active baseline

#### B2. Phase 1 audit
确认：
- CTA 仍保持单一最强主 CTA
- continuation-first 没被回退
- `action + reason` 仍是当前已 pin very small contract
- `priority_band / blocking_condition` 没被偷做进来
- absent / delayed / degraded 仍安全回退到 Option C baseline

#### B3. Phase 2 audit
确认：
- review deeper summary 仍以后端 contract 为准
- `active_group_completed` 没被写成“今日复习完成”
- `next_group_readiness` 没被前端 remaining count 脑补
- Review deeper state 没污染 CTA winner

#### B4. Phase 3 audit
确认：
- statistics 仍是 `summary-first`
- 没有 `/statistics` 独立 route
- `learning_day / check_in / streak` 没混写
- 空态 / 隐藏态 / 正常态矩阵仍成立

#### B5. Phase 4 audit
确认：
- `streak_basis_type = check_in` 仍保持 current runtime truth
- 未来方向只体现在 decision / compatibility explanation 边界
- 没有写成“现在已经按 learning_day 算”
- 没有改历史 streak 数据 / 展示 / 计算口径

### C. 你必须给 Room 4 的最终交付
请按以下结构回传：

#### 1. Final code summary
- 本轮是否有代码变更
- 若有，只允许与 final cleanup / regression 直接相关
- 列出文件、变更点、目的

#### 2. Final boundary audit
请逐条回答 PASS / FAIL：
- CTA single-winner preserved
- continuation-first preserved
- summary-first preserved
- `learning_day / check_in / streak` separation preserved
- `streak_basis_type = check_in` preserved
- no new route / no new contract / no phase bleed

#### 3. Final test summary
至少给出：
- `flutter test`
- `flutter analyze`
- `npm test`
- `npm run test:e2e`
- 总数 / 是否全过

#### 4. Close bar self-check
请按以下 close bar 回答：
1. P3 Phase 0–4 都已完成
2. 没有 candidate input 被偷实现为 active truth
3. 没有新 route / 新 contract / 新业务面被偷偷带入
4. 回归测试全过
5. 当前 runtime truth 没被 future stance 污染
6. 可以提交给 Room 4 做 P3 close judgment

#### 5. Residual risk
- 只列真正 residual risk
- 非 blocker 请明确写 `non-blocking`
- 不要把“未来可继续优化”包装成 blocker

### D. 完成后的停止条件
完成 closeout 后：
- **停止**
- 不自动开新产品方向
- 不自动开 P4 / P5 / secondary patch
- 等 Room 4 审核

---

## 5. Room 4 给你的实际执行建议

现在的顺序应当是：

1. 你先让 Cursor 执行 **Phase 4**
2. Cursor 回 Phase 4
3. 我以 Room 4 审核
4. 若通过，我再用本文件中的 **Post-Phase4 Closeout Handoff** 去做 P3 总收口

一句话：

> **现在能进 p4；但当前计划里没有新的 official p5，p4 后面接的是 P3 总收口，不是再开一个业务 phase。**

