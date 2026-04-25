# Japanese Keyboard Assist

This script fixes the issue where IME conversion (Enter key) triggers a message send on macOS.

## Requirements

- Swift
- Accessibility permission

## Usage

1. Compile the script

```bash
swiftc KeyboardAssist.swift
```


2. grant execution permissions:

```bash
chmod +x KeyboardAssist
```


3. Create `KeyboardAssist.app` and move it to the specified directory.

```tree
KeyboardAssist.app
└── Contents
    ├── Info.plist
    └── MacOS
        └── KeyboardAssist ← HERE
```


4. Make sure the following keys are included in your `Info.plist` file.

```xml
<key>LSUIElement</key>
<true/>

<key>LSBackgroundOnly</key>
<true/>
```


5. Grant accessibility permissions and enable `login items` from Settings.


## Supported Apps

supported apps are efined in `~/.config/KeyboardAssist/target_apps.txt`.

Add any bundle identifier to extend support.

```txt
com.apple.MobileSMS
```

## Logging

Events are logged to `~/.config/KeyboardAssist/keyboard_assist.log`.

```log
[2026-04-25T10:23:11Z UTC] app launched
[2026-04-25T10:45:03Z UTC] tapDisabledByTimeout — re-enabling tap
```

## License

MIT
