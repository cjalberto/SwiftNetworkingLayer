//
//  JSONEndpointBase.swift
//  NetwokingClient
//
//  Created by Carlos Jaramillo on 12/8/24.
//

import Foundation

public protocol JSONEndpointBase: Endpoint {
    var headers: [String: String]? { get }
    var decoder: ResponseDecodable { get }
}

extension JSONEndpointBase {
    private var defaultHeader: [String: String] {
        return ["Content-Type": "application/json"]
    }

    private var storedHeadersKey: String { "JSONEndpointBaseHeaders" }

    public var headers: [String: String]? {
        get {
            // Recuperar los encabezados almacenados y fusionarlos con los predeterminados
            var combinedHeaders = defaultHeader
            if let storedHeaders = objc_getAssociatedObject(self, storedHeadersKey) as? [String: String] {
                combinedHeaders.merge(storedHeaders) { (_, new) in new }
            }
            return combinedHeaders
        }
        set {
            // Guardar los nuevos encabezados, asegurando que no sobrescriban los predeterminados
            var newHeaders = newValue ?? [:]
            newHeaders.merge(defaultHeader) { (_, defaultValue) in defaultValue }

            objc_setAssociatedObject(self, storedHeadersKey, newHeaders, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var decoder: ResponseDecodable {
        return JSONResponseDecoder()
    }
}
