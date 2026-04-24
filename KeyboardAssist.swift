import Cocoa

let TARGET_APPS: Set<String> = [
    "com.apple.MobileSMS"
]

let ENTER_KEYCODE: Int64 = 36

func eventTapCallback(
	proxy: CGEventTapProxy,
	type: CGEventType,
	event: CGEvent,
	userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
	if type == .keyDown {
		let keycode = event.getIntegerValueField(.keyboardEventKeycode)

		if keycode == ENTER_KEYCODE {
			let flags = event.flags // Check modifier flags
			let currentApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
         guard TARGET_APPS.contains(currentApp) else {
				return Unmanaged.passRetained(event)
         }
			let source = CGEventSource(stateID: .hidSystemState)
			if flags.contains(.maskShift) { // Already a Shift+Enter
				let shiftUp = CGEvent(keyboardEventSource: source, virtualKey: 56, keyDown: false)
				shiftUp?.flags = [] // No modifier
				event.flags = event.flags.subtracting(.maskShift)
			} else { // Only a Enter
				let shiftDown = CGEvent(keyboardEventSource: source, virtualKey: 56, keyDown: true)
				shiftDown?.flags = .maskShift
				event.flags = .maskShift
			}
		}
	}
	return Unmanaged.passRetained(event) // Return to the Text Field
}

guard let eventTap = CGEvent.tapCreate(
	tap: .cgSessionEventTap,
	place: .headInsertEventTap,
	options: .defaultTap,
	eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
	callback: eventTapCallback,
	userInfo: nil
) else {
	print("Failed — grant Accessibility permission first")
	exit(1)
}

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

CFRunLoopRun()
