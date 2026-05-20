# mobile_app

一款基于 Flutter 的个人记账 App，本地优先存储，注重交互流畅与数据可视化。

## 技术栈

- **框架**：Flutter (Material 3)
- **状态管理**：flutter_riverpod
- **本地存储**：Hive (`hive`, `hive_flutter`)
- **路由**：go_router
- **图表**：fl_chart
- **代码生成**：build_runner + freezed + hive_generator

## 目录结构

```
lib/
├── main.dart
├── app/                # 应用入口与全局配置
│   ├── app.dart
│   └── theme.dart
├── models/             # 数据模型（Hive 注解）
│   ├── expense.dart
│   ├── category.dart
│   └── budget.dart
├── providers/          # Riverpod providers
├── services/           # 数据服务层（Hive、文件、备份等）
├── screens/            # 页面
├── widgets/            # 通用组件
└── utils/              # 工具：常量、格式化、校验
```

## 起步

> 仓库已包含 lib 目录与 `pubspec.yaml`，但 **Android / iOS / Web 等平台目录尚未生成**，
> 需要先安装 Flutter SDK 并执行 `flutter create .` 让 Flutter 补齐这些目录。

```bash
# 1. 安装依赖
flutter pub get

# 2. 生成平台目录（首次需要）
flutter create .

# 3. 生成 Hive / Riverpod 适配器代码（*.g.dart）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行
flutter run
```

## 数据模型

详见 [`lib/models/`](lib/models)。核心三张表：

- **Expense**：单笔收支记录（amount 正为收入、负为支出）
- **Category**：类别（图标、颜色、收入/支出类型）
- **Budget**：按月预算（绑定 categoryId）

字段定义对齐《数据相关要求.txt》。
