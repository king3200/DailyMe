import AVFoundation
import AppKit
import SwiftUI

final class CameraManager: NSObject, AVCapturePhotoCaptureDelegate {
    static let shared = CameraManager()
    
    private let sessionQueue = DispatchQueue(label: "com.dailyme.camera.session")
    private var session: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoDevice: AVCaptureDevice?
    
    private let stateQueue = DispatchQueue(label: "com.dailyme.camera.state")
    private var _isSessionRunning = false
    private var _isInitializing = false
    
    private var isSessionRunning: Bool {
        get { stateQueue.sync { _isSessionRunning } }
        set { stateQueue.sync { _isSessionRunning = newValue } }
    }
    
    private var isInitializing: Bool {
        get { stateQueue.sync { _isInitializing } }
        set { stateQueue.sync { _isInitializing = newValue } }
    }
    
    @AppStorage("lastPhotoDate") private var lastPhotoDate: Double = 0
    
    private var countdownTimer: Timer?
    private var countdownCount = 0
    private var countdownWorkItem: DispatchWorkItem?
    
    override init() {
        super.init()
    }
    
    private func hasPhotoTakenToday() -> Bool {
        guard lastPhotoDate > 0 else { return false }
        let lastDate = Date(timeIntervalSince1970: lastPhotoDate)
        return Calendar.current.isDate(lastDate, inSameDayAs: Date())
    }
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showCameraPermissionAlert()
            }
            completion(false)
        @unknown default:
            completion(false)
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
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session?.stopRunning()
            
            let newSession = AVCaptureSession()
            newSession.beginConfiguration()
            newSession.sessionPreset = .photo
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                LogManager.shared.log("无法获取前置摄像头", level: .error)
                newSession.commitConfiguration()
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if newSession.canAddInput(input) {
                    newSession.addInput(input)
                }
                
                let output = AVCapturePhotoOutput()
                if newSession.canAddOutput(output) {
                    newSession.addOutput(output)
                    self.photoOutput = output
                }
                
                self.videoDevice = device
            } catch {
                LogManager.shared.log("相机设置错误：\(error.localizedDescription)", level: .error)
                newSession.commitConfiguration()
                return
            }
            
            newSession.commitConfiguration()
            newSession.startRunning()
            
            self.session = newSession
            self.isSessionRunning = true
        }
    }
    
    private func ensureCameraReady(completion: @escaping () -> Void) {
        LogManager.shared.log("ensureCameraReady 被调用, isSessionRunning: \(isSessionRunning), isInitializing: \(isInitializing)", level: .debug)

        if isSessionRunning {
            LogManager.shared.log("会话已在运行，直接回调", level: .debug)
            completion()
            return
        }

        if isInitializing {
            LogManager.shared.log("正在初始化，等待后重试...", level: .debug)
            sessionQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.ensureCameraReady(completion: completion)
            }
            return
        }

        LogManager.shared.log("开始初始化相机...", level: .debug)
        isInitializing = true
        checkCameraPermission { [weak self] granted in
            guard granted else {
                self?.isInitializing = false
                LogManager.shared.log("相机权限被拒绝", level: .error)
                return
            }
            LogManager.shared.log("相机权限已授予，设置相机", level: .info)
            self?.setupCamera()

            self?.sessionQueue.asyncAfter(deadline: .now() + 1.0) {
                self?.isInitializing = false
                LogManager.shared.log("相机设置完成，执行回调", level: .debug)
                completion()
            }
        }
    }
    
    func capturePhoto(forceCapture: Bool = false) {
        LogManager.shared.log("capturePhoto 被调用, forceCapture: \(forceCapture)", level: .debug)

        if !forceCapture && !AppSettings.shared.testModeEnabled && hasPhotoTakenToday() {
            LogManager.shared.log("今天已经拍过照了，跳过", level: .debug)
            return
        }

        LogManager.shared.log("开始确保相机就绪...", level: .debug)
        ensureCameraReady { [weak self] in
            LogManager.shared.log("相机就绪，开始倒计时", level: .info)
            self?.startCountdown()
        }
    }
    
    private func startCountdown() {
        LogManager.shared.log("startCountdown 被调用", level: .debug)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            LogManager.shared.log("开始倒计时，countdownCount = 4", level: .debug)
            self.countdownCount = 4

            self.countdownTimer?.invalidate()
            self.countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                self.countdownCount -= 1
                
                if self.countdownCount > 0 {
                    NSSound(named: "Tink")?.play()
                } else {
                    timer.invalidate()
                    self.takePicture()
                }
            }
        }
    }
    
    private func takePicture() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let output = self.photoOutput,
                  let session = self.session,
                  session.isRunning else {
                LogManager.shared.log("相机未准备就绪", level: .error)
                return
            }
            
            NSSound(named: "Camera Shutter")?.play()
            
            let settings = AVCapturePhotoSettings()
            output.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            LogManager.shared.log("拍照错误：\(error.localizedDescription)", level: .error)
            NSSound(named: "Basso")?.play()
            stopCamera()
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let saveDirectory = UserDefaults.standard.string(forKey: "saveDirectory") else {
            stopCamera()
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "selfie_\(dateFormatter.string(from: Date())).jpg"
        let fileURL = URL(fileURLWithPath: saveDirectory).appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            lastPhotoDate = Date().timeIntervalSince1970
            LogManager.shared.log("照片保存成功: \(fileName)", level: .info)
            NSSound(named: "Glass")?.play()
        } catch {
            LogManager.shared.log("保存照片错误：\(error.localizedDescription)", level: .error)
            NSSound(named: "Basso")?.play()
        }
        
        stopCamera()
    }
    
    private func stopCamera() {
        DispatchQueue.main.async { [weak self] in
            self?.countdownTimer?.invalidate()
            self?.countdownTimer = nil
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session?.stopRunning()
            self.session = nil
            self.photoOutput = nil
            self.videoDevice = nil
            self.isSessionRunning = false
        }
    }
    
    func preInitializeCamera() {
        LogManager.shared.log("preInitializeCamera 被调用", level: .debug)

        if !AppSettings.shared.testModeEnabled && hasPhotoTakenToday() {
            LogManager.shared.log("今天已经拍过照了", level: .debug)
            return
        }

        guard !isSessionRunning && !isInitializing else {
            LogManager.shared.log("相机已在使用中或初始化中", level: .debug)
            return
        }

        LogManager.shared.log("开始检查相机权限...", level: .debug)
        isInitializing = true
        checkCameraPermission { [weak self] granted in
            guard granted else {
                self?.isInitializing = false
                LogManager.shared.log("相机权限被拒绝", level: .error)
                return
            }
            LogManager.shared.log("相机权限已授予，开始设置相机", level: .info)
            self?.setupCamera()

            // 延迟重置 isInitializing，参考 ensureCameraReady 的实现
            self?.sessionQueue.asyncAfter(deadline: .now() + 1.0) {
                self?.isInitializing = false
                LogManager.shared.log("preInitializeCamera 完成，isInitializing 重置", level: .debug)
            }
        }
    }
}
