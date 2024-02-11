//
//  CryptoCurrencyPriceInfoDTO.swift
//  CoinMarketApp
//
//  Created by Carlos Jaramillo on 1/8/24.
//

import Foundation

public struct CryptocurrencyPriceInfoDTO: Codable {
    public let price: Double
    public let marketCap: Double
    public let volume24h: Double
    public let price24h: Double
    
    enum CodingKeys: String, CodingKey {
        case price = "usd"
        case marketCap = "usd_market_cap"
        case volume24h = "usd_24h_vo1"
        case price24h = "usd_24h_change"
    }
}

