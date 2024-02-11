//
//  CoinsEndpoint.swift
//  
//
//  Created by Carlos Jaramillo on 2/4/24.
//

import Foundation
import NetwokingClient

@available(macOS 12.0, *)
extension API {
    private struct CoinsEndpoint: EndpointClient  {
        internal var provider: Networking
        
        public struct List: Endpoint {
            public var body: Data?
            
            public typealias requestType = [CryptoCurrencyBasicDTO]
            
            internal init(data: Data? = nil){}
            
            public var method: HTTPMethod { .get }
            public var path: String {
                return "coins/list"
            }
        }
    }
    
    public func fetchCryptoCurrencyBasicInfo() async -> Result<[CryptoCurrencyBasicDTO], HTTPClientError> {
        let result = await CoinsEndpoint(provider: provider).request(endpoint: CoinsEndpoint.List())
        return result
    }
}
