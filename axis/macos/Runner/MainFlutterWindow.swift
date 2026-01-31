import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // Set a reasonable window size and center it
    let screenSize = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
    let windowSize = NSSize(width: 1200, height: 800)
    let windowFrame = NSRect(
      x: (screenSize.width - windowSize.width) / 2,
      y: (screenSize.height - windowSize.height) / 2,
      width: windowSize.width,
      height: windowSize.height
    )
    
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    
    // Ensure window is visible and brought to front
    self.makeKeyAndOrderFront(nil)
    self.orderFrontRegardless()
    NSApp.activate(ignoringOtherApps: true)
  }
}
