//
//  ConnectionHistoryManager.swift
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

struct ConnectionHistoryEntry: Codable {
    let ssid: String
    let connectedAt: Date
    let disconnectedAt: Date?
    let success: Bool
    let failureReason: String?
    
    var duration: TimeInterval? {
        guard let disconnectedAt = disconnectedAt else { return nil }
        return disconnectedAt.timeIntervalSince(connectedAt)
    }
}

final class ConnectionHistoryManager {
    static let shared = ConnectionHistoryManager()
    
    private let maxHistoryEntries = 100
    private let historyKey = "ConnectionHistory"
    
    private var history: [ConnectionHistoryEntry] = []
    
    private init() {
        loadHistory()
    }
    
    func recordConnection(ssid: String) {
        let entry = ConnectionHistoryEntry(
            ssid: ssid,
            connectedAt: Date(),
            disconnectedAt: nil,
            success: true,
            failureReason: nil
        )
        addEntry(entry)
    }
    
    func recordDisconnection(ssid: String) {
        // Update the most recent connection for this SSID
        if let index = history.firstIndex(where: { $0.ssid == ssid && $0.disconnectedAt == nil }) {
            let entry = history[index]
            history.remove(at: index)
            let updatedEntry = ConnectionHistoryEntry(
                ssid: entry.ssid,
                connectedAt: entry.connectedAt,
                disconnectedAt: Date(),
                success: entry.success,
                failureReason: entry.failureReason
            )
            history.insert(updatedEntry, at: 0)
            saveHistory()
        }
    }
    
    func recordFailure(ssid: String, reason: String) {
        let entry = ConnectionHistoryEntry(
            ssid: ssid,
            connectedAt: Date(),
            disconnectedAt: Date(),
            success: false,
            failureReason: reason
        )
        addEntry(entry)
    }
    
    func getHistory(limit: Int = 20) -> [ConnectionHistoryEntry] {
        return Array(history.prefix(limit))
    }
    
    func getLastSuccessfulConnection(for ssid: String) -> ConnectionHistoryEntry? {
        return history.first { $0.ssid == ssid && $0.success }
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    private func addEntry(_ entry: ConnectionHistoryEntry) {
        history.insert(entry, at: 0)
        
        // Keep only the most recent entries
        if history.count > maxHistoryEntries {
            history = Array(history.prefix(maxHistoryEntries))
        }
        
        saveHistory()
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([ConnectionHistoryEntry].self, from: data) else {
            history = []
            return
        }
        history = decoded
    }
    
    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(history) else {
            Log.error("Failed to encode connection history")
            return
        }
        UserDefaults.standard.set(encoded, forKey: historyKey)
    }
}

