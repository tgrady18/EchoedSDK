import Foundation
import os

public class EchoedSDK {
    public static let shared = EchoedSDK()
    static let logger = Logger(subsystem: "com.echoed.sdk", category: "Echoed")

    let networkManager: NetworkManager
    let userTagManager: UserTagManager
    let deviceManager: DeviceManager
    private let messageManager: MessageManager

    public var deviceId: String { deviceManager.getDeviceId() }

    /// The current customer ID, if set via `setCustomer(id:)`.
    public var customerId: String? { userTagManager.getCustomerId() }

    private init() {
        networkManager = NetworkManager()
        userTagManager = UserTagManager()
        deviceManager = DeviceManager()
        messageManager = MessageManager()
    }

    public func initialize(apiKey: String, companyId: String) {
        guard !apiKey.isEmpty, !companyId.isEmpty else {
            Self.logger.error("initialize() called with empty apiKey or companyId")
            return
        }
        networkManager.initialize(withApiKey: apiKey, companyId: companyId)
    }

    // MARK: - Anchor Methods
    public func hitAnchor(_ anchorId: String) {
        // Record anchor hit to the backend
        networkManager.recordAnchorHit(anchorId: anchorId) { result in
            switch result {
            case .success:
                Self.logger.debug("Anchor hit recorded successfully")
            case .failure(let error):
                Self.logger.error("Error recording anchor hit: \(error.localizedDescription)")
            }
        }

        // Fetch messages for this anchor
        networkManager.fetchMessagesForAnchor(anchorId: anchorId, userTags: userTagManager) { [weak self] result in
            switch result {
            case .success(let messages):
                DispatchQueue.main.async {
                    self?.messageManager.present(messages: messages)
                }
            case .failure(let error):
                Self.logger.error("Error fetching messages: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Customer Methods

    /// Sets customer identity. All parameters are optional. Persisted across sessions.
    /// Call this when your user logs in or you know who they are.
    public func setCustomer(id: String? = nil, name: String? = nil, email: String? = nil) {
        if let id = id {
            userTagManager.setCustomerTag("echoed_customer_id", value: id, type: .string)
        }
        if let name = name {
            userTagManager.setCustomerTag("echoed_customer_name", value: name, type: .string)
        }
        if let email = email {
            userTagManager.setCustomerTag("echoed_customer_email", value: email, type: .string)
        }

        // Sync with backend
        networkManager.syncTags(userTags: userTagManager) { result in
            switch result {
            case .success:
                Self.logger.debug("Customer info synced with Firebase")
            case .failure(let error):
                Self.logger.error("Error syncing customer info: \(error.localizedDescription)")
            }
        }
    }

    /// Clears customer identity. Internal and user tags are preserved.
    /// Call this when your user logs out.
    public func resetCustomer() {
        userTagManager.clearCustomerTags()

        networkManager.syncTags(userTags: userTagManager) { result in
            switch result {
            case .success:
                Self.logger.debug("Customer reset synced with Firebase")
            case .failure(let error):
                Self.logger.error("Error syncing customer reset: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - User Tag Methods
    public func setUserTag(_ key: String, value: Any, type: TagType) {
        guard !userTagManager.isReservedKey(key) else {
            Self.logger.warning("Cannot set tag with reserved 'echoed_' prefix: \(key)")
            return
        }

        // Set locally
        userTagManager.setTag(key, value: value, type: type, category: .user)

        // Sync with Firebase
        networkManager.syncTags(userTags: userTagManager) { result in
            switch result {
            case .success:
                Self.logger.debug("Tags synced with Firebase successfully")
            case .failure(let error):
                Self.logger.error("Error syncing tags with Firebase: \(error.localizedDescription)")
            }
        }
    }

    public func getUserTagValue(_ key: String) -> Any? {
        return userTagManager.getTagValue(key)
    }

    public func getUserTagType(_ key: String) -> TagType? {
        return userTagManager.getTagType(key)
    }

    public func getAllUserTags() -> [String: Any] {
        return userTagManager.getAllTagsForNetwork()
    }

    public func removeUserTag(_ key: String) {
        userTagManager.removeTag(key)
        // Sync removal with Firebase
        networkManager.syncTags(userTags: userTagManager) { result in
            switch result {
            case .success:
                Self.logger.debug("Tag removal synced with Firebase successfully")
            case .failure(let error):
                Self.logger.error("Error syncing tag removal with Firebase: \(error.localizedDescription)")
            }
        }
    }

    public func clearAllUserTags() {
        userTagManager.clearAllTags()
        // Sync cleared tags with Firebase
        networkManager.syncTags(userTags: userTagManager) { result in
            switch result {
            case .success:
                Self.logger.debug("Cleared tags synced with Firebase successfully")
            case .failure(let error):
                Self.logger.error("Error syncing cleared tags with Firebase: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Debug Methods
    public func printAllTags() {
        userTagManager.printAllTags()
    }

    // MARK: - Error Types
    public enum SDKError: Error {
        case notInitialized
        case invalidTagType
        case tagValidationFailed
        case networkError(Error)

        var localizedDescription: String {
            switch self {
            case .notInitialized:
                return "SDK not properly initialized. Call initialize first."
            case .invalidTagType:
                return "Invalid tag type provided."
            case .tagValidationFailed:
                return "Tag validation failed. Check value type matches tag type."
            case .networkError(let error):
                return "Network error: \(error)"
            }
        }
    }
}
