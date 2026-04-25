import Cocoa

let ENTER_KEYCODE: CGKeyCode = 36
var eventTap: CFMachPort?
var TARGET_APPS = loadTargetApps()

func loadTargetApps() -> Set<String> {
	let configDir = FileManager.default.homeDirectoryForCurrentUser
		.appendingPathComponent(".config/KeyboardAssist")
	let configURL = configDir.appendingPathComponent("target_apps.txt")
	if let content = try? String(contentsOf: configURL, encoding: .utf8) {
		let apps = Set(content
			.components(separatedBy: .newlines)
			.map { $0.trimmingCharacters(in: .whitespaces) }
			.filter { !$0.isEmpty && !$0.hasPrefix("#") })
		return apps
	}
	let defaultContent = """
	# KeyboardAssist target apps
	# Add one bundle ID per line
	com.apple.MobileSMS
	"""

	do {
		try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
		try defaultContent.write(to: configURL, atomically: true, encoding: .utf8)
		appendLog("config file created at \(configURL.path)")
	} catch {
		appendLog("failed to create config file: \(error)")
	}
	return ["com.apple.MobileSMS"]
}

func appendLog(_ message: String) {
	let logURL = FileManager.default.homeDirectoryForCurrentUser
		.appendingPathComponent(".config/KeyboardAssist/keyboard_assist.log")
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
			appendLog("log file created")
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
