//
//  CryptoCurrencyBasicDTO.swift
//  CoinMarketApp
//
//  Created by Carlos Jaramillo on 1/8/24.
//

import Foundation

public struct CryptoCurrencyBasicDTO: Codable {
    public let id: String
    public let symbol: String
    public let name: String
}
