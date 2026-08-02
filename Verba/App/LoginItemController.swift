import Foundation
import ServiceManagement

struct LoginItemController: Sendable {

    // MARK: Dependencies

    private let preferences: PreferenceStoring
    private let logger: AppLogger

    // MARK: Public properties

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    // MARK: Init

    init(preferences: PreferenceStoring, logger: AppLogger) {
        self.preferences = preferences
        self.logger = logger
    }

    // MARK: Public methods

    func syncPreferenceOnLaunch() {
        preferences.launchAtLogin = isEnabled
    }

    func setEnabled(_ enabled: Bool) async {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try await SMAppService.mainApp.unregister()
            }
            logger.loginItemChanged(requestedEnabled: enabled, succeeded: true)
        } catch {
            logger.loginItemChanged(requestedEnabled: enabled, succeeded: false)
        }
        preferences.launchAtLogin = isEnabled
    }
}
