import Foundation

/// The deployment environment used to build the server's environment path segment.
enum Environment {
    case development
    case staging
    case production
    case custom(String)
    
    var path: String {
        switch self {
        case .development:
            return "qa"
        case .staging:
            return "staging"
        case .production:
            return ""
        case .custom(let customBaseURL):
            return customBaseURL
        }
    }
}
