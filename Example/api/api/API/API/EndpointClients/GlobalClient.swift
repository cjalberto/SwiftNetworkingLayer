//
//  GlobalClient.swift
//
//
//  Created by Carlos Jaramillo on 2/4/24.
//

import Foundation
import NetwokingClient

protocol GlobalClientProtocol {
    func fetchGlobalCryptoCurrencies() async -> Result<CryptoCurrencyGlobalInfoDTO, HTTPClientError>
}

public struct GlobalClient: EndpointClient  {
    public var provider: Networking<HTTPClientError>
    
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

extension GlobalClient: GlobalClientProtocol {
    func fetchGlobalCryptoCurrencies() async -> Result<CryptoCurrencyGlobalInfoDTO, HTTPClientError> {
        let result = await self.request(endpoint: GlobalClient.Global())
        return result
    }
}


