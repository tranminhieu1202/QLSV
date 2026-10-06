import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Màn hình có thanh điều hướng bên + bảng nhiều cột nên cần cửa sổ rộng;
    // mặc định 1280×800, không cho thu nhỏ quá mức làm vỡ bố cục. Vị trí và
    // kích thước được macOS ghi nhớ giữa các lần mở.
    self.title = "QLGD EDU"
    self.contentMinSize = NSSize(width: 1100, height: 680)
    if !self.setFrameUsingName("QLGDMainWindow") {
      self.setContentSize(NSSize(width: 1280, height: 800))
      self.center()
    }
    self.setFrameAutosaveName("QLGDMainWindow")

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
