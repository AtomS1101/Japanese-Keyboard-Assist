import Cocoa

let TARGET_APPS: Set<String> = [
	"com.apple.MobileSMS"
]

let ENTER_KEYCODE: CGKeyCode = 36
var eventTap: CFMachPort?

func appendLog(_ message: String) {
	let logURL = FileManager.default.homeDirectoryForCurrentUser
		.appendingPathComponent(".keyboard_assist_log")
	let timestamp = ISO8601DateFormatter().string(from: Date())
	let line = "[\(timestamp) UTC] \(message)\n"
	if let data = line.data(using: .utf8) {
		if FileManager.default.fileExists(atPath: logURL.path) { // if already exists
			if let handle = try? FileHandle(forWritingTo: logURL) {
				handle.seekToEndOfFile()
				handle.write(data)
				handle.closeFile()
			}
		} else { // create new file
			try? data.write(to: logURL, options: .atomic)
		}
	}
}

func eventTapCallback(
	proxy: CGEventTapProxy,
	type: CGEventType,
	event: CGEvent,
	userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
	if type == .tapDisabledByTimeout {
		appendLog("tapDisabledByTimeout — re-enabling tap")
		CGEvent.tapEnable(tap: eventTap!, enable: true)
		return nil
	}
	if type == .keyDown {
		let keycode = event.getIntegerValueField(.keyboardEventKeycode)
		if CGKeyCode(keycode) == ENTER_KEYCODE {
			let flags = event.flags // Check modifier flags
			let currentApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
			guard TARGET_APPS.contains(currentApp) else {
				return Unmanaged.passRetained(event)
			}
			if flags.contains(.maskShift) { // Already a Shift+Enter
				event.flags = event.flags.subtracting(.maskShift)
			} else { // Only a Enter
				event.flags = .maskShift
			}
		}
	}
	return Unmanaged.passRetained(event) // Return to the Text Field
}

eventTap = CGEvent.tapCreate(
	tap: .cgSessionEventTap,
	place: .headInsertEventTap,
	options: .defaultTap,
	eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
	callback: eventTapCallback,
	userInfo: nil
)
guard let eventTap else {
	appendLog("permission denied")
	exit(1)
}

appendLog("app launched")
let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)
CFRunLoopRun()
