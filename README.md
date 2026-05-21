# mobile_app

一款基于 Flutter 的个人记账 App，本地优先存储，覆盖 **记账 / 分类 / 预算 / 统计 / 历史 / 导出 / 语音记账** 全流程。Material 3 设计，移动端、桌面端、Web 端同一份代码运行。

## 功能一览

- **记一笔**：支出 / 收入快速录入，类别图标网格选择，金额带正负色彩预览
- **类别管理**：自带常用类别，支持自定义图标、颜色、收入/支出类型的增删改
- **预算**：按月设置总预算和分类别预算，主页与统计页用进度条直观展示进度（< 80% 主色、80–100% 橙色、超支红色）
- **统计**：饼图（按类别占比）+ 折线图（按日趋势）+ 关键指标，支持收入 / 支出切换
- **历史**：按日期、类别、支付方式多维筛选 + 关键词搜索 + CSV 导出（带 UTF-8 BOM，Excel 直接打开不乱码）
- **语音记账**：录音 → 语音转文字 → OpenAI 兼容大模型抽取「类型 / 金额 / 类别 / 备注 / 日期 / 支付方式」→ 预填表单等用户确认
- **跨平台**：Android / iOS / Windows / macOS / Linux / Web 全部跑得起来；Web 端 CSV 走浏览器下载，桌面端落到 Documents 目录

## 技术栈

| 类别 | 选型 |
|---|---|
| 框架 | Flutter 3.19+ / Dart 3.3+，Material 3 |
| 状态管理 | flutter_riverpod |
| 本地存储 | Hive（业务数据）+ flutter_secure_storage（API Key 等敏感字段） |
| 路由 | go_router |
| 图表 | fl_chart |
| 语音 | speech_to_text（平台原生引擎）+ permission_handler |
| 网络 | http（OpenAI 兼容 chat/completions） |
| 代码生成 | build_runner + hive_generator |

## 目录结构

```
lib/
├── main.dart                # 入口 + 异步 hydrate（Hive、AI 配置）
├── app/                     # MaterialApp、路由、主题
├── models/                  # Hive 模型：Expense / Category / Budget
├── providers/               # Riverpod：列表、筛选、统计、预算进度、AI 配置
├── services/                # Hive 服务、CSV 导出（条件导入区分 Web / IO）、
│                            # 语音识别封装、OpenAI 抽取
├── screens/                 # 主页、记一笔、统计、历史、设置、预算、
│                            # 分类管理、AI 设置
├── widgets/                 # 类别选择器、预算进度卡、语音录入弹层等
└── utils/                   # 常量、默认类别、格式化、校验、图标目录
```

## 起步

### 前置依赖

- Flutter SDK ≥ 3.19，Dart ≥ 3.3
- 第一次拉下来后，平台目录已经齐全（android / ios / windows / macos / linux / web 都在仓库里），不用再 `flutter create .`

```bash
# 1. 安装依赖
flutter pub get

# 2. 生成 Hive 适配器（*.g.dart）
dart run build_runner build --delete-conflicting-outputs

# 3. 选一个目标平台跑起来
flutter run                        # 自动选第一个可用设备
flutter run -d chrome              # Web
flutter run -d windows             # Windows 桌面
flutter run -d <android-device-id> # 真机或模拟器，id 从 flutter devices 拿
```

### 各平台说明

**Android**：USB 连真机并打开"USB 调试"，或在 Android Studio 里建一个 API 34+ 模拟器。中文语音识别走 Google SpeechRecognizer，质量好。

**iOS**：必须有 Mac + Xcode 才能打包安装。Apple Speech Framework 中文识别质量接近 Chrome。Windows 上没法做 iOS 构建。

**Windows / macOS / Linux 桌面**：直接 `flutter run -d <平台>` 即可。**注意**：Windows 的 SAPI 中文识别质量较差，建议在桌面端跑时只用文字输入，把语音留给手机端。

**Web**：`flutter run -d chrome` 即可。**已知限制**：浏览器 CORS 策略会拦截绝大多数 LLM 厂商的 API 直连，所以 Web 端的语音记账 / AI 抽取无法工作 —— App 内已给出明确提示。其余功能（CSV 导出、记账、统计）一切正常。

## 语音记账配置

进入 **设置 → AI 语音记账** 填三个字段：

| 字段 | 说明 |
|---|---|
| Base URL | 默认 `https://api.openai.com/v1`，可改为任何 OpenAI 兼容接口（Azure、DeepSeek、混元、自建代理等） |
| API Key | 仅保存在 flutter_secure_storage，导出 CSV / 备份时不会泄漏 |
| 模型名 | 推荐 `gpt-4o-mini`，单次抽取成本 ≈ ¥0.001 |

打开"启用语音记账"开关后，**记一笔**页面右上角会出现麦克风按钮：点开 → 说一句"昨天午饭花了 35 元，微信支付" → 抬手 → 模型把 6 个字段抽出来预填表单，用户确认后保存。即使模型抽取失败，原始转写文本也会塞到备注里，话不会白说。

## 数据模型

详见 [`lib/models/`](lib/models)。三张表：

- **Expense**：单笔收支，amount 正为收入、负为支出，绑定 categoryId / 日期 / 支付方式 / 备注
- **Category**：类别，自带图标 codePoint 和颜色，区分 `expense` / `income`
- **Budget**：按月预算，categoryId 为 `__total__` 时表示总预算

字段定义对齐《数据相关要求.txt》。

## 数据导出

**历史**页右上角 → 导出 CSV：

- 桌面端：保存到 `~/Documents/` 或系统 Documents 目录
- Android：保存到 App 私有目录
- Web：触发浏览器下载

文件含 UTF-8 BOM，Excel / WPS 直接打开中文不乱码；逗号、引号、换行按 RFC 4180 转义。

## 开发提示

- **改了 Hive 模型？** 跑 `dart run build_runner build --delete-conflicting-outputs` 重新生成 `*.g.dart`
- **类型检查 + 静态分析**：`flutter analyze`
- **单元 / Widget 测试**：`flutter test`
- **清干净重来**：`flutter clean && flutter pub get`

## 路线图（Roadmap）

- [ ] 桌面端走 Whisper API 替代系统 STT，解决 Windows 中文识别质量问题
- [ ] 数据备份 / 恢复（加密导出整个 Hive 库）
- [ ] 多账本 / 多币种
- [ ] 周期性账单（订阅、月付）

## 许可

仅用于课程实训，未做商业授权。
