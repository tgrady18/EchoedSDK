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
    
    public func sendEcho(anchorId: String, userTags: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NSError(domain: "NetworkManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company ID not set"])))
            return
        }
        
        let endpoint = baseURL + "sendEcho"
        let parameters: [String: Any] = [
            "companyId": companyId,
            "anchorId": anchorId,
            "userTags": userTags
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
    
    public func fetchMessagesForAnchor(anchorId: String, userTags: [String: Any], completion: @escaping (Result<[Message], Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NSError(domain: "NetworkManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company ID not set"])))
            return
        }

        let endpoint = baseURL + "fetchMessagesForAnchor"
        let parameters: [String: Any] = [
            "companyId": companyId,
            "anchorId": anchorId,
            "userTags": userTags
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
    
    
    public func fetchAnchors(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NSError(domain: "NetworkManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company ID not set"])))
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
    
    public func fetchRuleSets(completion: @escaping (Result<[RuleSet], Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NSError(domain: "NetworkManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company ID not set"])))
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
    
    public func checkUserTags(_ userTags: [String: Any], completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NSError(domain: "NetworkManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company ID not set"])))
            return
        }
        
        let endpoint = baseURL + "checkUserTags"
        var parameters: [String: Any] = ["companyId": companyId]
        parameters.merge(userTags) { (_, new) in new }
        
        makeRequest(to: endpoint, method: "POST", parameters: parameters) { result in
            switch result {
            case .success(let data):
                if let isValid = try? JSONDecoder().decode(Bool.self, from: data) {
                    completion(.success(isValid))
                } else {
                    completion(.failure(NSError(domain: "NetworkManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func fetchMessages(for messageIds: [String], completion: @escaping (Result<[Message], Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NSError(domain: "NetworkManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company ID not set"])))
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
    
    public func sendMessageResponse(messageId: String, response: String, userTags: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let companyId = companyId else {
            completion(.failure(NSError(domain: "NetworkManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company ID not set"])))
            return
        }
        
        let endpoint = baseURL + "sendMessageResponse"
        let parameters: [String: Any] = [
            "companyId": companyId,
            "messageId": messageId,
            "response": response,
            "userTags": userTags
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

    private func makeRequest(to endpoint: String, method: String, parameters: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "NetworkManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey {
            request.addValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NetworkManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
}
