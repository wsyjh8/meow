# 背单词 App 设计规格书 v1.0

> **交付目的**：本文档供 Claude Code 等编码代理使用，用于实现移动端（iOS/Android 或 Web）的 UI 界面。
> 文档目标是**无歧义、可直接落地**——所有颜色、尺寸、文案、SVG 资源都是精确值，不留模糊空间。
>
> **范围声明**：本文档覆盖 4 个已定稿页面 + 共享组件。**词书页面、Mochi 子页（换装/房间/零食柜/日记）尚未设计**，已在第 9 节明确标注为待补，请勿擅自补全。

---

## 目录

1. 项目概述
2. 设计原则
3. 设计 Tokens（颜色 / 字体 / 圆角 / 间距）
4. 共享资源（Mochi SVG、爪印 SVG、Tab bar 图标）
5. 共享组件（卡片、按钮、列表、Tab bar）
6. 页面规格
   - 6.1 首页
   - 6.2 Mochi 页
   - 6.3 统计页
   - 6.4 我的页
7. 交互行为
8. 实现注意事项
9. 范围外 / 待补内容

---

## 1. 项目概述

### 1.1 产品定位
背单词学习 App，核心差异化是**云养猫机制**——用户通过学习单词获得"小鱼干"，用于喂养、装扮一只名为 **Mochi** 的虚拟猫。Mochi 不是附加功能，而是产品的情感引擎，**贯穿整个 App 而不仅仅在猫页**。

### 1.2 目标用户
**主要用户**：15-35 岁中文女性，英语学习需求中低强度（兴趣、考试、职场提升），最大痛点是"坚持不下来"。
**次要用户**：自然渗透的同年龄段男性用户，**不为他们做产品妥协**。

### 1.3 战略定位（"先女后男"）
- **第一阶段**（前 2 年）：纯女性向定位，不为男性做任何视觉妥协。
- **第二阶段**：让男性用户因为产品力（算法、词库、考试覆盖）自然渗透。
- 实现细则：视觉语言保持温柔但不幼稚；不做排行榜、PK、徽章等竞技元素；不做付费跳过；不做"再不学猫就死了"这类负向情绪绑架。

### 1.4 整体萌度目标
**全 App 平均 5 分**（10 分制，参考 Duolingo / Headspace / 小红书的水位）。其中：
- Mochi 页：6 分（情感主场）
- 首页：5 分（温柔的工具）
- 统计页：5 分（温柔的数据）
- 我的页：4.8 分（最克制的工具页）

**绝对不要**为了"更可爱"而推到 6 分以上——一旦越线，产品的"学习工具"严肃性会被稀释，留存下降。

---

## 2. 设计原则

### 2.1 信息层级原则
首页有且只有**一个**主 CTA（继续学习）。其他页面同理——每页只有一个视觉重心。次级元素必须明显比主元素"轻"。

### 2.2 Mochi 是隐形主持人
Mochi 必须出现在 4 个主要页面中的 **3 个非猫页**（首页、统计页、我的页），但**绝不打断每页的核心任务**。具体载体：
- 首页：打卡条里的小头像
- 统计页：底部斜体落款 + 大数字卡上的爪印水印
- 我的页：用户头像位置（默认是 Mochi 头像）
- Mochi 页：完整角色插画作为页面主角

### 2.3 反焦虑原则
Mochi **永远不会饿死、不会生病、不会消失**。所有关于猫的状态描述用正向叙事（"等了你 18 小时"）而非负向勒索（"快饿死了"）。所有进度条用"距离下一阶段还差 X"而非"再不学就要后退"。

### 2.4 克制原则
绝对不要做以下事情，无论看起来多有意义：
- 红点、未读数字角标（除"小鱼干余额"这类信息型角标）
- 内容流、Banner、活动横幅
- 排行榜、好友 PK、社交对比
- 付费跳过养成进度的入口
- 字体描边、阴影、彩色渐变
- 每日运势、每日一句励志
- 弹窗式祝贺（"Mochi 升级啦！"）

### 2.5 字号下限
**最小 11px**。低于这个值即使为了塞更多内容也不允许。

---

## 3. 设计 Tokens

### 3.1 颜色系统

#### 3.1.1 背景色
| 用途 | 名称 | Hex | 备注 |
|---|---|---|---|
| 全局背景 | bg-canvas | `#FDFBF7` | 暖米色，**不是纯白**，整个 App 的基底 |
| 卡片背景（主） | bg-card | `#F5EFE6` | 米色，用于数字卡、信息卡 |
| 卡片背景（强调） | bg-card-deep | `#ECE0CC` | 略深米色，用于次级强调 |
| 描边卡背景 | bg-card-outline | `#FDFBF7` | 和全局背景一致，靠描边区分 |
| Mochi 暖色卡 | bg-mochi-warm | `#FAECE7` | 桃米色，仅用于 Mochi 相关卡片 |
| 紫色 hero 背景 | bg-hero-purple | `#EEEDFE` | 浅紫，用于统计页 hero 卡 |
| 绿色亮点背景 | bg-highlight-green | `#E1F5EE` | 用于"本周亮点" |

#### 3.1.2 文字色
| 用途 | 名称 | Hex |
|---|---|---|
| 主要文字 | text-primary | `#2C2C2A` |
| 次要文字 | text-secondary | `#888070` |
| 提示文字 | text-tertiary | `#B4A89A` |
| 主题暖紫（数字、强调） | text-purple | `#6B4FA8` |
| 主题暖紫（深，标题） | text-purple-deep | `#26215C` |
| 珊瑚红（连续天数等正向情感） | text-coral | `#993C1D` |
| Mochi 棕（Mochi 卡内文字） | text-mochi | `#4A1B0C` |
| 绿色（亮点卡） | text-green | `#04342C` |

#### 3.1.3 主题色
| 用途 | 名称 | Hex | 备注 |
|---|---|---|---|
| 主 CTA 紫 | brand-purple | `#6B4FA8` | 首页大按钮、强调元素 |
| 主 CTA 紫（深，统计深色块） | brand-purple-deep | `#534AB7` | 仅热力图最深的方格使用，从 v2 起逐步替换为 brand-purple |
| Mochi 主色（Mochi 页 CTA） | mochi-rose | `#D4537E` | 仅在 Mochi 页内使用 |

#### 3.1.4 边框色
| 用途 | 名称 | Hex | 描述 |
|---|---|---|---|
| 卡片边框（默认） | border-default | `#E8DFCF` | 0.5px |
| 列表分隔线 | border-divider | `#ECE3D2` | 0.5px |
| 图标描边（未选中） | border-icon | `#C9B8A0` | tab bar 未选中图标 |
| 图标描边（选中） | border-icon-active | `#B8845C` | tab bar 选中图标 |

#### 3.1.5 Mochi 角色色板（用于角色 SVG，不要修改）
| 用途 | Hex |
|---|---|
| 主体毛色（浅） | `#F5DEB3` |
| 主体毛色（深，肚子/尾巴底） | `#E8C99A` |
| 阴影色（脖子下方/影子） | `#E8B89C` |
| 耳朵内侧 | `#F0B89C` |
| 腮红 | `#F4C0D1`（opacity 0.7） |
| 鼻子 | `#D88B7A` |
| 眼睛/嘴线条 | `#3a2820` |
| 胡须 | `#8a6a55` |

### 3.2 字体

**字体堆栈**：使用系统默认 sans-serif，避免引入第三方字体造成的延迟和不一致。
```css
font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Helvetica Neue", "Microsoft YaHei", sans-serif;
```

**字号阶梯**：
| 用途 | 大小 | 字重 |
|---|---|---|
| 大数字（统计 hero） | 36-38px | 500 |
| 页面标题 | 18px | 500 |
| 区块大数字 | 22-24px | 500 |
| 中等数字 | 15-18px | 500 |
| 卡片标题/正文 | 13-15px | 400/500 |
| 次要标签 | 11-12px | 400 |
| 状态栏/极小提示 | 10-11px | 400 |

**字重规则**：**只使用 400 和 500 两个字重**。绝对不使用 600/700——会显得过重，破坏温柔感。

### 3.3 圆角

| 用途 | 大小 |
|---|---|
| 列表项、小卡片 | 16px |
| 标准卡片 | 16px |
| 大卡片（数据 hero、当前词书卡） | 18-22px |
| 主 CTA 按钮 | 22px |
| 头像 / 圆形元素 | 50% |
| 胶囊（pill） | 999px |
| 手机外框（仅 mockup） | 36px |

**规则**：最重要的元素圆角最大。主 CTA 永远是页内圆角最大的元素之一。

### 3.4 间距

| 用途 | 大小 |
|---|---|
| 页面左右边距 | 22px |
| 卡片之间垂直间距 | 14-18px |
| 卡片内部内边距（小） | 12-14px |
| 卡片内部内边距（大） | 18-22px |
| 元素之间小间距 | 8-12px |
| Tab bar 高度 | 64px（含底部安全区） |

### 3.5 阴影

**全 App 不使用阴影**，除了：
- 表单输入框 focus ring（默认浏览器/系统）
- 极少数浮层提示（如 Mochi 卡上的"+1 张新照片"胶囊），使用极轻 `box-shadow: 0 1px 3px rgba(0,0,0,0.06)`

---

## 4. 共享资源

### 4.1 Mochi 角色 SVG（大尺寸，用于 Mochi 页）

**用途**：Mochi 页主角插画，建议尺寸 200-260px 高度。
**viewBox**：`0 0 200 210`

```html
<svg viewBox="0 0 200 210" xmlns="http://www.w3.org/2000/svg">
  <!-- 影子 -->
  <ellipse cx="100" cy="195" rx="70" ry="6" fill="#F0997B" opacity="0.25"/>
  <!-- 身体阴影 -->
  <ellipse cx="100" cy="178" rx="62" ry="14" fill="#E8B89C"/>
  <!-- 身体 -->
  <ellipse cx="100" cy="135" rx="50" ry="42" fill="#F5DEB3"/>
  <!-- 头 -->
  <ellipse cx="100" cy="80" r="42" fill="#F5DEB3"/>
  <circle cx="100" cy="80" r="42" fill="#F5DEB3"/>
  <!-- 耳朵外 -->
  <path d="M 66 56 L 60 26 L 88 48 Z" fill="#F5DEB3"/>
  <path d="M 134 56 L 140 26 L 112 48 Z" fill="#F5DEB3"/>
  <!-- 耳朵内侧 -->
  <path d="M 70 52 L 68 36 L 82 48 Z" fill="#F0B89C"/>
  <path d="M 130 52 L 132 36 L 118 48 Z" fill="#F0B89C"/>
  <!-- 眯眼 -->
  <path d="M 78 82 Q 84 76 90 82" stroke="#3a2820" stroke-width="2.8" fill="none" stroke-linecap="round"/>
  <path d="M 110 82 Q 116 76 122 82" stroke="#3a2820" stroke-width="2.8" fill="none" stroke-linecap="round"/>
  <!-- 腮红 -->
  <ellipse cx="78" cy="92" rx="6" ry="3" fill="#F4C0D1" opacity="0.7"/>
  <ellipse cx="122" cy="92" rx="6" ry="3" fill="#F4C0D1" opacity="0.7"/>
  <!-- 鼻子 -->
  <path d="M 96 94 L 104 94 L 100 99 Z" fill="#D88B7A"/>
  <!-- 嘴 -->
  <path d="M 100 99 Q 95 104 91 101" stroke="#3a2820" stroke-width="1.6" fill="none" stroke-linecap="round"/>
  <path d="M 100 99 Q 105 104 109 101" stroke="#3a2820" stroke-width="1.6" fill="none" stroke-linecap="round"/>
  <!-- 胡须左 -->
  <line x1="70" y1="93" x2="54" y2="90" stroke="#8a6a55" stroke-width="1" stroke-linecap="round"/>
  <line x1="70" y1="99" x2="54" y2="100" stroke="#8a6a55" stroke-width="1" stroke-linecap="round"/>
  <!-- 胡须右 -->
  <line x1="130" y1="93" x2="146" y2="90" stroke="#8a6a55" stroke-width="1" stroke-linecap="round"/>
  <line x1="130" y1="99" x2="146" y2="100" stroke="#8a6a55" stroke-width="1" stroke-linecap="round"/>
  <!-- 尾巴 -->
  <path d="M 148 145 Q 178 130 168 95" stroke="#F5DEB3" stroke-width="16" fill="none" stroke-linecap="round"/>
  <path d="M 148 145 Q 178 130 168 95" stroke="#E8C99A" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.5"/>
  <!-- 后脚 -->
  <ellipse cx="82" cy="172" rx="11" ry="7" fill="#E8C99A"/>
  <ellipse cx="118" cy="172" rx="11" ry="7" fill="#E8C99A"/>
</svg>
```

**互动**：整个 SVG 是可点的（hit area = 整个 viewBox 区域）。点击触发眯眼/翻肚子/咕噜咕噜动画（动画细节待动效设计师补充，本文档不规定具体帧）。

### 4.2 Mochi 头像 SVG（小尺寸，用于打卡条/头像位）

**用途**：首页打卡条、统计页落款、我的页头像等。建议显示尺寸 32-46px。
**viewBox**：`0 0 60 60`

```html
<svg viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg">
  <circle cx="30" cy="34" r="22" fill="#F5DEB3"/>
  <path d="M 13 22 L 10 6 L 23 18 Z" fill="#F5DEB3"/>
  <path d="M 47 22 L 50 6 L 37 18 Z" fill="#F5DEB3"/>
  <path d="M 15 18 L 14 10 L 21 17 Z" fill="#F0B89C"/>
  <path d="M 45 18 L 46 10 L 39 17 Z" fill="#F0B89C"/>
  <path d="M 20 33 Q 24 29 28 33" stroke="#3a2820" stroke-width="2" fill="none" stroke-linecap="round"/>
  <path d="M 32 33 Q 36 29 40 33" stroke="#3a2820" stroke-width="2" fill="none" stroke-linecap="round"/>
  <ellipse cx="20" cy="40" rx="4" ry="2" fill="#F4C0D1" opacity="0.7"/>
  <ellipse cx="40" cy="40" rx="4" ry="2" fill="#F4C0D1" opacity="0.7"/>
  <path d="M 28 41 L 32 41 L 30 44 Z" fill="#D88B7A"/>
  <path d="M 30 44 Q 27 47 25 45" stroke="#3a2820" stroke-width="1.2" fill="none" stroke-linecap="round"/>
  <path d="M 30 44 Q 33 47 35 45" stroke="#3a2820" stroke-width="1.2" fill="none" stroke-linecap="round"/>
</svg>
```

### 4.3 Mochi 爪印 SVG（水印用）

**用途**：首页主 CTA 右下角水印 + 统计页 hero 卡右下角水印。
**viewBox**：`0 0 40 40`，显示尺寸 30-32px，opacity 0.18-0.22。

```html
<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="20" cy="26" rx="9" ry="7" fill="currentColor"/>
  <ellipse cx="9" cy="16" rx="3.5" ry="4.5" fill="currentColor"/>
  <ellipse cx="17" cy="11" rx="3.5" ry="4.5" fill="currentColor"/>
  <ellipse cx="25" cy="11" rx="3.5" ry="4.5" fill="currentColor"/>
  <ellipse cx="32" cy="16" rx="3.5" ry="4.5" fill="currentColor"/>
</svg>
```

**填色规则**：用 `currentColor` 继承父元素颜色。
- 在紫色 CTA 上：父元素 color 设为 `white`，opacity 0.18
- 在浅紫 hero 卡上：父元素 color 设为 `#6B4FA8`，opacity 0.22

### 4.4 Tab bar 图标 SVG

全部使用**填充式（filled）图标**，不是线性图标。共用一套米色 + 暖灰棕描边的视觉规则。

**统一规则**：
- viewBox：`0 0 28 28`
- 显示尺寸：22-26px（Mochi 24-28px，比其他略大）
- 未选中填充：`#F5EFE6`（次填充 `#ECE0CC`）
- 未选中描边：`#C9B8A0`，1.3px
- 选中填充：`#F5DEB3`（次填充 `#E8B89C`）
- 选中描边：`#B8845C`，1.5px
- 所有连接：`stroke-linejoin="round"` `stroke-linecap="round"`

#### 4.4.1 首页图标
```html
<svg viewBox="0 0 28 28" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 13 L14 4 L24 13 L24 23 L4 23 Z"
        fill="var(--icon-fill)"
        stroke="var(--icon-stroke)"
        stroke-width="1.5" stroke-linejoin="round"/>
  <rect x="11" y="16" width="6" height="7"
        fill="var(--icon-fill-deep)"
        stroke="var(--icon-stroke)"
        stroke-width="1.2" stroke-linejoin="round"/>
</svg>
```

#### 4.4.2 词书图标
```html
<svg viewBox="0 0 28 28" xmlns="http://www.w3.org/2000/svg">
  <rect x="5" y="6" width="18" height="4.5" rx="1.2"
        fill="var(--icon-fill)" stroke="var(--icon-stroke)" stroke-width="1.3"/>
  <rect x="4" y="11.5" width="20" height="4.5" rx="1.2"
        fill="var(--icon-fill-deep)" stroke="var(--icon-stroke)" stroke-width="1.3"/>
  <rect x="6" y="17" width="16" height="4.5" rx="1.2"
        fill="var(--icon-fill)" stroke="var(--icon-stroke)" stroke-width="1.3"/>
</svg>
```

#### 4.4.3 Mochi 图标（猫脸）
```html
<svg viewBox="0 0 28 28" xmlns="http://www.w3.org/2000/svg">
  <path d="M8 9 L5.5 3.5 L11 7 Z"
        fill="var(--icon-fill)" stroke="var(--icon-stroke)" stroke-width="1.3" stroke-linejoin="round"/>
  <path d="M20 9 L22.5 3.5 L17 7 Z"
        fill="var(--icon-fill)" stroke="var(--icon-stroke)" stroke-width="1.3" stroke-linejoin="round"/>
  <circle cx="14" cy="15" r="8"
          fill="var(--icon-fill)" stroke="var(--icon-stroke)" stroke-width="1.3"/>
  <path d="M11 14 Q12 13 13 14" stroke="#8a6a55" stroke-width="1.2" fill="none" stroke-linecap="round"/>
  <path d="M15 14 Q16 13 17 14" stroke="#8a6a55" stroke-width="1.2" fill="none" stroke-linecap="round"/>
  <path d="M13.3 16.5 L14.7 16.5 L14 17.4 Z" fill="var(--icon-stroke)"/>
</svg>
```

**注意**：Mochi 图标的眼睛和鼻子线条颜色（`#8a6a55`）在选中和未选中态都不变——它们是角色特征，不是状态指示。

#### 4.4.4 统计图标
```html
<svg viewBox="0 0 28 28" xmlns="http://www.w3.org/2000/svg">
  <rect x="4.5" y="15" width="5" height="8" rx="1.2"
        fill="var(--icon-fill)" stroke="var(--icon-stroke)" stroke-width="1.3"/>
  <rect x="11.5" y="8" width="5" height="15" rx="1.2"
        fill="var(--icon-fill-deep)" stroke="var(--icon-stroke)" stroke-width="1.3"/>
  <rect x="18.5" y="11.5" width="5" height="11.5" rx="1.2"
        fill="var(--icon-fill)" stroke="var(--icon-stroke)" stroke-width="1.3"/>
</svg>
```

#### 4.4.5 我的图标
```html
<svg viewBox="0 0 28 28" xmlns="http://www.w3.org/2000/svg">
  <circle cx="14" cy="9" r="4.5"
          fill="var(--icon-fill)" stroke="var(--icon-stroke)" stroke-width="1.3"/>
  <path d="M4.5 24 a9.5 9.5 0 0 1 19 0 Z"
        fill="var(--icon-fill)" stroke="var(--icon-stroke)" stroke-width="1.3" stroke-linejoin="round"/>
</svg>
```

---

## 5. 共享组件

### 5.1 Tab bar

> **重要更新（v1.0 开发期）**：tab bar 当前是 **6 个 tab**，不是 5 个。第 6 个 tab "原版" 是临时的开发期备份，详见 5.1.6。**正式发版前必须移除**，届时 tab bar 恢复为 5 个。

**结构**：底部固定栏，6 个 tab（开发期），从左到右：首页 / 词书 / Mochi / 统计 / 我的 / 原版。

**容器规格**：
```
height: 64px (含底部 safe area)
border-top: 0.5px solid #ECE3D2
background: #FDFBF7
padding: 10px 8px 16px
display: flex
justify-content: space-around
```

**每个 tab 项**：
- 上方：图标（22-26px，Mochi 24-28px）
- 下方：文字标签，10px，与图标间距 3-4px
- 选中态：图标用选中色板 + 文字 `#2C2C2A` + font-weight 500
- 未选中态：图标用未选中色板 + 文字 `#888070` + font-weight 400
- 点击区域：整个 tab 项区域，最小 44×44px

**实现要点**：
1. Tab 切换无任何动画过渡，直接切换页面（避免廉价感）
2. **底部 tab bar 在所有 4 个主页面均存在**，通过页面路由切换
3. 不要在 tab bar 上加任何角标、红点（除非有未读消息这种功能性需求，但目前需求里没有）

#### 5.1.6 原版 tab（开发期临时）

**重要前提**：项目代码库里**已经存在一套旧版首页**，包含各种功能入口。开发期内**不要删除或重构这套旧 UI**，而是把它作为第 6 个 tab "原版" 暴露出来，方便后期对比和参考。

**为什么放在最右边**：
- 右侧是底部 bar 中注意力最低的位置，符合"参考用、不主推"的定位
- 移除时其他 5 个 tab 位置不变，零迁移成本
- Mochi 仍然在 6 个 tab 中相对靠中的位置（位置 3）

**视觉规则**——必须和其他 5 个 tab **明显区分**，让用户一眼看出"这不是主产品的一部分"：

- **图标**：用极简的线性档案夹图标，**不要**用其他 5 个 tab 的填充式米色风格
- **图标颜色**：始终为 `#B4A89A`（即未选中态色），不区分选中/未选中
- **文字标签**："原版" — 10px，颜色 `#B4A89A`
- **选中态**：唯一区别是文字下方加一个 2px 高的 `#B4A89A` 横线指示器，**不要让选中态变成主题色**

**原版 tab 的图标 SVG**：
```html
<svg viewBox="0 0 28 28" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 9 L11 9 L13 7 L23 7 L23 21 L5 21 Z"
        fill="none" stroke="#B4A89A" stroke-width="1.5"
        stroke-linejoin="round" stroke-linecap="round"/>
</svg>
```

**Tab 内容**：路由指向项目里**已经存在的旧首页代码**。Claude Code **不要重写、重构、修改、美化**这部分代码——它是参考用的备份。如果在代码库里找不到旧首页，必须停下来询问，**不要自己创建占位页**。

**dev-only 标记**：建议在该 tab 路由对应的页面顶部加一行**仅在开发环境可见**的提示横幅：
```
margin: 0
padding: 6px 12px
background: #FAEEDA
color: #633806
font-size: 11px
text-align: center
```
内容："⚠ 这是 v0 旧版首页（开发期参考用，正式版本将移除）"

横幅在生产构建时通过环境变量隐藏，**避免上线时被用户看到**。

**6 tab 布局的代价**：
- 每个 tab 在 375px 屏上宽度约 60px，触控目标接近最小可用阈值
- Mochi 不再正中心（变成位置 3 of 6 而非位置 3 of 5）
- 视觉密度上升

这些都是**开发期的临时妥协**。设计上不打算优化它，因为正式发版时这一切会随着原版 tab 的移除自动恢复。

### 5.2 卡片样式

#### 5.2.1 米色填充卡（默认数据卡）
```css
background: #F5EFE6;
border-radius: 16px;
border: none;
padding: 13px 14px;
```
用于首页"本书进度""错词本"，统计页三个数字卡，我的页"当前词书"。

#### 5.2.2 描边卡（次级信息）
```css
background: #FDFBF7;
border: 0.5px solid #E8DFCF;
border-radius: 16px;
padding: 11-13px 14px;
```
用于首页"5 分钟快速复习"，统计页"需要关注"列表项，我的页"日记预览"。

#### 5.2.3 紫色 hero 卡（主 CTA / 大数字）
```css
background: #6B4FA8;
border-radius: 22px;
padding: 22px 20px;
color: white;
position: relative; /* 为爪印水印做容器 */
overflow: hidden;
```
仅用于首页主 CTA。统计页 hero 是另一个变体（浅紫底深紫字），见 6.3。

#### 5.2.4 Mochi 暖色卡
```css
background: #FAECE7;
border-radius: 18px;
padding: 14px 16px;
```
用于首页打卡条、Mochi 页主插画背景。

### 5.3 列表组（设置项）

```css
border: 0.5px solid #E8DFCF;
background: #FDFBF7;
border-radius: 16px;
overflow: hidden;
```

每个列表项：
```css
padding: 13px 14px;
display: flex;
justify-content: space-between;
align-items: center;
border-bottom: 0.5px solid #ECE3D2;
font-size: 13px;
```
最后一项无 `border-bottom`。

**列表组前的小标题**：
```css
font-size: 11px;
color: #B4A89A;
margin-bottom: 8px;
padding-left: 22px; /* 与页面边距对齐 */
```

### 5.4 状态栏 mockup（仅设计稿）

实际实现使用系统状态栏，不要在 App 内部画。本规格书 mockup 中的 9:41 是设计稿示意，**不要实现成静态文字**。

---

## 6. 页面规格

### 6.1 首页

#### 6.1.1 信息层级（从上到下）
1. 顶部问候 + 当前词书名 + 用户头像（轻）
2. **Mochi 打卡条**（次重点，温度引擎）
3. **主 CTA：继续学习**（绝对视觉重心）
4. 两个数字卡：本书进度 / 错词本（次级信息）
5. 5 分钟快速复习入口（情境补救）
6. Tab bar

#### 6.1.2 顶部问候区
- 容器：`padding: 12px 22px 8px; display: flex; justify-content: space-between;`
- 左侧：
  - 上行："早上好，{用户名}" — 13px，`#888070`，weight 400
  - 下行：当前词书名（如"雅思核心词汇"）— 15px，`#2C2C2A`，weight 500
- 右侧：用户头像
  - 36×36px 圆形
  - 背景 `#F5EFE6`
  - 内容：用户名首字母 13px，`#6B4FA8`，weight 500
  - **可点**：进入"我的"页

**问候语动态规则**：
- 5:00-11:00 → "早上好"
- 11:00-13:00 → "中午好"
- 13:00-18:00 → "下午好"
- 18:00-23:00 → "晚上好"
- 23:00-5:00 → "夜深了"

#### 6.1.3 Mochi 打卡条
```
margin: 8px 22px 16px
padding: 14px 16px
background: #FAECE7
border-radius: 18px
display: flex; align-items: center; gap: 12px
```

**内容**：
- 左侧：Mochi 小头像 SVG（46×46px，使用 4.2 节的小尺寸 SVG）
- 右侧：
  - 主文："Mochi 等了你 {N} 小时" — 13px，`#4A1B0C`，weight 500
  - 副文："连续陪伴 {M} 天 · {状态}" — 11px，`#993C1D`，weight 400

**动态规则**：
- {N} = 自上次开启 App 至今的小时数（取整，最大显示 999）
- {M} = 连续打卡天数
- {状态}：
  - 今天还没学习 → "今天还没见面"
  - 今天已学习 → "今天已经一起学过啦"
  - 断签后第一天 → "好久不见"

**可点**：跳转到 Mochi 页。

#### 6.1.4 主 CTA：继续学习
```
margin: 0 22px 18px
padding: 22px 20px
background: #6B4FA8
border-radius: 22px
color: white
position: relative
overflow: hidden
```

**内部结构**：
- 顶部小字"今日任务" — 12px，opacity 0.78
- 主标题"继续学习" — 22px，weight 500，line-height 1.2
- 三段元数据（横排，gap 16px）：
  - "新词 {新词数}" — 12px，数字部分 14px weight 500
  - "复习 {复习数}"
  - "约 {时长} 分钟"
- 进度条：
  - 高 4px
  - 背景 `rgba(255,255,255,0.22)`
  - 填充 white
  - border-radius: 2px
- **右下角爪印水印**：
  - 32×32px
  - SVG 来自 4.3 节
  - color: white
  - opacity: 0.18
  - 绝对定位 `bottom: 14px; right: 16px`

**点击行为**：进入学习流程页面（学习流程页本规格书不覆盖）。

**文案规则**：
- 默认文案是"继续学习"，**不是"开始学习"** — 这是延续动作而非新决策
- 如果今日已完成，主标题改为"今天已完成 ✓"，元数据改为显示明日预告，CTA 仍可点（进入复习模式）

#### 6.1.5 数字卡组（本书进度 / 错词本）
两个并列卡片，`display: flex; gap: 10px`。

**本书进度卡**：
```
flex: 1
padding: 13px 14px
background: #F5EFE6
border-radius: 16px
```
- 上："本书进度" — 11px，`#888070`
- 下："{已学} <span>/ {总数}</span>" — 主数字 15px weight 500 `#6B4FA8`，分母 12px weight 400 `#B4A89A`

**错词本卡**：同样布局，文字颜色：
- 上："错词本"
- 下：主数字 `#993C1D`，副文 "{N} 个待巩固"

**点击行为**：分别进入本书详情页 / 错词复习页（不在本规格书覆盖范围）。

#### 6.1.6 5 分钟快速复习入口
```
margin: 0 22px 18px
padding: 11px 14px
border: 0.5px solid #E8DFCF
background: #FDFBF7
border-radius: 16px
display: flex; justify-content: space-between
```
- 左侧：
  - 上："时间不够？" — 12px，`#888070`
  - 下："5 分钟快速复习" — 13px，weight 500
- 右侧：右箭头 →，16px，`#B4A89A`

**动态规则**：仅在以下条件之一满足时显示：
- 当前是用户高频通勤时段（早 7-9，晚 17-19，依用户习惯）
- 用户今日剩余任务时间 > 15 分钟
- 用户连续 2 天断签

否则隐藏（不占空间）。

---

### 6.2 Mochi 页

#### 6.2.1 信息层级
1. 顶部：Mochi 名字 + 陪伴天数 + 羁绊等级 pill
2. **大 Mochi 插画区**（页面绝对视觉重心，包含对话气泡 + 新照片浮层 + 引导提示）
3. 进度条：距离下一阶段
4. 玫红色主 CTA：学单词赚小鱼干
5. 4 个次级入口：换装 / 房间 / 零食柜 / 日记
6. 日记预览卡
7. Tab bar

#### 6.2.2 顶部信息区
```
padding: 10px 22px 14px
display: flex; justify-content: space-between; align-items: center
```
- 左侧：
  - "Mochi" — 17px，weight 500
  - "陪伴你 {N} 天" — 11px，`#888070`
- 右侧：羁绊等级 pill
  - `padding: 5px 12px; background: #FBEAF0; border-radius: 999px`
  - "羁绊 Lv.{N}" — 11px，`#72243E`，weight 500

**动态规则**：
- {N} = 用户首次使用至今的天数
- 羁绊等级随累计学习单词数提升，具体等级表本文档不规定（待产品方提供）

#### 6.2.3 大 Mochi 插画区
```
margin: 0 22px 16px
padding: 18px 14px 8px
background: #FAECE7
border-radius: 18px
position: relative
overflow: hidden
```

**内部包含 4 个元素：**

**(a) 大 Mochi SVG**（4.1 节）
- 宽度 100%，高度 200px
- 居中显示
- **整个 SVG 可点**，触发 Mochi 互动动画

**(b) 对话气泡**（绝对定位）
- 位置：`top: 22px; right: 14px`
- 样式：
  ```
  background: white
  padding: 8px 12px
  border-radius: 14px 14px 14px 4px
  font-size: 11px
  color: #4A1B0C
  max-width: 130px
  line-height: 1.4
  ```
- 内容：根据状态动态变化的简短问候。示例：
  - 默认："今天也想和你 / 一起学单词～"
  - 已学完："今天也辛苦你了"
  - 断签 1 天："好像有点想你了"
  - 断签 3 天+："还记得我吗"

**(c) "+1 张新照片"浮层**（绝对定位，仅在有新照片时显示）
- 位置：`top: 14px; left: 14px`
- 样式：
  ```
  padding: 6px 10px 6px 8px
  background: white
  border-radius: 999px
  font-size: 10px
  color: #4A1B0C
  display: flex; align-items: center; gap: 6px
  box-shadow: 0 1px 3px rgba(0,0,0,0.06)
  ```
- 左侧小色块：14×14px，圆角 3px，背景 `#F0997B`
- 右侧文字："+1 张新照片"
- **可点**：跳转相册（相册子页本规格书不覆盖）。**点击后该浮层消失**，下次有新照片时再次出现。

**(d) 引导提示**（仅新用户首次进入此页时显示）
- 位置：插画下方居中
- 样式：
  ```
  text-align: center
  font-size: 10px
  color: #993C1D
  opacity: 0.7
  padding-bottom: 4px
  ```
- 内容："轻轻戳一下试试"
- **永久消失逻辑**：用户第一次点击 Mochi 插画后，永久隐藏（写入用户本地状态）。

#### 6.2.4 进度条区
```
margin: 0 22px 16px
```
- 上行：左侧"距离下一阶段" 11px `#888070`，右侧"背 {N} 个词解锁" 11px `#888070`
- 进度条：
  ```
  height: 6px
  background: #FBEAF0
  border-radius: 3px
  ```
  - 填充：`background: #D4537E; border-radius: 3px`
  - 宽度根据当前进度动态计算

#### 6.2.5 Mochi 主 CTA
```
margin: 0 22px 16px
padding: 16px
background: #D4537E
border-radius: 18px
color: white
```
- 上："今天还没喂 Mochi" — 12px，opacity 0.85
- 下："学单词，赚小鱼干 →" — 16px，weight 500

**动态规则**：
- 已喂过 → 隐藏整个卡片，或改为"今天已经一起学过啦"中性文案
- 文案永远不要出现"再不喂就饿了""快饿死了"等负向情绪

**点击行为**：跳转到学习页（与首页主 CTA 同一目的地）。

#### 6.2.6 4 个次级入口
```
margin: 0 22px 18px
display: flex; gap: 8px
```
每个入口：
```
flex: 1
padding: 14px 8px
background: #F5EFE6
border-radius: 16px
text-align: center
position: relative
```
- 上方：24×24px 占位色块（图标待补，本规格书不规定具体图标）
- 下方：标签 11px，`#2C2C2A`

**4 个入口的标签和占位色**：

| 序号 | 标签 | 占位色 | 形状 | 备注 |
|---|---|---|---|---|
| 1 | 换装 | `#F0997B` | 4px 圆角方 | |
| 2 | 房间 | `#FAC775` | 4px 圆角方 | |
| 3 | 零食柜 | `#F4C0D1` | 圆形 | **带数字角标** |
| 4 | 日记 | `#AFA9EC` | 4px 圆角方 | |

**零食柜数字角标**：
- 位置：右上角 `position: absolute; top: 8px; right: 14px`
- 样式：
  ```
  padding: 1px 5px
  background: #D4537E
  border-radius: 999px
  font-size: 9px
  color: white
  font-weight: 500
  ```
- 内容：当前小鱼干余额数字
- **重要**：这个角标显示的是**资源数量**（信息），不是未读红点（焦虑）。即使为 0 也显示"0"，不要变成红点。

**点击行为**：分别跳转到 4 个子页（**子页本规格书不覆盖，标注为待补**）。

#### 6.2.7 日记预览卡
```
margin: 0 22px 18px
padding: 12px 14px
border: 0.5px solid #E8DFCF
background: #FDFBF7
border-radius: 16px
```
- 顶部："Mochi 的日记 · 今天" — 10px，`#B4A89A`
- 主体：日记正文 — 12px，`#2C2C2A`，line-height 1.55，**font-style: italic**
- 内容示例："主人今早学了 15 个新词，比昨天多了 3 个。我趴在她键盘旁边假装睡觉，其实一直在偷看。"

**生成规则**：
- 后端根据当日学习数据 + 模板生成
- 必须是第三人称叙事（Mochi 视角）
- 必须包含至少一个真实数据点（学的单词数、对比、时段等）
- 不要使用"主人"这个词如果用户在 onboarding 选择了"高冷"等其他人格——人格系统是后续可扩展项

**点击行为**：跳转日记完整列表（待补）。

---

### 6.3 统计页

#### 6.3.1 信息层级
1. 顶部页面标题"学习统计"
2. **大数字 Hero**：已掌握 1240（视觉重心，正向叙事）
3. 三个核心指标：连续 / 本周 / 记忆率
4. 12 周热力图
5. 本周亮点（绿色）
6. "需要关注"行动列表
7. **Mochi 落款**（情感退出）
8. Tab bar

#### 6.3.2 页面标题
```
padding: 10px 22px 14px
font-size: 18px
font-weight: 500
```
内容："学习统计"

#### 6.3.3 大数字 Hero 卡
```
margin: 0 22px 18px
padding: 22px 18px
background: #EEEDFE
border-radius: 22px
text-align: center
position: relative
overflow: hidden
```
- 上："已掌握" — 12px，`#6B4FA8`
- 中："{N}" — 38px，weight 500，`#26215C`，line-height 1
- 下："个单词 · 占本书 {P}%" — 12px，`#6B4FA8`
- 进度条：
  ```
  margin-top: 14px
  height: 5px
  background: rgba(107,79,168,0.18)
  border-radius: 3px
  ```
  - 填充：`#6B4FA8`，宽度 = P%

- **右下角爪印水印**：
  - 位置：`bottom: 14px; right: 16px`
  - 30×30px
  - SVG 来自 4.3 节
  - color: `#6B4FA8`
  - opacity: 0.22

**关键设计纪律**：这个卡片的 hero 数字是**已掌握的数字**，不是"还差多少"。永远不要显示成"还需 2260 个"——这会触发焦虑。

#### 6.3.4 三个核心指标卡
```
margin: 0 22px 16px
display: flex; gap: 10px
```
每个：
```
flex: 1
padding: 13px 12px
background: #F5EFE6
border-radius: 16px
```

| 卡片 | 上方标签 | 主数字 + 单位 | 主数字颜色 |
|---|---|---|---|
| 连续 | "连续" | "{N} <span>天</span>" | `#993C1D`（珊瑚） |
| 本周 | "本周" | "{N} <span>个新词</span>" | `#6B4FA8`（暖紫） |
| 记忆率 | "记忆率" | "{N}<span>%</span>" | `#6B4FA8`（暖紫） |

- 标签：11px `#888070`
- 主数字：18px weight 500
- 单位：11px weight 400 `#B4A89A`

**为什么"连续"用珊瑚而不是紫**：连续天数代表的是坚持/承诺/情感，珊瑚色温度更高；其他两个是认知性数据，用紫色统一。这个色彩区分是有意的，**请勿统一**。

#### 6.3.5 12 周热力图
```
margin: 0 22px 18px
```
- 标题行：左"最近 12 周" 13px weight 500，右"深色 = 学得多" 11px `#888070`
- 热力图本体：SVG，3 行 × 12 列方格

**SVG 模板**：
```html
<svg viewBox="0 0 280 70" style="width: 100%; height: auto;">
  <!-- 第一行：12 个方格 -->
  <rect x="{i*22}" y="0" width="20" height="14" rx="3" fill="{color}"/>
  <!-- 第二行 y="16" -->
  <!-- 第三行 y="32" -->
  <!-- 标签 -->
  <text x="0" y="62" font-size="9" fill="#B4A89A">12 周前</text>
  <text x="240" y="62" font-size="9" fill="#B4A89A">本周</text>
</svg>
```

**color 取值**（按学习强度从弱到强）：
- 最弱：`#EEEDFE`
- 弱：`#CECBF6`
- 中弱：`#AFA9EC`
- 中：`#7F77DD`
- 强：`#6B4FA8`

**重要**：所有方格 `rx="3"` 不是 `rx="2"`——更圆润。
**禁止**：不要用红绿配色。同一色系深浅是中性叙事，红绿会让"浅色周"变成失败标签。

#### 6.3.6 本周亮点（绿色）
```
margin: 0 22px 18px
padding: 14px 16px
background: #E1F5EE
border-radius: 16px
```
- 上："本周亮点" — 11px，`#0F6E56`
- 下：亮点正文 — 13px，weight 500，`#04342C`，line-height 1.5

**生成规则**：后端从本周数据中自动提取 1-2 条积极信号。示例：
- "你比上周多记了 18 个词，记忆率提升了 4%"
- "你坚持了整整一周没有断签"
- "新词记忆率比上月高 12%，学得更稳了"

**纪律**：永远是正向叙事。即使本周比上周差，也找一个积极角度（如"虽然新词少了，但复习扎实，记忆率反而上升"）。如果完全没有正向数据，**整个卡片隐藏**，不要硬塞负面消息。

#### 6.3.7 需要关注列表
```
margin: 0 22px 18px
```
- 标题："需要关注" — 13px weight 500
- 列表项（描边卡样式）：

每项：
```
padding: 13px 14px
border: 0.5px solid #E8DFCF
background: #FDFBF7
border-radius: 16px
margin-bottom: 8px
display: flex; justify-content: space-between
```
- 左侧主文 13px，副文 11px `#888070`
- 右侧 `→` 16px `#B4A89A`

**默认两项**：
1. 易遗忘词 — "{N} 个易遗忘词" / "建议今天巩固"
2. 完成预测 — "按当前进度" / "预计 {日期} 学完"

**纪律**：第二项的措辞永远是"按当前进度"中性陈述，不要用"如果你不努力 / 否则要更久"这种施压语言。

#### 6.3.8 Mochi 落款
```
margin: 0 22px 22px
display: flex; align-items: center; justify-content: center; gap: 10px
```
- 左：Mochi 小头像 SVG（32×32px，4.2 节）
- 右：文字"Mochi 见证了你的 {N} 天" — 11px，`#888070`，**font-style: italic**

**绝对纪律**：
- 不可点（不是入口）
- 不要加大、加粗、加色块
- 不要变成卡片
- 它的功能就是"被看到，被感受，然后被忘记"——任何视觉权重的提升都会破坏 peak-end rule 的退出情绪设计

---

### 6.4 我的页

#### 6.4.1 信息层级
1. 用户身份区（头像 + 名字 + 元信息）
2. 当前词书卡（高频切换入口）
3. 设置组：学习
4. 设置组：数据
5. 设置组：关于
6. Tab bar

#### 6.4.2 用户身份区
```
padding: 14px 22px 18px
display: flex; align-items: center; gap: 14px
```
- 左：用户头像 54×54px 圆形
  - 背景 `#FAECE7`
  - 内容：默认显示 Mochi 小头像 SVG（4.2 节，44×44px 居中）
  - 用户也可上传自己的照片替换，但默认是 Mochi
- 中：
  - "Alex" — 16px weight 500
  - "加入 {N} 天 · 共掌握 {M} 词" — 12px `#888070`
- 右：`→` 16px `#B4A89A`

**点击行为**：进入个人资料编辑页（待补）。

**设计纪律**：副文里**永远是用户的成就**，不是 Mochi 的状态。这是用户的页，Mochi 只是头像里的旁观者。绝对不要写"Mochi 长大了 187 天"。

#### 6.4.3 当前词书卡
```
margin: 0 22px 18px
padding: 16px
background: #F5EFE6
border-radius: 18px
```
- 顶部行：左"当前词书" 12px `#888070`，右"切换 →" 11px `#6B4FA8` weight 500
- 主标题：词书名 — 15px weight 500
- 副文：进度 — 11px `#B4A89A`

**重要**：右上角"切换 →"是页面里唯一带颜色的高频操作入口。这个紫色提示是**有意的视觉权重**，用户切换词书的频率高于其他任何设置项，必须最快被找到。

#### 6.4.4 设置组：学习
小标题"学习"：11px `#B4A89A` `padding-left: 22px; margin-bottom: 8px`

列表组：使用 5.3 节的列表组样式。

**4 个项**：

| 标签 | 当前值 | 备注 |
|---|---|---|
| 每日新词数量 | 15 → | 数值用户可调，5-50 之间 |
| 复习算法 | 艾宾浩斯 → | 默认艾宾浩斯，可选 SuperMemo / 自定义 |
| 学习提醒 | 每天 8:00 → | 可关闭 |
| 发音 | 英式 → | 英式 / 美式 |

每项右侧值文字 13px `#888070`。

**设计纪律**：复习算法这一项**必须露出**，不要藏到深层菜单。愿意点这一项的用户是核心用户，他们值得被尊重。

#### 6.4.5 设置组：数据
小标题"数据"。

**2 个项**：

| 标签 | 右侧 | 备注 |
|---|---|---|
| 同步与备份 | "5 分钟前 →" | 显示上次同步时间 |
| 导出学习记录 | → | 11px `#888070` |

#### 6.4.6 设置组：关于
小标题"关于"。

**2 个项**：

| 标签 | 右侧 | 备注 |
|---|---|---|
| 帮助与反馈 | → | |
| 版本 | "3.4.1" | **不可点**，只是显示 |

版本号的右侧文字用 12px `#B4A89A`，左侧标签用 13px `#888070`——颜色比其他列表项更淡，因为它不是行动项。

**绝对不要做的**：不要加"评分""邀请好友""会员中心""签到""每日任务"这类干扰项。如果未来有付费或会员，开新页面，不要塞进我的页。

---

## 7. 交互行为

### 7.1 路由
四个 tab 之间的切换是**纯页面替换**，无动画过渡。Tab 状态通过路由管理。

### 7.2 Mochi 互动
- 点击大 Mochi 插画 → 触发互动动画（眯眼 / 翻肚 / 咕噜咕噜，具体动效本文档不规定）
- 第一次点击后，"轻轻戳一下试试"引导提示永久消失
- Mochi 永远不会有负向反馈状态（不会拒绝、生气、消失）

### 7.3 Mochi 头像 vs Mochi 跳转
**重要区分**：
- 首页打卡条点击 → 跳转到 Mochi 页
- 我的页头像点击 → **进入个人资料编辑页**（不是 Mochi 页）。这是用户编辑自己资料的入口，Mochi 只是默认头像。

### 7.4 浮层与提示
- 新照片浮层：仅当 Mochi 相册有未查看的新照片时出现，点击后消失，下次新照片再次出现
- 引导提示："轻轻戳一下试试"是一次性，使用本地存储记录已显示
- **绝对不要**有任何弹窗式祝贺、连续打卡破纪录庆祝、升级动画。Mochi 的成长是后台叙事，不是前台干扰

### 7.5 主 CTA 行为
- 首页"继续学习" + Mochi 页"学单词赚小鱼干" + 数字卡点击 = **同一个目标**：进入学习流程页面
- 学习流程页面本规格书不覆盖

### 7.6 暗色模式
**v1.0 暂不支持暗色模式**。如果未来要做，需要重新设计整套色板（米色背景在暗色模式下不工作）。本文档所有颜色仅适用于浅色模式。

---

## 8. 实现注意事项（给 Claude Code）

### 8.1 技术栈建议
本规格书不绑定具体技术栈。建议：
- **如果用 React Native**：使用 NativeWind（Tailwind for RN）或 styled-components。所有 SVG 用 `react-native-svg`。
- **如果用 Flutter**：使用 `flutter_svg` 渲染 SVG，自定义 Theme 实现 tokens。
- **如果用 Web**（H5 或 PWA）：原生 CSS + SVG inline，移动端宽度建议 320-414px 适配。

### 8.2 必须严格执行的纪律
1. **所有颜色 hex 值必须精确**——不要"差不多就行"地换近似色，色板的每一个值都是经过校准的。
2. **字重只有 400 和 500**——不要用 600/700。
3. **不使用任何阴影**（除前面明确允许的 1 处轻阴影）。
4. **不使用任何渐变**（背景、文字、按钮都不行）。
5. **font-size 最小 11px**，绝对不允许更小。
6. **Mochi SVG 不要修改**任何路径——这是品牌资产。如果尺寸需要变化，只调整 viewBox 显示尺寸，不动内部坐标。

### 8.3 占位数据
本规格书所有数字、人名、词书名都是示例：
- "Alex"、"187 天"、"1240 词"、"47 天连续"、"82 个本周新词"、"89% 记忆率"、"雅思核心词汇"

实现时需对接真实数据源。如果测试期间没有数据，使用上述示例值。

### 8.4 字体加载
不要引入任何 web font 或第三方字体。直接使用系统默认 sans-serif（见 3.2 节字体堆栈）。理由：
- 加载延迟会破坏首屏体验
- 系统字体在中文渲染上更可靠
- 体积小，启动快

### 8.5 Mochi 资源管理
Mochi SVG 应作为**项目内静态资源**，不要动态加载。建议：
- 大 Mochi（4.1）、小 Mochi（4.2）、爪印（4.3）作为 3 个独立 SVG 组件
- Tab bar 5 个图标作为一组图标组件，接受 `selected: boolean` prop 切换颜色

### 8.6 路由结构示例
```
/                    → 首页
/cat                 → Mochi 页
/stats               → 统计页
/profile             → 我的页
/books               → 词书页（待补）
/legacy              → 原版（指向已存在的旧首页代码，不要重写）
/learn               → 学习流程（待补）
/cat/dressup         → 换装（待补）
/cat/room            → 房间（待补）
/cat/snacks          → 零食柜（待补）
/cat/diary           → 日记列表（待补）
/cat/album           → 相册（待补）
/profile/edit        → 个人资料编辑（待补）
```

### 8.7 状态管理边界
本规格书覆盖的状态：
- 当前选中 tab
- Mochi 引导提示是否已显示过
- 新照片浮层显示状态
- 显示用的所有数据值（本规格书定义为来自 props/data source）

不覆盖的状态：学习流程、登录态、网络状态、错误处理、加载状态。这些需要单独设计。

### 8.8 不要做的事（重要）
按重要性排：
1. **不要为了美观加任何渐变、阴影、模糊效果**——这是 v1.0 的核心审美纪律。
2. **不要把 tab bar 改成自定义形状**（弧形、凹陷、悬浮）——保持标准底栏。
3. **不要在任何地方加 Toast / Snackbar 通知** v1.0。如果需要反馈，用页面内联状态。
4. **不要改 Mochi 的眼睛形状**——眯眼是品牌特征。睁眼版本是另一种状态，需要单独设计。
5. **不要把"我的"页头像换成更复杂的展示**（比如等级勋章、连续打卡环）——克制是它的核心价值。
6. **不要给任何按钮加 hover 动画的 box-shadow**——保持平面。

---

## 9. 范围外 / 待补内容

以下内容**不在本规格书覆盖范围内**，需要单独设计或后续补充。Claude Code 实现时遇到这些请**停下询问**，不要擅自补全：

### 9.1 未设计的页面
- **词书页**（tab bar 第 2 个 tab）— 完全未设计
- **学习流程页**（点主 CTA 后的页面）— 完全未设计

### 9.2 Mochi 页的子页（4 个次级入口的目的地）
- 换装页
- 房间页
- 零食柜页
- 日记完整列表页

### 9.3 其他子页
- 个人资料编辑页（点我的页头像后）
- Mochi 相册页（点新照片浮层后）
- 错词本详情页（点首页"错词本"卡片后）
- 词书切换页（点我的页"切换"后）
- 单项设置详情（如调整每日新词数的具体页面）

### 9.4 系统级功能
- 登录 / 注册流程
- Onboarding（首次使用引导）
- 暗色模式
- 国际化（目前只有中文版）
- 无障碍（A11y）— 需要单独评估
- 推送通知设计

### 9.5 动效与微交互
- Mochi 互动动画的具体帧
- Tab 切换是否要过渡（v1 默认无过渡）
- 加载状态（loading skeleton 等）
- 空状态设计

### 9.6 数据契约
- API 接口
- 数据模型
- 同步策略

---

## 10. 验收标准

实现完成后，按以下标准验收：

### 10.1 像素级
- 4 个页面在 iPhone 12/13/14（390×844）上完整显示，无横向滚动
- 所有颜色 hex 与本文档 100% 一致（用取色器验证）
- 所有圆角与本文档一致
- 字号、字重无偏差

### 10.2 行为
- Tab bar 5 个 tab 切换正常，选中态正确
- 首页打卡条可点跳转 Mochi 页
- Mochi 大插画可点（即使无动画也要有点击反馈）
- 我的页头像可点
- 新照片浮层、引导提示按规则出现 / 消失

### 10.3 设计纪律
- 没有任何渐变、阴影、字体描边
- 没有任何红点焦虑元素
- 没有任何"快饿死了"式负向情绪文案
- Mochi SVG 未被修改

### 10.4 萌度
最终的整体感受应该是："温暖、克制、像一个真实存在的小室友陪伴学习"。
**不应该是**："非常可爱"或"看起来很专业"——前者过头，后者不够。
**参考产品**：Duolingo 的温度、Headspace 的克制、Neko Atsume 的角色感——三者中间的位置。

---

## 附录 A：版本

- v1.0（本版本）：4 个主页面 + 共享组件 + 设计 tokens 完整定稿。词书页、学习页、所有子页待补。

## 附录 B：决策日志

本规格书的每一项设计选择都有底层依据。如果未来需要修改，请先理解原因再动手。

| 决策 | 依据 |
|---|---|
| 全局背景用 #FDFBF7 而非纯白 | 暖米色制造"纸张感"，比"屏幕感"减少认知摩擦 |
| 主 CTA 用 #6B4FA8 而非冷紫 | 暖紫与 Mochi 桃米色形成色温一致的色系 |
| Tab bar 用填充图标而非线性 | 情感型产品适配填充图标，触发 Kindchenschema 反应 |
| Mochi 必须出现在 3 个非猫页 | 防止"猫被关在猫页里"，落实情感连续性 |
| 统计页 hero 用"已掌握"不用"还差" | 正向叙事，避免焦虑 |
| 删除"抚摸"按钮 | 猫本身可点是 affordance 原理的直接应用，按钮是赘余 |
| 删除"相册"按钮 | 低频功能不该占主屏入口位，用浮层代替 |
| "羁绊 Lv.X"保留中文乙女向词汇 | 服务核心人群（女性向定位），不为路过的人妥协 |
| Mochi 永不死亡/生病 | 反"赛博宠物"焦虑机制，长期留存优于短期触发 |
| tab bar 中 Mochi 略大 | 差异化在物理上的体现，但不打破对称 |
| 字重只用 400/500 | 600/700 显得过重，破坏温柔感 |
| 全 App 不使用阴影 | 平面化保持高级感，阴影易显廉价 |

---

**文档结束。**

如果实现过程中有疑问，请优先参考本文档的"设计纪律"和"绝对不要做的事"——这些是**有意的克制**，不是疏忽。

如果某项细节本文档没有明确规定，按以下优先级判断：
1. 是否符合"克制原则"？
2. 是否服务"温柔的工具"定位？
3. 是否会让 15-35 女性目标用户感到舒服？

不要默认套用 Material Design 或 iOS HIG 的完整规则，本产品有自己的设计语言。
