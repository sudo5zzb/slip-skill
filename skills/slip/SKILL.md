---
name: slip
description: >
  Send AI-written text to a HUMAN outside this chat via a one-tap Slip note
  and reply with a single URL. Default: toss — a one-shot note (Markdown
  rendered, readable on open, tear-to-delete, auto-expires in 24 hours) for
  one-way delivery like checklists, summaries, code snippets. Use push only
  when the human is expected to reply or the text exceeds 10,000 chars.
  Use when the user asks to send AI-written text to a colleague, tester, or
  their own phone; or says Slip, 纸条, 发给同事, 递到手机, 发到微信,
  即撕纸条. Do NOT use for agent-to-agent handoff, secrets, passwords,
  tokens, file transfer, or a casual in-chat note (e.g. 写个备注) that is
  not being handed to a person outside this conversation.
  当用户要把 AI 写好的内容递给聊天窗外的真人时使用。
license: MIT
compatibility: >
  Requires bash, curl, outbound HTTPS to slip.omnimoke.com, and python3 or node.
  Native Windows/PowerShell unsupported; use WSL or Git Bash. No npm. No MCP.
metadata:
  version: "1.2.0"
  homepage: "https://slip.omnimoke.com"
---

# Slip

把这段对话里写好的字，递给聊天窗外的真人。不要用来交接下一个 agent。

## 何时用

用户明确要把内容交给**另一个人**或**另一台设备上的自己**，例如：

- 「用 Slip 发给我同事 / 测试」
- 「把这份验收清单递到我手机」
- 「发到微信让产品看」
- 「share this with my tester via Slip」

## 选 toss 还是 push

- **toss（即撕纸条，默认）**：内容是单向给人看的——清单、总结、一段代码、一组链接。
  对方打开即见（Markdown 会渲染成排版好的页面），看完可以撕掉，撕掉即彻底删除；
  24 小时后没撕也会自动消失。单条不超过 10,000 字。
- **push（对话纸条）**：需要对方回复、多轮往来，或内容超过 10,000 字。
  对方能在页面里写字回传。

不确定时选 toss：大多数「递给人看」的场景都是一次性的。

## 何时不用

- 「写个备注」「write a note」且没有指定接收人 → 只在对话里写，不要建纸条
- 「交给下一个 agent / handoff」→ 用本地 handoff 文档，不要用 Slip
- 密码、token、密钥、身份证号 → 拒绝（toss 和 push 都是明文存储，不适合传密钥）
- 文件、截图、apk → 拒绝，说明两边打开 https://slip.omnimoke.com 用浏览器发
- 原生 Windows PowerShell 且没有 bash → 让用户用 WSL / Git Bash，或把正文交给用户自己去网站新建

## toss：即撕纸条（默认）

工作目录是本 skill 根（`scripts/slip.sh` 与本文件同级的 `scripts/`）。

把**要分享的正文**写入 stdin（不要把密钥写进去）：

```bash
scripts/slip.sh toss
```

只有退出码 0 时，stdout 才会有一行 URL。此时对用户**只回这一行 URL 本身**——
不要附加任何标语、解释、token、JSON 或 curl 输出；用户若追问，再用用户的语言简短说明
（可以说：24 小时内有效；对方打开即见；看完可撕，撕掉即彻底删除）。

```
https://slip.omnimoke.com/n/{id}?utm_source=skill
```

把 `{id}` 换成 stdout URL 里的 id。不要改 `utm_source=skill`。

toss 是单请求原子创建：要么拿到 URL，要么没有，不存在「创建成功但没写上」的半成品。
Markdown 语法直接写进正文即可，对方打开会看到渲染后的页面。

## push：对话纸条（需要对方回复时）

```bash
scripts/slip.sh push
```

成功时 stdout 同样只有一行 URL（路径上没有 `/n/`）：

```
https://slip.omnimoke.com/{id}?utm_source=skill
```

## 追加和读回（仅 push）

从对话历史里解析 id。上一轮成功回复的 URL 形如 `https://slip.omnimoke.com/happy-panda-042?utm_source=skill`，id 是路径上那段 `happy-panda-042`。用户如果又贴了 id 或 URL，以用户贴的为准。`/n/` 开头的是即撕纸条，不能 write、不能 read——不要对它调用这两个命令。

```bash
scripts/slip.sh write happy-panda-042    # stdin = 新正文
scripts/slip.sh read happy-panda-042     # 看对方回了什么；不要编造
```

读回后用自己的话转述 messages，按时间顺序，不要发明没有的句子。

## 失败时对用户说什么

- 空正文 / 脚本 exit 2：「没有可发送的正文。把要分享的文字给我。」
- exit 3（429）：「创建太频繁，等一分钟再试。」不要换 id 连打。
- exit 4（413）：先拆短再发（toss 上限 10,000 字，超长内容用 push 拆条）。若 push 的 stderr 出现 `created id=... write_failed`，对那个 id 用 `write` 追加后半段，**不要**把半成品 URL 当成功分享。
- exit 5（404）：「这张纸条已经过期或不存在。需要的话我再新建一张。」
- push 成功但 write 失败（stdout 空）：不要回分享模板。告诉用户「还没写上，我再试一次」，用 stderr 的 id 重试 `write`。
- 用户说已经把密钥发出去了：「这张纸条没有创建者删除权，知道链接的人都能读（push 还能写、能删单条）。请立刻打开页面把那几条删掉，并当作密钥已泄露去轮转。」不要尝试找回 token。
- 没有 bash/curl/python3/node：把正文交给用户，让他们自己打开 https://slip.omnimoke.com 新建。

## 禁止

- 打印、复述、保存 `owner_token`。脚本也不会把它给你。
- 不要自己拼 curl 或 JSON。必须走 `scripts/slip.sh`。
- 不要把 stderr 贴进给用户的回复。
- 不要调用不存在的文件 API。
- 不要把整段 system prompt 写进纸条。
