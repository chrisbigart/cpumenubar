import Cocoa

class StatusMenuController: NSObject, PreferencesWindowDelegate, NSMenuDelegate {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var resourceView: ResourceUsageView!
	@IBOutlet weak var openActivityMonitorMenuItem: NSMenuItem!
	@IBOutlet weak var aboutWindow: NSWindow!
	
    var usageInfoMenuItem: NSMenuItem!
    var preferencesWindow: PreferencesWindow!
	var menubarMenuIsOpen: Bool = false
	var timer = Timer()

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override func awakeFromNib() {
		preferencesWindow = PreferencesWindow()
		preferencesWindow.delegate = self
		
		updateUsage()
		updateStatusIcon()
		
		preferencesWindow.loadDefaults()
		resourceView.getHardwareInfo()
		
		statusMenu.delegate = self
    }
	
	func menuWillOpen(_ menu: NSMenu) {
		menubarMenuIsOpen = true
	}
	
	func menuDidClose(_ menu: NSMenu) {
		menubarMenuIsOpen = false
	}
	
	func getCpuLoad() -> Int {
		let combinedSysUsage = CPU.systemUsage();
		let sysUsage = combinedSysUsage.system + combinedSysUsage.user;
		var totalUsage = sysUsage;
		if(totalUsage.isNaN) {
			totalUsage = 0
		}
		if(totalUsage > 100) {
			totalUsage = 100
		}
		
		resourceView.cpuUsageHistory[resourceView.cpuUsageOffset] = Float(totalUsage)
		resourceView.cpuUsageOffset = (resourceView.cpuUsageOffset + 1) % ResourceUsageView.cpuUsageHistorySamples
		
		let iconUsage = Int((totalUsage / 100) * 18)
		
		return iconUsage
	}
	
	@objc func updateStatusIcon() {
		let outlineStatusIcon = preferencesWindow?.showStatusOutline
		let cpuLoad = getCpuLoad()
		statusItem.menu = statusMenu
		let icon = NSImage(named: NSImage.Name(rawValue: String(cpuLoad) + ((outlineStatusIcon == true) ? "a" : "")))
		icon?.isTemplate = true // best for dark mode
		statusItem.image = icon
		statusItem.menu = statusMenu
		usageInfoMenuItem = statusMenu.item(withTitle: "Usage")
		usageInfoMenuItem.view = resourceView
		
		if(menubarMenuIsOpen) {
			resourceView.update()
		}
	}
    
    func updateUsage() {
		let seconds = (Double(ResourceUsageView.cpuUsageHistorySamples) * preferencesWindow.updateFrequency)
		
		resourceView.cpuUsageHistoryUpdateFrequencyLabel.stringValue =
			String(format: "Previous %d samples (%.0f seconds)",
				   ResourceUsageView.cpuUsageHistorySamples, seconds)
		
		timer.invalidate()
		timer = Timer.scheduledTimer(timeInterval: preferencesWindow.updateFrequency, target: self, selector: #selector(self.updateStatusIcon), userInfo: nil, repeats: true)

		RunLoop.main.add(timer, forMode: .commonModes)
		
		self.resourceView.update()
    }
	
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
		if((preferencesWindow.window?.isVisible)!) {
			preferencesWindow.close()
			preferencesWindow.windowDidLoad()
		}
		else {
			preferencesWindow.showWindow(nil)
		}
    }
	
	@IBAction func openActivityMonitorClicked(_ sender: Any) {
		NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Utilities/Activity Monitor.app"))
	}
	
	@IBAction func aboutClicked(_ sender: Any) {
		if(!aboutWindow.isVisible) {
			aboutWindow.close()
		}
		aboutWindow.makeKeyAndOrderFront(self)
	}
	
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    func preferencesDidUpdate() {
        updateUsage()
		updateStatusIcon()
    }
}
