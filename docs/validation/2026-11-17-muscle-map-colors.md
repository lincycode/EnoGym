# 肌肉热力图语义配色

日期：2026-11-17（北京时间）

## 改动

- 统计页本周与 30 天肌肉图固定使用橙棕色阶，不再读取出勤颜色偏好；零训练量保留原中性色。人体、图例、点击详情、组数列表以及共享相同绘制逻辑的首页肌肉小组件保持一致。
- 恢复图、总体恢复环、图例、详情标记和状态分段统一使用连续绿色阶。恢复越充分，浅色主题颜色越深、深色主题颜色越亮；状态文字和百分比保留，状态标签正文使用主题文字色保证辨识。
- 「未练」维持原有近期训练偏绿、长期未练偏橙红的逻辑。出勤网格、训练量计算、恢复算法和数据格式不变。
- 中英文配色入口明确为「出勤图颜色」，说明肌肉图使用固定配色。其他语言既有翻译不改动，无新增翻译键。
- 提交前复核同步了训练时间线人体图的图例，使其与时间线人体图保持同一色阶。

## 已执行验证

- `gen-l10n` 完成；既有俄语、乌克兰语 ICU 警告与其他语言待翻译提示仍存在。
- `flutter analyze --no-pub --no-fatal-infos`：No issues found。
- 因标准 Flutter 测试需要监听本机端口，当前沙箱阻止其启动。使用本地 Flutter 引擎、关闭 VM service，经文件方式编译和运行现有测试，无网络传输：`muscle_map_test` 6 项、`readiness_test` 4 项、`activity_map_test` 10 项、`body_hit_test` 1 项、`home_widgets_test` 5 项、`light_palette_test` 1 项、`i18n_test` 31 项，共 58 项通过。既有测试使用标准测试字体参数；未新增产品测试或变更测试断言。
- Flutter debug bundle 编译通过。此结果只确认 Dart 与 Flutter 资源编译，不等于 APK 构建通过。
- 用真实 `ProgressScreen` 和合成训练记录渲染鼠尾草白、原版暖米灰、深色、AMOLED 四套主题，共 32 张截图；检查本周、30 天、恢复详情、未练、展开组数列表和配色浮层。截图启用本机字体回退，不代替 Android 真机字体与交互验收。
- 四套主题下将出勤色从蓝切换为绿，本周肌肉卡片截图均逐字节一致，验证配色已解耦。
- 完整源码 diff 已审查，`git diff --check` 通过。

本地执行入口、日志和截图位于 `artifacts/qa/2026-11-17-muscle-colors/`，不进入 Git。`offline_runner.dart` 仅为本次受限环境的验证入口，直接运行既有测试及本地截图脚本，不修改 Flutter 工具链。

## 限制

- `bash scripts/build-own.sh debug --no-pub` 在 Gradle 初始化阶段因 `java.net.SocketException: Operation not permitted` 失败，尚未执行 Android 编译；本轮没有生成新 APK。
- 显式暂存本轮文件时，Git 无法创建 `.git/index.lock`（Operation not permitted）。改动保留在工作区，未暂存、未提交、未推送。暂存检查只能检查当前空暂存区，不算对本轮文件完成提交前验证。
- 未操作真实手机、未安装应用、未修改用户数据、未创建 Release。
