import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    // 状态栏图标项
    var statusItem: NSStatusItem?
    // 弹出窗口
    var popover: NSPopover?
    // 用于跟踪相机初始化状态
    private var isCameraInitializing = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 在最开始添加这行代码
        ProcessInfo.processInfo.processName = ""  // 这会隐藏 Dock 图标
        
        // 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let statusButton = statusItem?.button {
            // 设置图标为相机图标
            statusButton.image = NSImage(systemSymbolName: "camera", accessibilityDescription: "Daily Selfie")
        }
        
        // 创建弹出菜单
        let popover = NSPopover()
        // 设置弹出窗口大小
        popover.contentSize = NSSize(width: 300, height: 200)
        // 设置点击其他地方自动关闭
        popover.behavior = .transient
        // 设置弹出窗口的内容视图
        popover.contentViewController = NSHostingController(rootView: StatusBarView())
        self.popover = popover
        
        // 为状态栏图标添加点击事件
        statusItem?.button?.action = #selector(togglePopover)
        
        // 注册系统唤醒事件监听器
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screenDidUnlock(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        // 注册登录窗口解锁事件监听器
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenDidUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
        
        // 配置开机自启动
        setupLaunchAtStartup()
    }
    
    // 切换弹出窗口的显示状态
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    // 屏幕解锁时触发拍照
    @objc func screenDidUnlock(_ notification: Notification) {
        // 避免重复初始化
        guard !isCameraInitializing else { return }
        isCameraInitializing = true
        
        // 预初始化相机
        let camera = CameraManager.shared
        camera.preInitializeCamera()
        
        // 4秒后进行拍照
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            camera.capturePhoto(forceCapture: false)
            self?.isCameraInitializing = false
        }
    }
    
    // 设置开机自启动
    func setupLaunchAtStartup() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                print("设置开机自启动失败：\(error.localizedDescription)")
            }
        } else {
            // 对于旧版本 macOS，提示用户手动设置
            let alert = NSAlert()
            alert.messageText = "开机自启动设置"
            alert.informativeText = "请在系统设置中手动添加本应用到登录项中"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "打开系统设置")
            alert.addButton(withTitle: "取消")
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
} 