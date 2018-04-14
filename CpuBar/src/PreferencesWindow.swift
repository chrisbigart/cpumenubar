import Cocoa

protocol PreferencesWindowDelegate {
    func preferencesDidUpdate()
}

extension UserDefaults {
	func set(_ color: NSColor, forKey key: String) {
		set(NSKeyedArchiver.archivedData(withRootObject: color), forKey: key)
	}
	func color(forKey key: String) -> NSColor? {
		guard let data = data(forKey: key) else { return nil }
		return NSKeyedUnarchiver.unarchiveObject(with: data) as? NSColor
	}
}

class PreferencesWindow: NSWindowController, NSWindowDelegate {
    var delegate: PreferencesWindowDelegate?
	@IBOutlet weak var showStatusOutlineCheckbox: NSButton!
	//@IBOutlet weak var toggleDarkThemeCheckbox: NSButton!
	@IBOutlet weak var updateFrequencySlider: NSSlider!
	@IBOutlet weak var updateFrequencyLabel: NSTextField!
	
	var showStatusOutline: Bool = UserDefaults.standard.bool(forKey: "showStatusOutline")
	var updateFrequency: Double = UserDefaults.standard.double(forKey: "updateFrequency")

	@IBOutlet weak var cpuUsageColorWell: NSColorWell!
	@IBOutlet weak var activeMemoryColorWell: NSColorWell!
	@IBOutlet weak var wiredMemoryColorWell: NSColorWell!
	@IBOutlet weak var compressedMemoryColorWell: NSColorWell!
	
	static var cpuUsageColor: NSColor = NSColor.systemOrange
	static var activeMemoryColor: NSColor = NSColor.systemBlue
	static var compressedMemoryColor: NSColor = NSColor.systemYellow
	static var wiredMemoryColor: NSColor = NSColor.systemGreen
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		self.window?.center()
		self.window?.makeKeyAndOrderFront(nil)
		NSApp.activate(ignoringOtherApps: true)
		
		loadDefaults()
	}
	
//	func getSavedColor(color: String) -> NSColor {
//		let colorData = (UserDefaults.standard.object(forKey: "cpuUsageColor") as? NSData
//		let colorValue = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? NSColor
//
//		return colorValue
//	}
	
	func loadDefaults() {
		updateFrequency = UserDefaults.standard.double(forKey: "updateFrequency")
		showStatusOutline = UserDefaults.standard.bool(forKey: "showStatusOutline")
		if(showStatusOutline) {
			showStatusOutlineCheckbox?.state = NSControl.StateValue.on
		}
		else {
			showStatusOutlineCheckbox?.state = NSControl.StateValue.off
		}
		
		updateFrequencySlider?.doubleValue = updateFrequency
		frequencySliderChanged(self)
		
		PreferencesWindow.cpuUsageColor = UserDefaults.standard.color(forKey: "cpuUsageColor")!
		PreferencesWindow.activeMemoryColor = UserDefaults.standard.color(forKey: "activeMemoryColor")!
		PreferencesWindow.compressedMemoryColor = UserDefaults.standard.color(forKey: "compressedMemoryColor")!
		PreferencesWindow.wiredMemoryColor = UserDefaults.standard.color(forKey: "wiredMemoryColor")!
		
		cpuUsageColorWell?.color = PreferencesWindow.cpuUsageColor
		activeMemoryColorWell?.color = PreferencesWindow.activeMemoryColor
		wiredMemoryColorWell?.color = PreferencesWindow.compressedMemoryColor
		compressedMemoryColorWell?.color = PreferencesWindow.wiredMemoryColor
		
//		if(isDarkThemeOn()) {
//			toggleDarkThemeCheckbox.state = NSControl.StateValue.on
//		}
//		else {
//			toggleDarkThemeCheckbox.state = NSControl.StateValue.off
//		}
	}
	
    override var windowNibName : NSNib.Name? {
		return NSNib.Name(rawValue: "PreferencesWindow")
    }
	
	@IBAction func frequencySliderChanged(_ sender: Any) {
		updateFrequency = updateFrequencySlider?.doubleValue ?? 1.0
		updateFrequencyLabel?.stringValue = String(format: "%.2f seconds", updateFrequency)
		
		UserDefaults.standard.set(updateFrequency, forKey: "updateFrequency")
		
		delegate?.preferencesDidUpdate()
	}
	
	@IBAction func showOutlineCheckboxChecked(_ sender: Any) {
		showStatusOutline = (showStatusOutlineCheckbox.state == NSControl.StateValue.on)
		
		UserDefaults.standard.set(showStatusOutline, forKey: "showStatusOutline")
		
		delegate?.preferencesDidUpdate()
	}
	
//	@IBAction func toggleDarkTheme(_ sender: Any) {
//		var error: NSDictionary?
//		let script = NSAppleScript(source: "tell application \"System Events\"\ntell appearance preferences to set dark mode to not dark mode\nend tell")
//
//		script?.executeAndReturnError(&error)
//	}
//
//	func isDarkThemeOn() -> Bool {
//		var error: NSDictionary?
//
//		let script = NSAppleScript(source: "tell application \"System Events\"\ntell appearance preferences\nif dark mode is false then\nreturn \"light\"\nelse\nreturn \"dark\"\nend if\nend tell\nend tell")
//
//		let result = script?.executeAndReturnError(&error)
//		if(result?.stringValue == "dark") {
//			return true
//		}
//		else {
//			return false
//		}
//	}
//
	@IBAction func updateColors(_ sender: Any) {
		PreferencesWindow.cpuUsageColor = cpuUsageColorWell?.color ?? NSColor.systemOrange
		PreferencesWindow.activeMemoryColor = activeMemoryColorWell?.color ?? NSColor.systemBlue
		PreferencesWindow.compressedMemoryColor = compressedMemoryColorWell?.color ?? NSColor.systemYellow
		PreferencesWindow.wiredMemoryColor = wiredMemoryColorWell?.color ?? NSColor.systemGreen
		
		UserDefaults.standard.set(PreferencesWindow.cpuUsageColor, forKey: "cpuUsageColor")
		UserDefaults.standard.set(PreferencesWindow.activeMemoryColor, forKey: "activeMemoryColor")
		UserDefaults.standard.set(PreferencesWindow.compressedMemoryColor, forKey: "compressedMemoryColor")
		UserDefaults.standard.set(PreferencesWindow.wiredMemoryColor, forKey: "wiredMemoryColor")
	}
	
	
	func windowWillClose(_ notification: Notification) {
        delegate?.preferencesDidUpdate()
    }
}
