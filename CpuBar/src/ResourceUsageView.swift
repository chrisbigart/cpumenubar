import Foundation
import Cocoa

class ResourceUsageView : NSView {
	@IBOutlet weak var currentConditionsTextField: NSTextField!
	@IBOutlet weak var memoryUsageTextField: NSTextField!
	@IBOutlet weak var infoTextField: NSTextField!
	@IBOutlet weak var cpuUsageHistoryUpdateFrequencyLabel: NSTextField!
	
	var totalMem: CGFloat = 1.0
	var usedMem: CGFloat = 0.0
	
	static var cpuUsageHistorySamples = 25
	var cpuUsageHistory: Array<Float>
	var cpuUsageOffset: Int = 0
	
	required init?(coder decoder: NSCoder) {
		cpuUsageHistory = Array(repeating: -1, count: ResourceUsageView.cpuUsageHistorySamples)
		super.init(coder: decoder)
	}
	
    func update() {
        // do UI updates on the main thread
//		usedMem = CGFloat(usage.memUsage)
//		totalMem = CGFloat(usage.memTotal)
		
        DispatchQueue.main.async {
            //self.cityTextField.stringValue = usage.cpuUsage
            //self.currentConditionsTextField.stringValue = "\(Int(usage.memUsage))°F and \(usage.memTotal)"
            //self.imageView.image = NSImage(named: NSImage.Name(rawValue: usage.icon))
			
			//NSColor.windowBackgroundColor.setFill()
			//__NSRectFill(self.bounds)
			//self.invalidateIntrinsicContentSize()
			//self.setNeedsDisplay(NSMakeRect(0, 0, 1000, 1000))
			
			self.display()
			//self.draw(NSMakeRect(0, 0, 1000, 1000))
        }
    }
	
//
//	func vw_page_size() -> (kern_return_t, vm_size_t) {
//		var pageSize: vm_size_t = 0
//		let result = withUnsafeMutablePointer(to: &pageSize) { (size) -> kern_return_t in
//			host_page_size(mach_host_self(), size)
//		}
//
//		return (result, pageSize)
//	}
//
//	func vm_stat() -> (kern_return_t, vm_statistics) {
//		var vmstat = vm_statistics_data_t()
//		var count = UInt32(MemoryLayout<vm_statistics>.size / MemoryLayout<integer_t>.size)
//
//		let HOST_VM_INFO_COUNT = MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride
//		let size = mach_msg_type_number_t(HOST_VM_INFO_COUNT)
//
//		let result = withUnsafeMutablePointer(to: &vmstat) {
//			$0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
//				(stat) -> kern_return_t in
//			host_statistics(mach_host_self(), Int32(HOST_VM_INFO), $0, size)
//			}
//		}
//
//		return (result, vmstat)
//	}
	
//	func getTotalMemorySize() -> Float {
//		let (result1, pageSize) = vw_page_size()
//		let (result2, vmstat) = vm_stat()
//
//		guard result1 == KERN_SUCCESS else {
//		fatalError("Cannot get VM page size")
//		}
//		guard result2 == KERN_SUCCESS else {
//		fatalError("Cannot get VM stats")
//		}
//
//		let total = (UInt(vmstat.free_count + vmstat.active_count + vmstat.inactive_count + vmstat.speculative_count + vmstat.wire_count) * pageSize) >> 30
//		let free = (UInt(vmstat.free_count) * pageSize) >> 20
//
//		print("total: \(total)GB")
//		print("free : \(free)MB")
//		return Float(total)
//	}
//
	func getSysctl<T>(command: String) -> T {
		var size = 0
		sysctlbyname(command, nil, &size, nil, 0)
		if T.Type.self == Int.Type.self { //int type
			var result = 0
			sysctlbyname(command, &result, &size, nil, 0)
			return result as! T
		}
		else { //string type result
			var result = [CChar](repeating: 0,  count: size)
			sysctlbyname(command, &result, &size, nil, 0)
			return String(cString: result) as! T
		}
	}
	
	func getHardwareInfo() {
		let modelName = getSysctl(command: "hw.model") as String
		var cpuName = getSysctl(command: "machdep.cpu.brand_string") as String
		cpuName = cpuName.replacingOccurrences(of: "(R)", with: "")
		cpuName = cpuName.replacingOccurrences(of: "(TM)", with: "")
		cpuName = cpuName.replacingOccurrences(of: "CPU", with: "")
		cpuName = cpuName.replacingOccurrences(of: "  ", with: " ")
		
		let cpuInfo = String(format: "%d(%d)x %@",
							 getSysctl(command: "hw.physicalcpu") as Int,
							 ProcessInfo.processInfo.processorCount, //getSysctl(command: "hw.logicalcpu"),
			cpuName)
		var osVersion = ProcessInfo.processInfo.operatingSystemVersionString
		osVersion = osVersion.replacingOccurrences(of: "Version", with: "")
		osVersion = osVersion.trimmingCharacters(in: .whitespacesAndNewlines)
		
		let info = String(format: "%@\n%@\n%@\n%@",
						  //Host.current().localizedName ?? "",
			ProcessInfo.processInfo.hostName,
			modelName,
			osVersion,
			cpuInfo)
		
		infoTextField?.stringValue = info
	}
	
	override func draw(_ rect: CGRect) {
		let mem = System.memoryUsage()
		let totalUsedMem = CGFloat(mem.active + mem.compressed + mem.wired)
		let totalMem = ProcessInfo.processInfo.physicalMemory / (1024 * 1024) //CGFloat(mem.active + mem.compressed + mem.wired + mem.inactive)
		let memUsage = String(format: "%.0f MB / %d MB", totalUsedMem * 1024, totalMem)
		memoryUsageTextField?.stringValue = memUsage
		
		
		var xOff = CGFloat(14.0)
		var yOff = CGFloat(94.0)
		let chartWidth = CGFloat(256.0)
		let chartHeight = CGFloat(28.0)
		
		let colors: [NSColor] = [PreferencesWindow.activeMemoryColor, PreferencesWindow.compressedMemoryColor,
								 PreferencesWindow.wiredMemoryColor, NSColor.red]
		
		let memVals: [Double] = [mem.active, mem.compressed, mem.wired, mem.inactive]
		let legendXOffsets: [Double] = [36, 98, 198, 247]
		
		for i in 0...2 {
			let width = (CGFloat(memVals[i]) / CGFloat(totalMem / 1024)) * chartWidth;
			let barRect = NSMakeRect(xOff, yOff, width, CGFloat(chartHeight))
			xOff += width
			colors[i].setFill()
			__NSRectFill(barRect)
			//draw rect for legend labels
			let legendRect = NSMakeRect(CGFloat(legendXOffsets[i]), CGFloat(yOff - 16), 12, 12)
			__NSRectFill(legendRect)
		}
		
		//draw CPU usage line chart
		//NSColor.systemOrange.setStroke()
		PreferencesWindow.cpuUsageColor.setStroke()
		//NSColor.systemPurple.setFill()
		
		xOff = 13
		yOff += 56
		let cpuChartHeight = Float(64.0)
		
		//clear the drawing region (in case it is neccessary)
		//NSColor.windowBackgroundColor.setFill()
//		let chartBackgroundColor = NSColor.textBackgroundColor //NSColor(calibratedRed: 0.89, green: 0.905, blue: 0.935, alpha: 1.0)
//		chartBackgroundColor.setFill()
//		let chartRect = NSMakeRect(xOff, yOff, chartWidth - 1.0, (chartHeight * 2.0) + 3.0) //not sure why extra 3px
//		__NSRectFill(chartRect)
		
		let path = NSBezierPath()
		path.lineWidth = 2.0
		path.windingRule = NSBezierPath.WindingRule.evenOddWindingRule
		path.lineJoinStyle = NSBezierPath.LineJoinStyle.roundLineJoinStyle
		let numPoints = ResourceUsageView.cpuUsageHistorySamples
		
		var xOffBegin : CGFloat = 0
		for i in 0...(numPoints - 1) {
			if(cpuUsageHistory[i] == -1) {
				xOffBegin += chartWidth / CGFloat(numPoints)
			}
		}
		
		path.move(to: NSMakePoint(xOff + xOffBegin, yOff))
		
		for x in 0...(numPoints - 1) {
			let historyPoint = cpuUsageHistory[(cpuUsageOffset + x) % numPoints]
			if(historyPoint == -1) {
				continue
			}
			
			let xPos = CGFloat(x) * ((chartWidth - CGFloat(xOff) / 2.0) / (CGFloat(numPoints) - 1.0))
			let yPos = (historyPoint / 100.0) * cpuChartHeight
			path.line(to: NSMakePoint(xPos + xOff, CGFloat(yPos) + yOff))
		}
		
		path.line(to: NSMakePoint(CGFloat(chartWidth)+xOff-2, yOff))
		path.close()
		
		//path.fill()
		path.stroke()
		
	}
}
