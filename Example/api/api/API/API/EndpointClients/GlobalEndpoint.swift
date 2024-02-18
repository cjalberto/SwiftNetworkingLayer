//
//  GlobalEndpoint.swift
//  
//
//  Created by Carlos Jaramillo on 2/4/24.
//

import Foundation
import NetwokingClient

@available(macOS 12.0, *)
extension API {
    private struct GlobalEndpoint: EndpointClient  {
        internal var provider: Networking<HTTPClientError>
        
        public struct Global: Endpoint {
            public var body: Data?
            
            public typealias requestType = CryptoCurrencyGlobalInfoDTO
            
            internal init(body: Data? = nil){}
            
            public var method: HTTPMethod { .get }
            public var path: String {
                return "global"
            }
        }
    }
    
    public func fetchGlobalCryptoCurrencies() async -> Result<CryptoCurrencyGlobalInfoDTO, HTTPClientError> {
        let result = await GlobalEndpoint(provider: provider).request(endpoint: GlobalEndpoint.Global())
        return result
    }
}


