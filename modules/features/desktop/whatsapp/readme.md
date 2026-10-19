# whatsapp

- Never test the guard against the live WhatsApp: it kills the app. Point `appPath` at a throwaway `.app` with shimmed `pmset` and `ioreg`.
- A video call without a coreaudiod audio session looks idle and can be quit.
