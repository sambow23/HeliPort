//
//  PrefsGeneralView.swift
//  HeliPort
//
//  Created by Erik Bautista on 8/3/20.
//  Copyright © 2020 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Cocoa
import Sparkle

class PrefsGeneralView: NSView {

    let updatesLabel: NSTextField = {
        let view = NSTextField(labelWithString: .startup)
        view.alignment = .right
        return view
    }()

    lazy var autoUpdateCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .autoCheckUpdate,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .autoUpdateId
        checkbox.state = UpdateManager.sharedUpdater.automaticallyChecksForUpdates ? .on : .off
        return checkbox
    }()

    lazy var autoDownloadCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .autoDownload,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .autoDownloadId
        checkbox.state = UpdateManager.sharedUpdater.automaticallyDownloadsUpdates ? .on : .off
        return checkbox
    }()

    let appearanceLabel: NSTextField = {
        let view = NSTextField(labelWithString: .appearance)
        view.alignment = .right
        return view
    }()

    lazy var legacyUICheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .useLegacyUI,
                                target: self,
                                action: #selector(self.checkboxChanged(_:)))
        checkbox.identifier = .legacyUIId

        if #available(macOS 11, *) {
            checkbox.state = UserDefaults.standard.bool(forKey: .DefaultsKey.legacyUI) ? .on : .off
        } else {
            checkbox.state = .on
            checkbox.isEnabled = false
        }

        return checkbox
    }()
    
    let connectionLabel: NSTextField = {
        let view = NSTextField(labelWithString: .connection)
        view.alignment = .right
        return view
    }()
    
    lazy var enableNotificationsCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .enableNotifications,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .enableNotificationsId
        checkbox.state = UserDefaults.standard.bool(forKey: .DefaultsKey.enableNotifications) ? .on : .off
        return checkbox
    }()
    
    lazy var enableAutoConnectCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .enableAutoConnect,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .enableAutoConnectId
        checkbox.state = UserDefaults.standard.bool(forKey: .DefaultsKey.enableAutoConnect) ? .on : .off
        return checkbox
    }()
    
    lazy var enableAutoReconnectCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .enableAutoReconnect,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .enableAutoReconnectId
        checkbox.state = UserDefaults.standard.bool(forKey: .DefaultsKey.enableAutoReconnect) ? .on : .off
        return checkbox
    }()
    
    lazy var showConnectionDurationCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .showConnectionDuration,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .showConnectionDurationId
        checkbox.state = UserDefaults.standard.bool(forKey: .DefaultsKey.showConnectionDuration) ? .on : .off
        return checkbox
    }()

    let gridView: NSGridView = {
        let view = NSGridView()
        view.setContentHuggingPriority(.init(rawValue: 600), for: .horizontal)
        return view
    }()

    convenience init() {
        self.init(frame: NSRect.zero)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        gridView.addRow(with: [updatesLabel])
        gridView.addColumn(with: [autoUpdateCheckbox, autoDownloadCheckbox])
        let appearanceRow = gridView.addRow(with: [appearanceLabel, legacyUICheckbox])
        appearanceRow.topPadding = 5
        
        let connectionRow = gridView.addRow(with: [connectionLabel])
        connectionRow.topPadding = 5
        gridView.addColumn(with: [enableNotificationsCheckbox, enableAutoConnectCheckbox, 
                                  enableAutoReconnectCheckbox, showConnectionDurationCheckbox])

        addSubview(gridView)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let inset: CGFloat = 20
        gridView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset).isActive = true
        gridView.topAnchor.constraint(equalTo: topAnchor, constant: inset).isActive = true
        gridView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset).isActive = true
        gridView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset).isActive = true
    }
}

extension PrefsGeneralView {
    @objc private func checkboxChanged(_ sender: NSButton) {
        guard let identifier = sender.identifier else { return }
        Log.debug("State changed for \(identifier)")

        switch identifier {
        case .autoUpdateId:
            UpdateManager.sharedUpdater.automaticallyChecksForUpdates = sender.state == .on
        case .autoDownloadId:
            UpdateManager.sharedUpdater.automaticallyDownloadsUpdates = sender.state == .on
        case .legacyUIId:
            if #available(macOS 11, *) {
                UserDefaults.standard.set(sender.state == .on, forKey: .DefaultsKey.legacyUI)
                let alert = CriticalAlert(message: .heliportRestart,
                                          informativeText: .restartInfoText,
                                          options: [.restart, .later])

                if alert.show() == .alertFirstButtonReturn {
                    NSApp.restartApp()
                }
            }
        case .enableNotificationsId:
            UserDefaults.standard.set(sender.state == .on, forKey: .DefaultsKey.enableNotifications)
        case .enableAutoConnectId:
            UserDefaults.standard.set(sender.state == .on, forKey: .DefaultsKey.enableAutoConnect)
        case .enableAutoReconnectId:
            UserDefaults.standard.set(sender.state == .on, forKey: .DefaultsKey.enableAutoReconnect)
        case .showConnectionDurationId:
            UserDefaults.standard.set(sender.state == .on, forKey: .DefaultsKey.showConnectionDuration)
        default:
            break
        }
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let autoUpdateId = NSUserInterfaceItemIdentifier(rawValue: "AutoUpdateCheckbox")
    static let autoDownloadId = NSUserInterfaceItemIdentifier(rawValue: "AutoDownloadCheckbox")
    static let legacyUIId = NSUserInterfaceItemIdentifier(rawValue: "legacyUICheckbox")
    static let enableNotificationsId = NSUserInterfaceItemIdentifier(rawValue: "EnableNotificationsCheckbox")
    static let enableAutoConnectId = NSUserInterfaceItemIdentifier(rawValue: "EnableAutoConnectCheckbox")
    static let enableAutoReconnectId = NSUserInterfaceItemIdentifier(rawValue: "EnableAutoReconnectCheckbox")
    static let showConnectionDurationId = NSUserInterfaceItemIdentifier(rawValue: "ShowConnectionDurationCheckbox")
}

private extension String {
    static let startup = NSLocalizedString("Updates:")
    static let autoCheckUpdate = NSLocalizedString("Automatically check for updates.")
    static let autoDownload = NSLocalizedString("Automatically download new updates.")

    static let appearance = NSLocalizedString("Appearance:")
    static let useLegacyUI = NSLocalizedString("Use Legacy UI")
    
    static let connection = NSLocalizedString("Connection:")
    static let enableNotifications = NSLocalizedString("Show connection notifications")
    static let enableAutoConnect = NSLocalizedString("Automatically connect to saved networks on startup")
    static let enableAutoReconnect = NSLocalizedString("Automatically reconnect when disconnected")
    static let showConnectionDuration = NSLocalizedString("Show connection duration in menu")

    static let heliportRestart = NSLocalizedString("HeliPort Restart Required")
    static let restartInfoText =
        NSLocalizedString("Switching appearance requires a restart of the application to take effect.")
    static let restart = NSLocalizedString("Restart")
    static let later = NSLocalizedString("Later")
}
