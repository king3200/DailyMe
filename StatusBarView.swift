import SwiftUI

struct StatusBarView: View {
    @AppStorage("saveDirectory") private var saveDirectory = ""
    @AppStorage("lastPhotoDate") private var lastPhotoDate: Double = 0
    @State private var showDirectoryAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showQuitConfirmation = false
    
    private var lastPhotoTimeString: String {
        if lastPhotoDate == 0 {
            return "尚未拍摄"
        }
        let date = Date(timeIntervalSince1970: lastPhotoDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 拍照按钮
            Button(action: {
                if saveDirectory.isEmpty {
                    showDirectoryAlert = true
                } else {
                    CameraManager.shared.capturePhoto(forceCapture: true)
                }
            }) {
                HStack {
                    Image(systemName: "camera.circle.fill")
                        .font(.title2)
                    Text("立即拍照")
                }
            }
            .buttonStyle(.borderedProminent)
            
            Divider()
            
            // 目录管理区域
            HStack {
                Button("选择目录") {
                    selectDirectory()
                }
                Button("打开目录") {
                    openSaveDirectory()
                }
                .disabled(saveDirectory.isEmpty)
            }
            
            // 当前目录显示
            Text(saveDirectory.isEmpty ? "未设置保存目录" : "保存至：\(saveDirectory)")
                .lineLimit(1)
                .truncationMode(.middle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Divider()
            
            // 底部信息和操作区
            HStack {
                VStack(alignment: .leading) {
                    Text("上次拍摄：")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(lastPhotoTimeString)
                        .font(.system(size: 11))
                }
                
                Spacer()
                
                // 删除按钮
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                }
                .disabled(saveDirectory.isEmpty || !hasPhotoTakenToday())
                
                // 退出按钮
                Button(action: {
                    showQuitConfirmation = true
                }) {
                    Image(systemName: "power.circle")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(10)
        .frame(width: 280)
        .alert("需要设置保存目录", isPresented: $showDirectoryAlert) {
            Button("确定") {
                selectDirectory()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请先选择照片保存的目录")
        }
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("删除", role: .destructive) {
                deleteTodayPhotos()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除今天拍摄的照片吗？")
        }
        .alert("确认退出", isPresented: $showQuitConfirmation) {
            Button("退出", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要退出应用吗？")
        }
    }
    
    private func hasPhotoTakenToday() -> Bool {
        guard lastPhotoDate > 0 else { return false }
        let lastDate = Date(timeIntervalSince1970: lastPhotoDate)
        return Calendar.current.isDateInToday(lastDate)
    }
    
    private func deleteTodayPhotos() {
        guard !saveDirectory.isEmpty else { return }
        
        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: saveDirectory)
        
        do {
            // 获取目录中的所有文件
            let files = try fileManager.contentsOfDirectory(at: directoryURL, 
                                                          includingPropertiesForKeys: [.creationDateKey],
                                                          options: [.skipsHiddenFiles])
            
            // 获取今天的日期字符串
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: Date())
            
            // 查找并删除今天的照片
            for file in files {
                if file.lastPathComponent.hasPrefix("selfie_\(todayString)") {
                    try fileManager.removeItem(at: file)
                }
            }
            
            // 重置最后拍照时间
            if hasPhotoTakenToday() {
                lastPhotoDate = 0
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "删除失败"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "请选择照片保存目录"
        panel.prompt = "选择"
        
        panel.treatsFilePackagesAsDirectories = true
        panel.allowedContentTypes = [.folder]
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                // 测试目录写入权限
                let testFile = url.appendingPathComponent(".test")
                do {
                    try "test".write(to: testFile, atomically: true, encoding: .utf8)
                    try FileManager.default.removeItem(at: testFile)
                    saveDirectory = url.path
                } catch {
                    showWritePermissionAlert()
                }
            }
        }
    }
    
    private func showWritePermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "无法访问所选目录"
        alert.informativeText = "请确保应用有权限访问该目录，或选择其他目录"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    private func openSaveDirectory() {
        guard !saveDirectory.isEmpty else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: saveDirectory))
    }
} 
