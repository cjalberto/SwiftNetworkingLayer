//
//  JSONResponseDecoder.swift
//  NetwokingClient
//
//  Created by Carlos Jaramillo on 12/8/24.
//

import Foundation

public struct JSONResponseDecoder: ResponseDecodable {
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    public func decode<T: Decodable>(_ data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
}
