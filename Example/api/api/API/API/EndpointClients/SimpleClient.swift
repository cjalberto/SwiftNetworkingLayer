//
//  SimpleClient.swift
//
//
//  Created by Carlos Jaramillo on 2/3/24.
//

import Foundation
import NetwokingClient

protocol SimpleClientProtocol {
    func fetchCryptoCurrencyPriceInfo(id: String, vsCurrencies: String) async -> Result<CryptocurrencyPriceInfoDTO, HTTPClientError>
}

public struct SimpleClient: EndpointClient  {
    public var provider: Networking<HTTPClientError>
    
    public struct Price: Endpoint {
        public var body: Data?
        
        public typealias requestType = CryptocurrencyPriceInfoDTO
        
        public var method: HTTPMethod { .get }
        public var path: String {
            var path = "simple/price?ids=\(id)&vs_currencies=\(vsCurrencies)"
            if !(options ?? [:]).isEmpty {
                path += "&" + queryString(from: options!)
            }
            return path
        }
        
        public let id: String
        public let vsCurrencies: String
        public let options: [String: Any]?
        
        internal init(id: String, vsCurrencies: String, options: [String : Any]? = nil, body: Data? = nil) {
            self.id = id
            self.vsCurrencies = vsCurrencies
            self.options = options
        }
    }
}

extension SimpleClient: SimpleClientProtocol {
    func fetchCryptoCurrencyPriceInfo(id: String, vsCurrencies: String) async -> Result<CryptocurrencyPriceInfoDTO, HTTPClientError> {
        let result = await self.request(endpoint: SimpleClient.Price(id: id, vsCurrencies: vsCurrencies))
        return result
    }
}
