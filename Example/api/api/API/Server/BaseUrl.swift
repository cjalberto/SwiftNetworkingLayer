import Foundation


public enum BaseURL {
    case network(version: String)
    case local(version: String)
    case custom(url: String)
}

extension BaseURL: CustomStringConvertible {
    public var description: String {
        switch self {
        case .network(let version):
            return  version.isEmpty ? "https://api.coingecko.com/api" : "https://api.coingecko.com/api/\(version)"
        case .local(let version):
            return version.isEmpty ? "http://localhost:3000/api" : "http://localhost:3000/api/\(version)"
        case .custom(let url):
            return url
        }
    }
}
