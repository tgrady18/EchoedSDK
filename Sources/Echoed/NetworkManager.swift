import Foundation

struct FetchMessagesResponse: Codable {
    let messages: [Message]
}

public class NetworkManager {
    private let baseURL = "https://us-central1-echoed-ccedb.cloudfunctions.net/"
    private var apiKey: String?
    private var companyId: String?
    
    public func initialize(withApiKey apiKey: String, companyId: String) {
        self.apiKey = apiKey
        self.companyId = companyId
    }
    
    // MARK: - Tag Definitions
    public func fetchTagDefinitions(completion: @escaping (Result<[TagDefinition], Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NetworkError.companyIdNotSet))
            return
        }
        
        let endpoint = baseURL + "fetchTags"
        let parameters = ["companyId": companyId]
        
        makeRequest(to: endpoint, method: "GET", parameters: parameters) { result in
            switch result {
            case .success(let data):
                do {
                    let tagDefinitions = try JSONDecoder().decode([TagDefinition].self, from: data)
                    completion(.success(tagDefinitions))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Echo Methods
    public func sendEcho(anchorId: String, userTags: UserTagManager, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NetworkError.companyIdNotSet))
            return
        }
        
        let endpoint = baseURL + "sendEcho"
        let parameters: [String: Any] = [
            "companyId": companyId,
            "anchorId": anchorId,
            "userTags": userTags.getAllTagsForNetwork()
        ]
        
        makeRequest(to: endpoint, method: "POST", parameters: parameters) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func fetchMessagesForAnchor(anchorId: String, userTags: UserTagManager, completion: @escaping (Result<[Message], Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NetworkError.companyIdNotSet))
            return
        }

        let endpoint = baseURL + "fetchMessagesForAnchor"
        let parameters: [String: Any] = [
            "companyId": companyId,
            "anchorId": anchorId,
            "userTags": userTags.getAllTagsForNetwork()
        ]

        makeRequest(to: endpoint, method: "POST", parameters: parameters) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(FetchMessagesResponse.self, from: data)
                    completion(.success(response.messages))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Anchor Methods
    public func fetchAnchors(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NetworkError.companyIdNotSet))
            return
        }
        
        let endpoint = baseURL + "fetchAnchors"
        let parameters = ["companyId": companyId]
        
        makeRequest(to: endpoint, method: "GET", parameters: parameters) { result in
            switch result {
            case .success(let data):
                do {
                    let anchors = try JSONDecoder().decode([String].self, from: data)
                    completion(.success(anchors))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func recordAnchorHit(anchorId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NetworkError.companyIdNotSet))
            return
        }
        
        let endpoint = baseURL + "recordAnchorHit"
        let parameters: [String: Any] = [
            "companyId": companyId,
            "anchorId": anchorId
        ]
        
        makeRequest(to: endpoint, method: "POST", parameters: parameters) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Message Methods
    public func fetchRuleSets(completion: @escaping (Result<[RuleSet], Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NetworkError.companyIdNotSet))
            return
        }
        
        let endpoint = baseURL + "fetchRuleSets"
        let parameters = ["companyId": companyId]
        
        makeRequest(to: endpoint, method: "GET", parameters: parameters) { result in
            switch result {
            case .success(let data):
                do {
                    let ruleSets = try JSONDecoder().decode([RuleSet].self, from: data)
                    completion(.success(ruleSets))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func fetchMessages(for messageIds: [String], completion: @escaping (Result<[Message], Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NetworkError.companyIdNotSet))
            return
        }
        
        let endpoint = baseURL + "fetchMessages"
        let parameters: [String: Any] = [
            "companyId": companyId,
            "messageIds": messageIds
        ]
        
        makeRequest(to: endpoint, method: "POST", parameters: parameters) { result in
            switch result {
            case .success(let data):
                do {
                    let messages = try JSONDecoder().decode([Message].self, from: data)
                    completion(.success(messages))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func sendMessageResponse(messageId: String, response: String, userTags: UserTagManager, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NetworkError.companyIdNotSet))
            return
        }
        
        let endpoint = baseURL + "sendMessageResponse"
        let parameters: [String: Any] = [
            "companyId": companyId,
            "messageId": messageId,
            "response": response,
            "userTags": userTags.getAllTagsForNetwork()
        ]
        
        makeRequest(to: endpoint, method: "POST", parameters: parameters) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Models
    public struct TagDefinition: Codable {
        public let tag_id: String
        public let data_type: UserTagManager.TagType
        public let first_seen: Date
        public let last_seen: Date
        public let available_operations: [String]
        
        enum CodingKeys: String, CodingKey {
            case tag_id
            case data_type
            case first_seen
            case last_seen
            case available_operations
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            tag_id = try container.decode(String.self, forKey: .tag_id)
            data_type = try container.decode(UserTagManager.TagType.self, forKey: .data_type)
            
            // Convert Firebase Timestamp to Date
            let firstSeenTimestamp = try container.decode(Double.self, forKey: .first_seen)
            first_seen = Date(timeIntervalSince1970: firstSeenTimestamp)
            
            let lastSeenTimestamp = try container.decode(Double.self, forKey: .last_seen)
            last_seen = Date(timeIntervalSince1970: lastSeenTimestamp)
            
            available_operations = try container.decode([String].self, forKey: .available_operations)
        }
    }
    
    public enum NetworkError: Error {
        case companyIdNotSet
        case invalidURL
        case noDataReceived
        case invalidResponseFormat
    }

    // MARK: - Network Request Helper
    private func makeRequest(to endpoint: String, method: String, parameters: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey {
            request.addValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        
        if method == "POST" {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            } catch {
                completion(.failure(error))
                return
            }
        } else if method == "GET" && !parameters.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            if let url = components?.url {
                request.url = url
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noDataReceived))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
}
