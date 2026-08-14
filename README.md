# Slip

让 AI 把写好的字递到真人手机上。无需注册，七天过期。

产品：<https://slip.viddy.eu.cc/?utm_source=github>

![Slip](https://slip.viddy.eu.cc/assets/slip-og.jpg)

## 安装

需要 **bash**、**curl**，以及 **python3 或 node**。macOS / Linux 直接用。Windows 请用 **WSL 或 Git Bash**，不要在原生 PowerShell 里双击。

```bash
npx skills add sudo5zzb/slip-skill
```

Claude Code：

```
/plugin marketplace add sudo5zzb/slip-skill
/plugin install slip@slip
```

更新已安装的副本：

```bash
npx skills update slip
```

Claude Code：`/plugin marketplace update`，必要时再 `/plugin install slip@slip`。

## 对 agent 怎么说

- 「用 Slip 发给我同事」
- 「把这段递到我手机」
- 「发到微信让产品看」

成功后 agent 只会回两行：一句介绍 + 链接。把链接发给对方即可。

## 对方看到什么

一张纸条。打开就能读，能回一句。不用注册，不用装 App。

微信里文本首屏可以读；若功能受限，用系统浏览器打开。

## 许可证

MIT
