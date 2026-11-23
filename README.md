# 战争雷霆离线版 · 自定义 AI 对局修复补丁

针对 **War Thunder Offline（WOP 0.9.0 / 客户端 2.59.0.92）** 的自定义 AI 对局逻辑修复补丁。
不含游戏本体，必须先装好离线版本体。

**下载最新补丁**：见 [Releases](https://github.com/dellzou/warthunder-offline-patch/releases/latest)

---

## 修复清单

| # | 问题 | 现象 | 修复方式 |
|---|---|---|---|
| 1 | 空战出生点挤成一堆 | 开局几十架飞机生成在同一点，互相撞毁 | 出生点按 4 列 × 阶梯高度编队展开 |
| 2 | 海战船叠在一起 | 玩家与 AI 出生同点、舰体互穿 | 改用地图原版水面站位，按舰种分池、最远优先挑选 |
| 3 | 海战出生在岸上/图外 | 部分地图出生点被抓成空中点（y=1000~1500），船从空中摔下 | 重新从地图数据提取水面站位（96 张地图） |
| 4 | 对局几分钟被判负 | 开局约 4 分钟弹"对方玩家载具已经耗尽"，票数成块掉 | 关闭原生 CTA 的空队 / 无存活玩家惩罚系数 |
| 5 | 空战杀光对面不结束 | 敌方 AI 全灭后对局空转 | 按"该队活体数"判定，全灭后 20 秒结算 |
| 6 | 街机陆战 AI 起防空车 | 街机无飞机，AI 仍编入防空车且杵在出生点 | 街机 AI 池排除 `exp_SPAA`（历史模式保留） |
| 7 | 街机 AI 无限复活 | 陆战/海战街机 AI 可一直重生 | 恢复模式定义的 3 条命（空战街机保持无限） |
| 8 | 陆战 AI 卡墙/穿楼/上房 | 开进建筑被物理弹出（瞬移）、贴墙抽搐 | 走廊检测加密 + 撞墙节流 + 短距脱困 + 启用原生高级避碰 |
| 9 | 陆战开局不出门/原地转圈 | 开局几十秒 AI 挤在出生点打转 | 出生后 60 秒"出站宽限"，只走 navmesh 往战区开 |
| 10 | 选海战进了空战 | 模式跟随上次保存，忽略当前选中载具 | 出击模式按载具兵种决定 |

## 安装

1. 从 Releases 下载 `WarThunderOffline-Patch-v1.0.0.zip` 并解压到任意目录；
2. 以**管理员身份**运行 PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\INSTALL.ps1 -GamePath "D:\GameApp\WarThunderOffline"
```

脚本会先校验补丁包、备份将被覆盖的文件，再复制并逐个校验 SHA-256。不修改 `Save\` 存档。

手动安装也行：把 `files\` 下的 7 个文件按原目录结构覆盖到游戏根目录，**必须 7 个一起换**，
否则 `data\client-build.json` 的资源哈希对不上，启动自检会失败。

## 回滚

```powershell
powershell -ExecutionPolicy Bypass -File .\UNINSTALL.ps1 -GamePath "D:\GameApp\WarThunderOffline"
```

从最近一次安装生成的 `patch-backup-<时间戳>\` 还原。

## 校验

```powershell
Get-FileHash <游戏目录>\client\gui.vromfs.bin -Algorithm SHA256
```

期望值见 `SHA256SUMS.txt`。

## 已知未解决

- 击毁敌舰提示有时写成"击毁敌方飞机"（原生 HUD 兵种动词取自 `unitType`）；
- 部分地图顶部红蓝票条不显示；
- 极窄地形（巷战、桥洞）AI 可能判定过不去而停下，属原生避碰取舍；
- 陆战 AI 仍无法 100% 像真人绕障，彻底解决需改地图 navmesh（机制层面）。

## 版本

- 补丁 1.0.0（2026-11-23）· 客户端 2.59.0.92
