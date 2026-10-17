# 引用来源与鸣谢

Hyps Hub 是一个独立开源项目，下列来源与项目构成了它的基础。感谢所有作者与维护者。

## 特别鸣谢

特别鸣谢 **[MoYingJi](https://github.com/MoYingJi)** —— 上游 [Hyps](https://github.com/MoYingJi/Hyps)
的作者。Hyps Hub 的 CLI 调用、初始化流程、配置格式与游戏启动逻辑都建立在该项目之上。

## 1. 上游项目

| 项目 | 用途 | 许可 |
| --- | --- | --- |
| [MoYingJi/Hyps](https://github.com/MoYingJi/Hyps) | Hyps CLI、初始化流程、游戏启动脚本、配置格式与运行逻辑 | GPL-3.0-only |
| [K-Blaaaack/Hyps](https://github.com/K-Blaaaack/Hyps) | 上游调研与本地开发参考（fork） | GPL-3.0-only |

Hyps Hub 不包含上游源码。运行时由本机独立克隆的 Hyps 组件提供 CLI；
本项目通过适配层调用它，并遵循 GPL-3.0-only 发布。

## 2. 设计规范与界面语言

项目内的 `docs/design/` 是实现与验收文档，不作为第三方来源列出。设计语言参考：

| 来源 | 用途 |
| --- | --- |
| [Brandon030722/ark-ui-skill](https://github.com/Brandon030722/ark-ui-skill) | 设计语言与生产站点实现证据参考 |
| [《明日方舟》UI/UX 分析](https://gameinstitute.qq.com/index.php/knowledge/100122)（腾讯游戏学院，作者 AJ） | 画内界面、双签名纹理、层级与过场分析 |
| [ignoredone.space 字体库](https://www.ignoredone.space/index.php/fontlab/) | 方舟设计圈字体选型参考 |
| [《「舟味」从何而来》PDF](https://janniewang.net/wp-content/uploads/2023/09/UIUX-analysis-for-Arknights.pdf) | 补充 UI/UX 分析 |

界面实现只采用**设计语言**（近黑墨底、单一青色信号、0 圆角、1px 细线、
45° 切角、索引与双纹理），不包含鹰角网络的商标、logo、立绘、图标表或字体文件。
字体仅使用系统本地回退，不随项目分发。

## 3. 框架、工具与运行时

| 项目 | 用途 | 许可 |
| --- | --- | --- |
| [Qt 6 / Qt Quick Controls 2](https://www.qt.io/) | GUI 框架、窗口系统抽象、QML 运行时 | LGPL-3.0 / GPL-3.0（动态链接） |
| [CMake](https://cmake.org/) / [Ninja](https://ninja-build.org/) | 构建系统 | BSD-3-Clause / Apache-2.0 |
| [GitHub Actions](https://github.com/features/actions) | CI、Arch 包构建与发布 | GitHub 服务条款 |
| [actions/checkout](https://github.com/actions/checkout)、[upload-artifact](https://github.com/actions/upload-artifact)、[download-artifact](https://github.com/actions/download-artifact)、[softprops/action-gh-release](https://github.com/softprops/action-gh-release) | 自动构建与发布流水线 | 各自仓库许可 |
| [Arch Linux](https://archlinux.org/) / `makepkg` | 首要打包目标 | 各自项目许可 |

系统字体建议（不随包分发）：Noto Sans CJK（SIL OFL 1.1）、DejaVu Sans（Bitstream Vera）、
JetBrains Maple Mono（SIL OFL 1.1）；实际使用以用户系统已安装字体为准。

## 4. 原创内容

以下内容为 Hyps Hub 原创，不含第三方专有资产：

- 应用 logo（`assets/hyps-hub.svg`）与导航图标（`qml/components/NavIcon.qml`）
- 噪点与 45° 警戒线纹理（`assets/noise.png`、`assets/stripe.png`）
- 界面布局、QML 组件、文案与文档
- 诊断包结构、适配层与测试夹具

## 5. 作者与致谢

- 作者 / 维护：[K-Black](https://github.com/K-Blaaaack)
- **特别鸣谢**：[MoYingJi](https://github.com/MoYingJi)，上游 Hyps 作者
- 感谢上游 Hyps 的所有贡献者
- 感谢上述设计语言参考、分析文章与字体资料的作者

## 6. 商标与免责声明

Hyps Hub 与鹰角网络（Hypergryph）、明日方舟（Arknights）无隶属、赞助或背书关系。
“明日方舟”“Arknights”等名称与相关商标归其权利人所有。本项目仅参考公开的设计语言与
UI/UX 分析，不包含也不分发其专有美术资产。

Hyps Hub 与上游 Hyps 项目为独立项目；上游作者不对本项目的功能、稳定性或发布内容负责。
