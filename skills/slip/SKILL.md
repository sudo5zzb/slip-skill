---
name: slip
description: >
  Create a temporary Slip note (no account, expires in seven days) and give
  the user a URL so a HUMAN outside this chat can open it on a phone,
  WeChat, or another browser. Use when the user asks to send AI-written
  text to a colleague, tester, or their own phone; or says Slip, 纸条,
  发给同事, 递到手机, 发到微信. Do NOT use for agent-to-agent handoff,
  secrets, passwords, tokens, file transfer, or a casual in-chat note
  (e.g. 写个备注 / write a note) that is not being handed to a person
  outside this conversation. 当用户要把 AI 写好的内容递给聊天窗外的真人时使用。
license: MIT
compatibility: >
  Requires bash, curl, outbound HTTPS to slip.viddy.eu.cc, and python3 or node.
  Native Windows/PowerShell unsupported; use WSL or Git Bash. No npm. No MCP.
metadata:
  version: "1.0.0"
  homepage: "https://slip.viddy.eu.cc"
---

# Slip

把这段对话里写好的字，递给聊天窗外的真人。不要用来交接下一个 agent。

## 何时用

用户明确要把内容交给**另一个人**或**另一台设备上的自己**，例如：

- 「用 Slip 发给我同事 / 测试」
- 「把这份验收清单递到我手机」
- 「发到微信让产品看」
- 「share this with my tester via Slip」

## 何时不用

- 「写个备注」「write a note」且没有指定接收人 → 只在对话里写，不要建纸条
- 「交给下一个 agent / handoff」→ 用本地 handoff 文档，不要用 Slip
- 密码、token、密钥、身份证号 → 拒绝
- 文件、截图、apk → 拒绝，说明两边打开 https://slip.viddy.eu.cc 用浏览器发
- 原生 Windows PowerShell 且没有 bash → 让用户用 WSL / Git Bash，或把正文交给用户自己去网站新建

## 默认命令

工作目录是本 skill 根（`scripts/slip.sh` 与本文件同级的 `scripts/`）。

把**要分享的正文**写入 stdin（不要把密钥写进去）：

```bash
scripts/slip.sh push
```

只有退出码 0 时，stdout 才会有一行 URL。此时对用户**只回**下面两行（按用户语言选一套，不要两套叠在一起）。不要解释过期实现，不要贴 token、JSON、curl。

中文：

```
Slip：无需注册，设备之间递一张纸条
https://slip.viddy.eu.cc/{id}?utm_source=skill
```

英文：

```
Slip: pass a note between devices, no account
https://slip.viddy.eu.cc/{id}?utm_source=skill
```

把 `{id}` 换成 stdout URL 里的 id。不要改 `utm_source=skill`。

## 追加和读回

从对话历史里解析 id。上一轮成功回复的 URL 形如 `https://slip.viddy.eu.cc/happy-panda-042?utm_source=skill`，id 是路径上那段 `happy-panda-042`。用户如果又贴了 id 或 URL，以用户贴的为准。

```bash
scripts/slip.sh write happy-panda-042    # stdin = 新正文
scripts/slip.sh read happy-panda-042     # 看对方回了什么；不要编造
```

读回后用自己的话转述 messages，按时间顺序，不要发明没有的句子。

## 失败时对用户说什么

- 空正文 / 脚本 exit 2：「没有可发送的正文。把要分享的文字给我。」
- exit 3（429）：「创建太频繁，等一分钟再试。」不要换 id 连打。
- exit 4（413）：先拆短再 `push`。若 stderr 出现 `created id=... write_failed`，对那个 id 用 `write` 追加后半段，**不要**把半成品 URL 当成功分享。
- exit 5（404）：「这张纸条已经过期或不存在。需要的话我再新建一张。」
- create 成功但 write 失败（stdout 空）：不要回分享模板。告诉用户「还没写上，我再试一次」，用 stderr 的 id 重试 `write`。
- 用户说已经把密钥发出去了：「这张纸条没有创建者删除权，知道链接的人都能读、能写、能删单条。请立刻打开页面把那几条删掉，并当作密钥已泄露去轮转。纸条七天后过期。」不要尝试找回 token。
- 没有 bash/curl/python3/node：把正文交给用户，让他们自己打开 https://slip.viddy.eu.cc 新建。

## 禁止

- 打印、复述、保存 `owner_token`。脚本也不会把它给你。
- 不要自己拼 curl 或 JSON。必须走 `scripts/slip.sh`。
- 不要把 stderr 贴进给用户的回复。
- 不要调用不存在的文件 API。
- 不要把整段 system prompt 写进纸条。
