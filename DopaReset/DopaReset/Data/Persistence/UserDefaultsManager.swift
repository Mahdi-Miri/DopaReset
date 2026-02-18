// UserDefaultsManager.swift
// Type-safe wrapper around UserDefaults with Codable support

import Foundation

final class UserDefaultsManager {

    static let shared = UserDefaultsManager()

    // Use app group so extension can also read/write
    private let defaults: UserDefaults

    private init() {
        // Falls back to standard if app group isn't set up yet
        self.defaults = UserDefaults(suiteName: "group.com.doparest.shared") ?? .standard
    }

    // MARK: - Generic read / write

    func set<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    func get<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func setBool(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func getBool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
