import SwiftUI
import AppUpdateKit
import VNCalendarDesignSystem

/// App-owned update screen (design.html `.force`): hero, release notes group, primary action.
struct ForceUpdateView: View {
    @Environment(\.openURL) private var openURL
    let viewModel: ForceUpdateViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: VNSpacing.space32) {
                UpdateHero(kind: viewModel.kind)
                    .vnAppear()
                titleBlock
                    .vnAppear(delay: 0.05)
                if !viewModel.releaseNotes.isEmpty {
                    UpdateNotesSection(notes: viewModel.releaseNotes, version: viewModel.versionText)
                        .vnAppear(delay: 0.1)
                }
                actions
                    .vnAppear(delay: 0.15)
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.vertical, VNSpacing.space32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .interactiveDismissDisabled(!viewModel.isDismissible)
    }

    private var titleBlock: some View {
        VStack(spacing: VNSpacing.md) {
            Group {
                if let title = viewModel.remoteTitle {
                    Text(verbatim: title)
                } else {
                    Text(defaultTitle)
                }
            }
            .font(.vnTitleFestival)
            .foregroundStyle(Color.vnTextPrimary)
            .accessibilityAddTraits(.isHeader)

            Group {
                if let message = viewModel.remoteMessage {
                    Text(verbatim: message)
                } else {
                    Text(defaultMessage)
                }
            }
            .font(.vnBody)
            .foregroundStyle(Color.vnTextSecondary)
        }
        .multilineTextAlignment(.center)
    }

    private var actions: some View {
        VStack(spacing: VNSpacing.md) {
            if let url = viewModel.storeURL {
                VNButton(String(localized: "update.action.update"), isFullWidth: true) { openURL(url) }
            }
            if viewModel.isDismissible {
                let hasStore = viewModel.storeURL != nil
                VNButton(
                    String(localized: hasStore ? "update.action.later" : "update.action.close"),
                    variant: hasStore ? .tertiary : .primary,
                    isFullWidth: true
                ) { viewModel.dismiss() }
            }
        }
    }

    private var defaultTitle: LocalizedStringKey {
        switch viewModel.kind {
        case .force: "update.force.title"
        case .optional: "update.optional.title"
        case .maintenance: "update.maintenance.title"
        }
    }

    private var defaultMessage: LocalizedStringKey {
        switch viewModel.kind {
        case .force: "update.force.message"
        case .optional: "update.optional.message"
        case .maintenance: "update.maintenance.message"
        }
    }
}
