//
//  CacheService.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation
import FirebaseFirestore
import Combine

/// Simple caching service for offline support
final class CacheService {
    
    static let shared = CacheService()
    private init() {
        // Enable Firestore offline persistence (enabled by default but we ensure it)
        let settings = Firestore.firestore().settings
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber) // 100MB
        Firestore.firestore().settings = settings
    }
    
    private let defaults = UserDefaults.standard
    private let cachePrefix = "ezteach_cache_"
    
    // MARK: - User Data Cache
    
    func cacheUserData(_ data: [String: Any], userId: String) {
        if let encoded = try? JSONSerialization.data(withJSONObject: data) {
            defaults.set(encoded, forKey: "\(cachePrefix)user_\(userId)")
            defaults.set(Date(), forKey: "\(cachePrefix)user_\(userId)_timestamp")
        }
    }
    
    func getCachedUserData(userId: String) -> [String: Any]? {
        guard let data = defaults.data(forKey: "\(cachePrefix)user_\(userId)"),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
    
    func isCacheValid(for key: String, maxAge: TimeInterval = 3600) -> Bool {
        guard let timestamp = defaults.object(forKey: "\(cachePrefix)\(key)_timestamp") as? Date else {
            return false
        }
        return Date().timeIntervalSince(timestamp) < maxAge
    }
    
    // MARK: - School Data Cache
    
    func cacheSchoolData(_ data: [String: Any], schoolId: String) {
        if let encoded = try? JSONSerialization.data(withJSONObject: data) {
            defaults.set(encoded, forKey: "\(cachePrefix)school_\(schoolId)")
            defaults.set(Date(), forKey: "\(cachePrefix)school_\(schoolId)_timestamp")
        }
    }
    
    func getCachedSchoolData(schoolId: String) -> [String: Any]? {
        guard let data = defaults.data(forKey: "\(cachePrefix)school_\(schoolId)"),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
    
    // MARK: - Announcements Cache
    
    func cacheAnnouncements(_ announcements: [[String: Any]], schoolId: String) {
        if let encoded = try? JSONSerialization.data(withJSONObject: announcements) {
            defaults.set(encoded, forKey: "\(cachePrefix)announcements_\(schoolId)")
            defaults.set(Date(), forKey: "\(cachePrefix)announcements_\(schoolId)_timestamp")
        }
    }
    
    func getCachedAnnouncements(schoolId: String) -> [[String: Any]]? {
        guard let data = defaults.data(forKey: "\(cachePrefix)announcements_\(schoolId)"),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        return array
    }
    
    // MARK: - Events Cache
    
    func cacheEvents(_ events: [[String: Any]], schoolId: String) {
        if let encoded = try? JSONSerialization.data(withJSONObject: events) {
            defaults.set(encoded, forKey: "\(cachePrefix)events_\(schoolId)")
            defaults.set(Date(), forKey: "\(cachePrefix)events_\(schoolId)_timestamp")
        }
    }
    
    func getCachedEvents(schoolId: String) -> [[String: Any]]? {
        guard let data = defaults.data(forKey: "\(cachePrefix)events_\(schoolId)"),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        return array
    }
    
    // MARK: - Teachers Cache
    
    func cacheTeachers(_ teachers: [[String: Any]], schoolId: String) {
        if let encoded = try? JSONSerialization.data(withJSONObject: teachers) {
            defaults.set(encoded, forKey: "\(cachePrefix)teachers_\(schoolId)")
            defaults.set(Date(), forKey: "\(cachePrefix)teachers_\(schoolId)_timestamp")
        }
    }
    
    func getCachedTeachers(schoolId: String) -> [[String: Any]]? {
        guard let data = defaults.data(forKey: "\(cachePrefix)teachers_\(schoolId)"),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        return array
    }
    
    // MARK: - Clear Cache
    
    func clearAllCache() {
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(cachePrefix) }
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
    
    func clearSchoolCache(schoolId: String) {
        let keysToRemove = [
            "\(cachePrefix)school_\(schoolId)",
            "\(cachePrefix)announcements_\(schoolId)",
            "\(cachePrefix)events_\(schoolId)",
            "\(cachePrefix)teachers_\(schoolId)"
        ]
        keysToRemove.forEach { key in
            defaults.removeObject(forKey: key)
            defaults.removeObject(forKey: "\(key)_timestamp")
        }
    }
    
    // MARK: - Pending Operations (for offline writes)
    
    struct PendingOperation: Codable {
        let id: String
        let collection: String
        let documentId: String?
        let operation: String // "create", "update", "delete"
        let data: [String: String]
        let timestamp: Date
    }
    
    func queuePendingOperation(_ operation: PendingOperation) {
        var pending = getPendingOperations()
        pending.append(operation)
        
        if let encoded = try? JSONEncoder().encode(pending) {
            defaults.set(encoded, forKey: "\(cachePrefix)pending_operations")
        }
    }
    
    func getPendingOperations() -> [PendingOperation] {
        guard let data = defaults.data(forKey: "\(cachePrefix)pending_operations"),
              let operations = try? JSONDecoder().decode([PendingOperation].self, from: data) else {
            return []
        }
        return operations
    }
    
    func removePendingOperation(_ id: String) {
        var pending = getPendingOperations()
        pending.removeAll { $0.id == id }
        
        if let encoded = try? JSONEncoder().encode(pending) {
            defaults.set(encoded, forKey: "\(cachePrefix)pending_operations")
        }
    }
    
    func clearPendingOperations() {
        defaults.removeObject(forKey: "\(cachePrefix)pending_operations")
    }
}

// MARK: - Network Monitor
import Network

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
}
