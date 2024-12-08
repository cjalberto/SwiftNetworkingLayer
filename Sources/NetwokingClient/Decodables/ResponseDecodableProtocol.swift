//
//  ResponseDecodable.swift
//  NetwokingClient
//
//  Created by Carlos Jaramillo on 12/8/24.
//

import Foundation

public protocol ResponseDecodable {
    func decode<T: Decodable>(_ data: Data) throws -> T
}
