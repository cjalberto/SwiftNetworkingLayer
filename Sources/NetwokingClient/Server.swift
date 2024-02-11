import Foundation


public struct Server {
    let url: String
    let environment: String
    var mandatoryHeaders: [String: String] = ["accept": "application/json"]
    
    var baseURL: String {
        if !self.environment.isEmpty {
            return "\(self.url)/\(self.environment)/"
        }
        return "\(self.url)/"
    }
    
    fileprivate init(url: String, environment: String, mandatoryHeaders: [String : String]) {
        self.url = url
        self.environment = environment
        self.mandatoryHeaders = self.mandatoryHeaders.merging(mandatoryHeaders) { (_, new) in new }
    }
}

public class ServerFactory {
    public static func createServer(for environment: String, baseURL: String, apiKey: String? = nil, additionalHeaders: [String: String] = [:]) -> Server {
        var headers = additionalHeaders
        
        if let apiKey = apiKey {
            headers["api-key"] = apiKey
        }

        return Server(url: baseURL, environment: environment, mandatoryHeaders: headers)
    }
}
