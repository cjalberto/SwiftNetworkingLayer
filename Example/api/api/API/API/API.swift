//
//  API.swift
//  api
//
//  Created by Carlos Jaramillo on 2/11/24.
//

import Foundation
import NetwokingClient


@available(macOS 10.13, *)
public protocol APIClient {
    var provider: Networking { get }
    
    //Global
    func fetchGlobalCryptoCurrencies() async -> Result<CryptoCurrencyGlobalInfoDTO, HTTPClientError>
    
    //Simple
    func fetchCryptoCurrencyPriceInfo(id: String, vsCurrencies: String) async -> Result<CryptocurrencyPriceInfoDTO, HTTPClientError>
    
    //Coins
    func fetchCryptoCurrencyBasicInfo() async -> Result<[CryptoCurrencyBasicDTO], HTTPClientError>
}


@available(macOS 12.0, *)
public struct API: APIClient {
    public var provider: Networking
    static var shared: API = API(provider: Networking(provider: ServerFactory.createServer(for: Environment.production.path, baseURL: BaseURL.network(version: "v3").description)))
    
    public init(provider: Networking) {
        self.provider = provider
    }
}
