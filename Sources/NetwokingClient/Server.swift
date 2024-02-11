import Foundation

// Struct to manage server configurations
public struct Server {
    let url: String
    let environment: String
    // Mandatory HTTP headers with default value for JSON content
    var mandatoryHeaders: [String: String] = ["accept": "application/json"]
    
    // Computed property to return the base URL including environment if provided
    var baseURL: String {
        if !self.environment.isEmpty {
            return "\(self.url)/\(self.environment)/"
        }
        return "\(self.url)/"
    }
    
    // Initializer to create Server instance
    fileprivate init(url: String, environment: String, mandatoryHeaders: [String : String]) {
        self.url = url
        self.environment = environment
        // Merge provided mandatory headers with default ones
        self.mandatoryHeaders = self.mandatoryHeaders.merging(mandatoryHeaders) { (_, new) in new }
    }
}

// Class to create Server instances
public class ServerFactory {
    // Static method to create a Server instance
    public static func createServer(for environment: String, baseURL: String, apiKey: String? = nil, additionalHeaders: [String: String] = [:]) -> Server {
        var headers = additionalHeaders
        
        // Add API key to headers if provided
        if let apiKey = apiKey {
            headers["api-key"] = apiKey
        }

        // Return a new Server instance with provided configurations
        return Server(url: baseURL, environment: environment, mandatoryHeaders: headers)
    }
}
