# Slip

Let AI pass a note to someone’s phone. No account. Expires after seven idle days (cleared only when there are no new messages).

让 AI 把写好的字递到真人手机上。无需注册，七天过期（没有新消息才会清掉）。

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
4. It should reply with two lines: a short intro and a URL. Send that URL.

Do not say “write a note” with no recipient — that stays in the chat.

1. 运行上面的安装命令。
2. **新开**一轮对话。旧对话不一定会加载 skill。
3. AI 写完后说「用 Slip 发给我同事」或「递到我手机」。
4. 成功时只回两行：一句介绍 + 链接。把链接发出去。

不要只说「写个备注」——那种不会建纸条。

## What they see

A slip of paper. Open it, read it, reply. No account, no app.

In WeChat, the first screen of text is readable. If something is limited, open it in the system browser.

对方打开就是一张纸条，能读能回，不用注册。微信里若功能受限，用系统浏览器打开。

## License

MIT
