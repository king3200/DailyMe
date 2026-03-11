import AVFoundation
import AppKit
import SwiftUI

class CameraManager: NSObject, AVCapturePhotoCaptureDelegate {
    static let shared = CameraManager()
    
    private var session: AVCaptureSession?
    private var output: AVCapturePhotoOutput?
    private var isInitialized = false
    private var initializationQueue = DispatchQueue(label: "com.dailyme.camera.initialization")
    
    // 用于存储最后一次拍照的日期
    @AppStorage("lastPhotoDate") private var lastPhotoDate: Double = 0
    
    // 添加倒计时音效计时器
    private var countdownTimer: Timer?
    private var countdownCount = 0
    
    override init() {
        super.init()
    }
    
    // 检查今天是否已经拍过照
    private func hasPhotoTakenToday() -> Bool {
        let lastDate = Date(timeIntervalSince1970: lastPhotoDate)
        return Calendar.current.isDate(lastDate, inSameDayAs: Date())
    }
    
    private func initializeCameraIfNeeded(forceCapture: Bool = false) {
        guard !isInitialized else { return }
        
        initializationQueue.sync { [weak self] in
            guard let self = self, !isInitialized else { return }
            
            // 检查相机权限
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.setupCamera()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        DispatchQueue.main.async {
                            self.setupCamera()
                        }
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self.showCameraPermissionAlert()
                }
            @unknown default:
                break
            }
            
            isInitialized = true
        }
    }
    
    private func showCameraPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要相机权限"
        alert.informativeText = "请在系统设置中允许应用访问相机"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func setupCamera() {
        // 先确保之前的会话已经关闭
        stopCamera()
        
        let session = AVCaptureSession()
        self.session = session
        
        // 确保在后台线程进行相机设置
        DispatchQueue.global(qos: .userInitiated).async {
            session.beginConfiguration()
            
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if session.canAddInput(input) {
                        session.addInput(input)
                    }
                    
                    let output = AVCapturePhotoOutput()
                    if session.canAddOutput(output) {
                        session.addOutput(output)
                        self.output = output
                    }
                } catch {
                    print("相机设置错误：\(error.localizedDescription)")
                }
            }
            
            session.commitConfiguration()
            session.startRunning()
        }
    }
    
    func capturePhoto(forceCapture: Bool = false) {
        // 先检查是否已经拍过照
        if !forceCapture && hasPhotoTakenToday() {
            print("今天已经拍过照了")
            return
        }
        
        // 确保相机已初始化
        if !isInitialized {
            initializeCameraIfNeeded(forceCapture: forceCapture)
            // 给相机一些时间完成初始化
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.startCountdown()
            }
        } else {
            startCountdown()
        }
    }
    
    // 添加倒计时方法
    private func startCountdown() {
        countdownCount = 4 // 4秒倒计时
        
        // 创建计时器
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.countdownCount -= 1
            
            if self.countdownCount > 0 {
                // 播放倒计时音效
                NSSound(named: "Tink")?.play()
            } else {
                // 时间到，拍照
                timer.invalidate()
                self.takePicture()
            }
        }
    }
    
    private func takePicture() {
        guard let output = output, let session = session, session.isRunning else {
            print("相机未准备就绪")
            return
        }
        
        // 播放拍照声音
        NSSound(named: "Camera Shutter")?.play()
        
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            // 无论是否成功，都确保相机关闭
            stopCamera()
        }
        
        if let error = error {
            print("拍照错误：\(error.localizedDescription)")
            // 播放错误提示音
            NSSound(named: "Basso")?.play()
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let saveDirectory = UserDefaults.standard.string(forKey: "saveDirectory") else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "selfie_\(dateFormatter.string(from: Date())).jpg"
        let fileURL = URL(fileURLWithPath: saveDirectory).appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            // 更新最后拍照日期
            lastPhotoDate = Date().timeIntervalSince1970
            // 播放成功提示音
            NSSound(named: "Glass")?.play()
        } catch {
            print("保存照片错误：\(error.localizedDescription)")
            // 播放错误提示音
            NSSound(named: "Basso")?.play()
        }
    }
    
    // 停止相机会话时也要清理计时器
    private func stopCamera() {
        // 停止倒计时计时器
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let session = self.session, session.isRunning {
                session.stopRunning()
            }
            
            self.session = nil
            self.output = nil
            self.isInitialized = false
        }
    }
    
    // 预初始化相机时也需要检查是否已拍照
    func preInitializeCamera() {
        if hasPhotoTakenToday() {
            print("今天已经拍过照了")
            return
        }
        
        if !isInitialized {
            initializeCameraIfNeeded(forceCapture: false)
        }
    }
} 
