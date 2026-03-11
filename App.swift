import SwiftUI

@main
struct DailySelfieApp: App {
    // 将 AppDelegate 注入到 SwiftUI 生命周期中
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 使用 Settings 场景，因为我们不需要主窗口
        Settings {
            EmptyView()
        }
    }
} 