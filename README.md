# Japanese Keyboard Assist

This script fixes the issue where IME conversion (Enter key) triggers a message send on macOS.

## Requirements

- Swift
- Accessibility permission

## Usage

1. Run the script
```bash
swiftc KeyboardAssist.swift
```

2. Grant **Accessibility permission** to terminal when prompted
`System Settings → Privacy & Security → Accessibility`

## Supported Apps

Defined in `~/.config/KeyboardAssist/target_apps.txt`.

```txt
com.apple.MobileSMS
```

Add any bundle identifier to extend support (e.g. Slack: `"com.tinyspeck.slackmacgap"`).

## Logging

Events are logged to `~/.config/KeyboardAssist/keyboard_assist.log`.

```
[2026-04-25T10:23:11Z UTC] app launched
[2026-04-25T10:45:03Z UTC] tapDisabledByTimeout — re-enabling tap
```

## License

MIT
