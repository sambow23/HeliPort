//
//  NotificationManager.swift
//  HeliPort
//
//  Created by HeliPort Contributors
//  Copyright © 2025 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Foundation
import UserNotifications

@available(macOS 10.14, *)
final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private var isAuthorized = false
    
    private override init() {
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                Log.error("Notification authorization error: \(error.localizedDescription)")
            }
            self.isAuthorized = granted
            Log.debug("Notification authorization: \(granted)")
        }
    }
    
    func showConnectionSuccess(ssid: String, autoConnected: Bool = false) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Connected")
        if autoConnected {
            content.body = String(format: NSLocalizedString("Automatically connected to \"%@\""), ssid)
        } else {
            content.body = String(format: NSLocalizedString("Connected to \"%@\""), ssid)
        }
        content.sound = .default
        
        sendNotification(identifier: "connection-success", content: content)
    }
    
    func showConnectionFailure(ssid: String, reason: String? = nil) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Connection Failed")
        if let reason = reason {
            content.body = String(format: NSLocalizedString("Failed to connect to \"%@\": %@"), ssid, reason)
        } else {
            content.body = String(format: NSLocalizedString("Failed to connect to \"%@\""), ssid)
        }
        content.sound = .default
        
        sendNotification(identifier: "connection-failure", content: content)
    }
    
    func showDisconnection(ssid: String) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Disconnected")
        content.body = String(format: NSLocalizedString("Disconnected from \"%@\""), ssid)
        
        sendNotification(identifier: "disconnection", content: content)
    }
    
    func showReconnecting(ssid: String) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Reconnecting")
        content.body = String(format: NSLocalizedString("Attempting to reconnect to \"%@\""), ssid)
        
        sendNotification(identifier: "reconnecting", content: content)
    }
    
    private func sendNotification(identifier: String, content: UNMutableNotificationContent) {
        guard isAuthorized else { return }
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Log.error("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
    
    private var isEnabled: Bool {
        return UserDefaults.standard.bool(forKey: .DefaultsKey.enableNotifications)
    }
}

// MARK: - UNUserNotificationCenterDelegate

@available(macOS 10.14, *)
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when app is in foreground
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}

