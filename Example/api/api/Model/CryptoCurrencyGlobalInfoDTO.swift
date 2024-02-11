//
//  CryptoCurrencyGlobalInfoDTO.swift
//  CoinMarketApp
//
//  Created by Carlos Jaramillo on 1/13/24.
//

import Foundation

public struct CryptoCurrencyGlobalInfoDTO: Codable {
    public let data: CryptoCurrencyGlobalInfoDataDTO
    
    public struct CryptoCurrencyGlobalInfoDataDTO: Codable {
        public let activeCryptocurrencies: Int
        public let upcomingIcos: Int
        public let ongoingIcos: Int
        public let endedIcos: Int
        public let markets: Int
        public let totalMarketCap: [String: Double]
        public let totalVolume: [String: Double]
        public let marketCapPercentage: [String: Double]
        public let marketCapChangePercentage24hUsd: Double
        public let updatedAt: Int
        
        enum CodingKeys: String, CodingKey {
            case activeCryptocurrencies = "active_cryptocurrencies"
            case upcomingIcos = "upcoming_icos"
            case ongoingIcos = "ongoing_icos"
            case endedIcos = "ended_icos"
            case markets
            case totalMarketCap = "total_market_cap"
            case totalVolume = "total_volume"
            case marketCapPercentage = "market_cap_percentage"
            case marketCapChangePercentage24hUsd = "market_cap_change_percentage_24h_usd"
            case updatedAt = "updated_at"
        }
    }
}


