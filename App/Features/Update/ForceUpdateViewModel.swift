import Foundation
import Observation
import AppUpdateKit

/// Presentation state for the update screen, derived from an `AppUpdateAction`.
/// Covers force / optional / maintenance / custom; `.none` is never presented.
@Observable
@MainActor
final class ForceUpdateViewModel {
    enum Kind: Equatable {
        case force
        case optional
        case maintenance
    }

    let action: AppUpdateAction
    private let onDismiss: () -> Void

    init(action: AppUpdateAction, onDismiss: @escaping () -> Void) {
        self.action = action
        self.onDismiss = onDismiss
    }

    var kind: Kind {
        switch action {
        case .forceUpdate: .force
        case .maintenance: .maintenance
        case .none, .optionalUpdate, .custom: .optional
        }
    }

    /// Force update and maintenance both keep the user on this screen.
    var isDismissible: Bool { !action.isBlocking }

    /// Store URL comes from the action (microCMS); maintenance carries none.
    var storeURL: URL? { action.storeURL }

    /// Remote copy wins; empty strings fall back to the localized defaults in the view.
    var remoteTitle: String? { Self.nonEmpty(action.title) }
    var remoteMessage: String? { Self.nonEmpty(action.message) }

    var releaseNotes: [String] { (action.releaseNotes ?? []).filter { !$0.isEmpty } }
    var versionText: String? { action.version?.description }

    func dismiss() {
        guard isDismissible else { return }
        onDismiss()
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return value
    }
}
