# Slip

Let AI pass a note to someone’s phone. No account. `toss` sends a one-tap note (Markdown rendered, tear-to-delete, auto-expires in 24 hours); `push` opens a two-way slip that expires after seven idle days.

让 AI 把写好的字递到真人手机上。无需注册。`toss` 递一张即撕纸条（Markdown 渲染、看完可撕、24 小时自动消失）；`push` 开一张可往来的对话纸条（七天无新消息才清掉）。

https://slip.omnimoke.com/?utm_source=github

![Slip](https://slip.omnimoke.com/assets/slip-og.jpg)

## Install

```bash
npx skills add sudo5zzb/slip-skill
```

```bash
npx skills update slip
```

The installer will ask which AI to add it to. Pick the ones you use, then confirm.

安装时会问装到哪些 AI。勾选你正在用的即可。

## How to use

1. Run the install command above.
2. Start a **new** chat. Old conversations may not load the skill.
3. After the AI writes something, say one of these:
   - `Send this to my teammate with Slip`
   - `Put this on my phone`
   - `用 Slip 发给我同事`
   - `把这段递到我手机`
4. It should reply with one URL. Send that URL.

One-way delivery (checklists, summaries, code) gets a one-tap note under `/n/…`; when a reply is expected it opens a two-way slip. Do not say “write a note” with no recipient — that stays in the chat.

1. 运行上面的安装命令。
2. **新开**一轮对话。旧对话不一定会加载 skill。
3. AI 写完后说「用 Slip 发给我同事」或「递到我手机」。
4. 成功时只回一行链接。把链接发出去。

单向给人看的内容（清单、总结、代码）会得到一张 `/n/…` 即撕纸条；需要对方回复时会开一张可往来的对话纸条。不要只说「写个备注」——那种不会建纸条。

## What they see

A slip of paper. One-tap notes (`/n/…`) open instantly with the content rendered — Markdown becomes a formatted page — and can be torn up after reading; torn means gone for good, and unopened notes disappear after 24 hours. Two-way slips can be read and replied to. No account, no app.

In WeChat, the first screen of text is readable. If something is limited, open it in the system browser.

对方打开就是一张纸条。即撕纸条（`/n/…`）打开即见，Markdown 渲染成排版好的页面；看完可以撕掉，撕掉即彻底删除，24 小时没撕也会自动消失。对话纸条能读能回。不用注册，不用 App。

微信里若功能受限，用系统浏览器打开。

## License

MIT
