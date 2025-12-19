//
//  WiFiMenuItemViewModern.swift
//  HeliPort
//
//  Created by Bat.bat on 19/6/2024.
//  Copyright © 2024 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Cocoa

@available(macOS 11, *)
private class CircleSignalView: NSView {
    var image: NSImage? {
        willSet {
            signalView.image = newValue
        }
    }

    var active: Bool = false {
        willSet {
            fillColor = newValue ? .controlAccentColor : CircleSignalView.inactiveColor
            signalView.contentTintColor = newValue ? .white : .controlTextColor
            // Force redraw to apply the new fillColor
            setNeedsDisplay(bounds)
        }
    }

    private static let inactiveColor = NSColor(named: "SignalBackgroundColor")!

    private let signalView = NSImageView()
    private var fillColor: NSColor = inactiveColor

    init() {
        super.init(frame: .zero)
        addSubview(signalView)

        let signalSize: CGFloat = 17

        translatesAutoresizingMaskIntoConstraints = false
        signalView.translatesAutoresizingMaskIntoConstraints = false
        signalView.imageScaling = .scaleProportionallyUpOrDown
        NSLayoutConstraint.activate([
            signalView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            signalView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            signalView.widthAnchor.constraint(equalToConstant: signalSize),
            signalView.heightAnchor.constraint(equalToConstant: signalSize)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: 26, height: 26))
        fillColor.setFill()
        path.fill()
    }
}

@available(macOS 11, *)
class WifiMenuItemViewModern: SelectableMenuItemView, WifiMenuItemView {

    // MARK: Initializers

    private let lockImage: NSImageView = {
        let lockImage = NSImageView()
        lockImage.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lockImage.image = NSImage(systemSymbolName: "lock.fill")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 13, weight: .medium))
        lockImage.image?.isTemplate = true
        lockImage.alphaValue = 0.5
        return lockImage
    }()

    private let signalCircle: CircleSignalView = {
        let signalImage = CircleSignalView()
        signalImage.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return signalImage
    }()

    private let ssidLabel: NSTextField = {
        let ssidLabel = NSTextField(labelWithString: "")
        ssidLabel.font = NSFont.menuFont(ofSize: 0)
        return ssidLabel
    }()

    init(networkInfo: NetworkInfo) {
        self.networkInfo = networkInfo
        super.init(height: .networkModern, hoverStyle: .greytint)

        addSubview(ssidLabel)
        addSubview(lockImage)
        addSubview(signalCircle)

        setupLayout()

        // willSet/didSet will not be called during initialization
        defer {
            self.networkInfo = networkInfo
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var networkInfo: NetworkInfo {
        willSet(info) {
            ssidLabel.stringValue = info.ssid
            layoutSubtreeIfNeeded()
        }
        didSet {
            updateImages()
        }
    }

    public var connected: Bool = false {
        didSet {
            guard oldValue != connected else { return }
            signalCircle.active = connected
        }
    }

    public func updateImages() {
        signalCircle.image = StatusBarIcon.shared().getRssiImage(rssi: Int16(networkInfo.rssi))
        lockImage.isHidden = networkInfo.auth.security == ITL80211_SECURITY_NONE
    }

    // MARK: Internal

    internal override func setupLayout() {
        super.setupLayout()

        let signalCircleSize: CGFloat = 28
        let lockWidth: CGFloat = 16

        NSLayoutConstraint.activate([
            signalCircle.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            signalCircle.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            signalCircle.widthAnchor.constraint(equalToConstant: signalCircleSize),
            signalCircle.heightAnchor.constraint(equalToConstant: signalCircleSize),

            ssidLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            ssidLabel.leadingAnchor.constraint(equalTo: signalCircle.trailingAnchor, constant: 6),

            lockImage.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            lockImage.leadingAnchor.constraint(equalTo: ssidLabel.trailingAnchor, constant: 6),
            lockImage.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            lockImage.widthAnchor.constraint(equalToConstant: lockWidth)
        ])
    }

    // MARK: Overrides

    override func mouseUp(with event: NSEvent) {
        // Do not close the menu if the user clicked on a connected item
        if connected {
            connected = false
            updateImages()
            DispatchQueue.global().async {
                dis_associate_ssid(self.networkInfo.ssid)
                Log.debug("Disconnected from \(self.networkInfo.ssid)")
            }
        } else {
            isMouseOver = false
            enclosingMenuItem?.menu?.cancelTracking()
            NetworkManager.connect(networkInfo: networkInfo, saveNetwork: true)
        }
    }
    
    override func rightMouseUp(with event: NSEvent) {
        showContextMenu(at: event.locationInWindow)
    }
    
    private func showContextMenu(at location: NSPoint) {
        let menu = NSMenu()
        
        // Check if network is saved
        let isSaved = CredentialsManager.instance.getSavedNetworkSSIDs().contains(networkInfo.ssid)
        
        if isSaved {
            let forgetItem = NSMenuItem(title: NSLocalizedString("Forget This Network"), 
                                       action: #selector(forgetNetwork), 
                                       keyEquivalent: "")
            forgetItem.target = self
            menu.addItem(forgetItem)
            
            let autoJoinItem = NSMenuItem(title: NSLocalizedString("Toggle Auto-Join"), 
                                         action: #selector(toggleAutoJoin), 
                                         keyEquivalent: "")
            autoJoinItem.target = self
            menu.addItem(autoJoinItem)
        }
        
        let copySSIDItem = NSMenuItem(title: NSLocalizedString("Copy Network Name"), 
                                     action: #selector(copySSID), 
                                     keyEquivalent: "")
        copySSIDItem.target = self
        menu.addItem(copySSIDItem)
        
        menu.popUp(positioning: nil, at: location, in: self)
    }
    
    @objc private func forgetNetwork() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Forget Network?")
        alert.informativeText = String(format: NSLocalizedString("Are you sure you want to forget \"%@\"?"), networkInfo.ssid)
        alert.addButton(withTitle: NSLocalizedString("Forget"))
        alert.addButton(withTitle: NSLocalizedString("Cancel"))
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            CredentialsManager.instance.remove(networkInfo)
            Log.debug("Forgot network: \(networkInfo.ssid)")
            
            // Refresh the menu
            enclosingMenuItem?.menu?.cancelTracking()
        }
    }
    
    @objc private func toggleAutoJoin() {
        if let storage = CredentialsManager.instance.getStorageFromSsid(networkInfo.ssid) {
            let newAutoJoin = !storage.autoJoin
            CredentialsManager.instance.setAutoJoin(networkInfo.ssid, newAutoJoin)
            Log.debug("Set auto-join for \(networkInfo.ssid) to \(newAutoJoin)")
        }
    }
    
    @objc private func copySSID() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(networkInfo.ssid, forType: .string)
        Log.debug("Copied SSID: \(networkInfo.ssid)")
    }
}
