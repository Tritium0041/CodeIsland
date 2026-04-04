# CodeIsland Mobile 项目计划书

## 一、项目概述

### 产品名称
**CodeIsland Mobile** — iPhone 远程监控 Claude Code 会话

### 一句话定位
离开电脑也能掌控 AI 编程——iPhone 灵动岛实时监控、远程审批、推送告警。

### 产品关系
| 产品 | 平台 | 定价 | 定位 |
|------|------|------|------|
| CodeIsland | macOS | 免费开源 | 基础盘，涨粉引流 |
| CodeIsland Mobile | iOS | ¥28 买断 | 变现产品，独家功能 |

### 市场空白
| 竞品 | Mac 灵动岛 | iPhone 远程监控 | 远程审批 |
|------|-----------|---------------|---------|
| CodeIsland (Mac) | ✅ 免费 | ❌ | ❌ |
| Agentfy | ✅ 免费 | ❌ | ❌ |
| Codync | ✅ 免费 | ❌ | ❌ |
| Vibe Island | ✅ $14.99 | ❌ | ❌ |
| **CodeIsland Mobile** | — | **✅** | **✅** |

**结论：零竞品，全新品类。**

---

## 二、目标用户

### 核心用户画像
- 使用 Claude Code 的开发者
- 经常多任务并行（挂着 Claude 跑，自己去做其他事）
- MacBook + iPhone 用户（同一 Apple ID）
- 愿意为效率工具付费

### 使用场景
| 场景 | 痛点 | CodeIsland Mobile 解决方案 |
|------|------|--------------------------|
| 挂着 Claude 跑任务去开会 | 不知道跑完没 | 灵动岛实时状态 + 推送通知 |
| Claude 需要审批但人不在电脑前 | 任务卡住等你回来 | 手机远程审批，Claude 继续跑 |
| 同时跑 3-5 个项目 | 不知道哪个完了哪个出错了 | 手机会话列表一览全部状态 |
| 晚上睡觉前挂任务 | 早上不知道结果 | 锁屏通知 + 早上看灵动岛 |

---

## 三、功能规划

### v1.0（首发 MVP）

#### 核心功能
| 功能 | 优先级 | 说明 |
|------|--------|------|
| **灵动岛状态** | P0 | 折叠态显示最高优先级会话状态（Working/Done/Error） |
| **锁屏 Live Activity** | P0 | 展开显示所有活跃会话列表 |
| **推送通知** | P0 | 完成/出错/需要审批时推送 |
| **会话列表** | P0 | 主 App 内查看所有会话（状态、工具、时长） |
| **远程审批** | P0 | 手机上 approve/deny Claude 的权限请求 |
| **iCloud 同步** | P0 | 零配置，同 Apple ID 自动同步 |

#### 灵动岛 UI 规格

```
折叠态（紧凑视图）：
┌──────────────────────────────────┐
│  🐢  Working...         ×2     │
└──────────────────────────────────┘

展开态（长按展开）：
┌──────────────────────────────────┐
│  CodeIsland    进行中     31m   │
│  icare         已完成     25m   │
│                                  │
│      [ 拒绝 ]  [ 允许 ]         │
└──────────────────────────────────┘

锁屏卡片：
┌──────────────────────────────────┐
│ 🐢 CodeIsland Mobile            │
│                                  │
│ ● CodeIsland  进行中  Edit  31m │
│ ● icare       已完成  Bash  25m │
│                                  │
│ Claude 正在编辑 NotchView.swift  │
└──────────────────────────────────┘
```

### v2.0（后续迭代）
| 功能 | 说明 |
|------|------|
| Apple Watch 支持 | 手表表盘显示会话状态 |
| 对话预览 | 查看最近几条消息 |
| diff 预览 | 审批时查看代码变更 |
| Buddy 宠物互动 | 手机上和 Buddy 互动 |
| 自定义通知音 | 8-bit 芯片音风格 |
| iPad 支持 | iPad 适配 |

---

## 四、技术架构

### 数据同步方案：iCloud CloudKit

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  Mac 端      │         │   iCloud    │         │  iPhone 端   │
│  CodeIsland  │────────→│  KV Store   │────────→│  Mobile App  │
│              │  写入    │  (Apple)    │  监听    │              │
│  Hook事件    │         │  零成本     │         │  灵动岛      │
│  状态变化    │         │  <2s 延迟   │         │  推送通知    │
│  审批结果  ←─│─────────│─────────────│─────────│─ 远程审批    │
└─────────────┘  读取    └─────────────┘  写入   └─────────────┘
```

**为什么选 iCloud 而不是自建服务器：**
| 对比 | iCloud | 自建 WebSocket |
|------|--------|---------------|
| 服务器成本 | ¥0 | ¥0（现有服务器） |
| 运维 | Apple 托管，零运维 | 需要监控、重启 |
| 延迟 | 1-2 秒 | 100-500ms |
| 隐私 | 数据不离开用户设备 | 经过你的服务器 |
| 离线 | 自动缓存 | 断线丢失 |
| 跨网络 | 任何网络都行 | 需要公网 |

iCloud 延迟略高但在 3 秒内，且零成本零运维，综合最优。

### Mac 端改动（CodeIsland）

新增一个 `iCloudSync` 模块：
```swift
// 写入会话状态到 iCloud KV Store
NSUbiquitousKeyValueStore.default.set(sessionData, forKey: "sessions")

// 写入审批请求
NSUbiquitousKeyValueStore.default.set(approvalData, forKey: "pendingApproval")

// 监听 iPhone 端的审批结果
NotificationCenter.default.addObserver(
    forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification
)
```

### iPhone 端技术栈
| 组件 | 技术 |
|------|------|
| UI 框架 | SwiftUI |
| 灵动岛 | ActivityKit (Live Activities) |
| 数据同步 | CloudKit / NSUbiquitousKeyValueStore |
| 推送 | 本地通知（iCloud 变更触发） |
| 状态管理 | @Observable (Swift 5.9) |
| 最低版本 | iOS 18.0 |

### 项目结构
```
CodeIslandMobile/
├── App/
│   ├── CodeIslandMobileApp.swift      # 入口
│   └── ContentView.swift               # 主界面
├── Models/
│   ├── SessionState.swift              # 会话状态（与 Mac 端共享定义）
│   ├── ApprovalRequest.swift           # 审批请求模型
│   └── SyncPayload.swift              # iCloud 同步数据格式
├── Services/
│   ├── CloudSyncManager.swift          # iCloud 读写
│   ├── NotificationManager.swift       # 本地推送
│   └── LiveActivityManager.swift       # 灵动岛管理
├── Views/
│   ├── SessionListView.swift           # 会话列表
│   ├── SessionDetailView.swift         # 会话详情
│   ├── ApprovalView.swift             # 审批面板
│   └── SettingsView.swift             # 设置
├── LiveActivity/
│   ├── CodeIslandWidgetBundle.swift    # Widget 入口
│   ├── LiveActivityView.swift         # 灵动岛 UI
│   └── LockScreenView.swift           # 锁屏卡片 UI
└── Assets.xcassets/
```

---

## 五、开发排期

### 总工期：14 个工作日

| 阶段 | 天数 | 任务 |
|------|------|------|
| **第 1-2 天** | 2 | 项目搭建 + 数据模型定义 + iCloud 同步基础 |
| **第 3-4 天** | 2 | Mac 端 CodeIsland 添加 iCloud 写入模块 |
| **第 5-7 天** | 3 | iPhone 主 App UI（会话列表、详情、设置） |
| **第 8-9 天** | 2 | 灵动岛 Live Activity（折叠态 + 展开态 + 锁屏） |
| **第 10 天** | 1 | 推送通知（完成/出错/审批） |
| **第 11-12 天** | 2 | 远程审批功能（双向 iCloud 通信） |
| **第 13 天** | 1 | 联调测试（Mac ↔ iPhone 全链路） |
| **第 14 天** | 1 | App Store 准备（截图、描述、提审） |

### 里程碑

```
Week 1: 基础打通
  ✓ Mac 端写入 iCloud
  ✓ iPhone 端读取并展示会话列表
  ✓ 数据同步延迟 < 3s 验证

Week 2: 功能完成
  ✓ 灵动岛 Live Activity
  ✓ 推送通知
  ✓ 远程审批
  ✓ 联调通过

Week 3: 上线
  ✓ App Store 提审
  ✓ 小红书/社交媒体推广
  ✓ 用户反馈收集
```

---

## 六、商业模式

### 定价策略
| 方案 | 价格 | 理由 |
|------|------|------|
| **App Store 买断** | **¥28 / $3.99** | 零竞品定价权；买断不订阅是卖点；低于冲动消费阈值 |

### 收入预估（保守）
| 指标 | 数值 | 说明 |
|------|------|------|
| Mac 端用户 | 1000（3 个月内） | 开源免费，自然增长 |
| 转化率 | 5% | Mac 用户中购买 iOS 版的比例 |
| 付费用户 | 50 人 | 1000 × 5% |
| 单价 | ¥28 | 买断 |
| Apple 抽成 | 30% | 首年 |
| **净收入** | **¥980** | 50 × 28 × 0.7 |

### 收入预估（乐观）
| 指标 | 数值 |
|------|------|
| Mac 端用户 | 5000 |
| 转化率 | 8% |
| 付费用户 | 400 人 |
| **净收入** | **¥7,840** |

### 长期变现
- 后续大版本更新可提价到 ¥38
- Apple Watch 版可单独内购 ¥12
- 企业版（多人团队监控）另行定价

---

## 七、推广计划

### 上线前（Mac 版推广期）
| 时间 | 动作 |
|------|------|
| 现在 | 继续推广 Mac 免费版，积累用户基数 |
| 开发期间 | 小红书/即刻发开发过程（"我在做 iPhone 版了"） |
| 提审前 | 发预告视频，引导关注等上线通知 |

### 上线后
| 渠道 | 内容 |
|------|------|
| 小红书 | "Claude Code 用户必装！手机也能监控 AI 写代码了" |
| 即刻 | 开发者社区精准投放 |
| V2EX | 技术社区推广 |
| Product Hunt | 海外首发，获取国际用户 |
| GitHub | Mac 版 README 加上 iOS 版链接 |

### 推广话术
```
你的 Claude 还在跑，你已经在星巴克了。
打开手机一看——灵动岛上写着 "已完成 ✓"
要审批？手机上一点，Claude 继续跑。

CodeIsland Mobile
¥28 买断 不订阅
```

---

## 八、风险评估

| 风险 | 概率 | 影响 | 应对 |
|------|------|------|------|
| App Store 审核被拒 | 中 | 延迟上线 | 提前研究审核指南，准备申诉材料 |
| iCloud 同步延迟 >3s | 低 | 体验差 | 备选 WebSocket 方案（现有服务器） |
| Claude Code hooks API 变更 | 低 | 功能失效 | Mac 端做适配层，iPhone 端不受影响 |
| Live Activity 被 iOS 杀死 | 中 | 灵动岛冻结 | 推送通知兜底 + 自动重建 Activity |
| 用户付费意愿低 | 中 | 收入不达预期 | 先免费试用 3 天，体验后付费 |

---

## 九、成本汇总

| 项目 | 费用 | 说明 |
|------|------|------|
| Apple Developer 账号 | ¥0 | 已有 |
| 服务器 | ¥0 | iCloud 方案，不需要额外服务器 |
| 域名 | ¥0 | 已有 qxju.shop |
| 设计 | ¥0 | 复用 Mac 端设计语言 |
| 开发 | 14 天人力 | 自己开发 |
| **总成本** | **¥0 + 14 天时间** | |

---

## 十、验收标准

### 上线前必须满足
- [ ] Mac → iPhone 数据同步延迟 < 3 秒
- [ ] 灵动岛正确显示会话状态（Working/Done/Error/Approval）
- [ ] 推送通知在 5 秒内送达
- [ ] 远程审批全链路 < 5 秒（点按钮到 Claude 继续执行）
- [ ] App 后台 30 分钟内不被系统杀死
- [ ] 冷启动 < 2 秒
- [ ] iPhone 14 Pro / 15 / 16 全系列适配
- [ ] 支持中英双语
