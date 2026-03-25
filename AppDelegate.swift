import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    private let captureLock = NSLock()
    private var isCapturing = false
    private var lastCaptureTime: Date = .distantPast
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.processName = ""
        
        setupStatusItem()
        setupPopover()
        setupNotificationObservers()
        setupLaunchAtLogin()
        // 初始化日志管理器
        LogManager.shared.log("应用初始化完成")

        // 检查测试模式
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-testMode") {
            AppSettings.shared.testModeEnabled = true
            LogManager.shared.log("测试模式已启用", level: .info)
        } else {
            AppSettings.shared.testModeEnabled = false
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera", accessibilityDescription: "Daily Selfie")
            button.action = #selector(togglePopover)
        }
    }
    
    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: StatusBarView())
        self.popover = popover
    }
    
    private func setupNotificationObservers() {
        // 监听屏幕唤醒通知
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // 监听屏幕解锁通知 (更可靠的方法)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenUnlock),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )

        // 使用本地通知中心的屏幕解锁监听作为备用
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleScreenUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )

        LogManager.shared.log("通知观察者已注册", level: .info)
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    @objc private func handleWake(_ notification: Notification) {
        handleScreenEvent()
    }
    
    @objc private func handleScreenUnlock(_ notification: Notification) {
        LogManager.shared.log("收到屏幕解锁通知", level: .info)
        handleScreenEvent()
    }

    private func handleScreenEvent() {
        LogManager.shared.log("handleScreenEvent 被调用", level: .debug)

        captureLock.lock()
        defer { captureLock.unlock() }

        let now = Date()
        if now.timeIntervalSince(lastCaptureTime) < 60 {
            LogManager.shared.log("距离上次拍摄不足60秒，跳过", level: .debug)
            return
        }

        guard !isCapturing else {
            LogManager.shared.log("正在拍摄中，跳过", level: .debug)
            return
        }
        isCapturing = true
        lastCaptureTime = now

        LogManager.shared.log("开始初始化相机...", level: .info)

        let camera = CameraManager.shared
        camera.preInitializeCamera()

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            LogManager.shared.log("4秒后开始拍照", level: .info)
            camera.capturePhoto(forceCapture: false)
            self?.captureLock.lock()
            self?.isCapturing = false
            self?.captureLock.unlock()
        }
    }
    
    private func setupLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                try service.register()
                LogManager.shared.log("登录启动项已注册", level: .info)
            } catch {
                LogManager.shared.log("设置开机自启动失败：\(error.localizedDescription)", level: .error)
            }

            // 检查当前状态
            switch service.status {
            case .enabled:
                LogManager.shared.log("登录启动项状态: 已启用", level: .info)
            case .notRegistered:
                LogManager.shared.log("登录启动项状态: 未注册", level: .info)
            case .notFound:
                LogManager.shared.log("登录启动项状态: 未找到", level: .info)
            case .requiresApproval:
                LogManager.shared.log("登录启动项状态: 需要用户批准", level: .info)
            @unknown default:
                LogManager.shared.log("登录启动项状态: 未知状态", level: .info)
            }
        }
    }
}
