//
//  Enviroment.swift
//  api
//
//  Created by Carlos Jaramillo on 2/11/24.
//

import Foundation

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
