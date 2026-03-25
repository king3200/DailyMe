import Foundation

class AppSettings {
    static let shared = AppSettings()

    private init() {}

    var testModeEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "testModeEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "testModeEnabled")
        }
    }
}
