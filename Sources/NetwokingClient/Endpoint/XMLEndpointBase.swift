//
//  XMLEndpointBase.swift
//  NetwokingClient
//
//  Created by Carlos Jaramillo on 12/8/24.
//

import Foundation

public protocol XMLEndpointBase: Endpoint {
    var headers: [String: String]? { get }
    var decoder: XMLResponseDecoder { get }
}

extension XMLEndpointBase {
    private var defaultHeader: [String: String] {
        return ["Content-Type": "application/xml"]
    }

    private var storedHeadersKey: String { "XMLEndpointBaseHeaders" }

    public var headers: [String: String]? {
        get {
            var combinedHeaders = defaultHeader
            if let storedHeaders = objc_getAssociatedObject(self, storedHeadersKey) as? [String: String] {
                combinedHeaders.merge(storedHeaders) { (_, new) in new }
            }
            return combinedHeaders
        }
        set {
            var newHeaders = newValue ?? [:]
            newHeaders.merge(defaultHeader) { (_, defaultValue) in defaultValue }

            objc_setAssociatedObject(self, storedHeadersKey, newHeaders, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    

    public var decoder: ResponseDecodable {
        return XMLResponseDecoder()
    }
}
