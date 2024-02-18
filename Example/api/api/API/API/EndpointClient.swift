//
//  EndpointClient.swift
//  
//
//  Created by Carlos Jaramillo on 2/10/24.
//

import Foundation
import Combine
import NetwokingClient


public protocol EndpointClient {
    var provider: Networking<HTTPClientError> { get }
    
    @available(macOS 10.15, *)
    func request<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.requestType, HTTPClientError>) -> ())
    
    @available(macOS 10.15, *)
    func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, HTTPClientError>
    
    @available(macOS 12.0, *)
    func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, HTTPClientError>
}

extension EndpointClient {
    @available(macOS 10.15, *)
    public func request<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.requestType, HTTPClientError>) -> ()) {
        self.provider.request(endpoint: endpoint, completion: completion)
    }
    
    @available(macOS 10.15, *)
    public func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, HTTPClientError> {
        self.provider.request(endpoint: endpoint)
    }
    
    @available(macOS 12.0, *)
    public func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, HTTPClientError> {
        await self.provider.request(endpoint: endpoint)
    }
}
