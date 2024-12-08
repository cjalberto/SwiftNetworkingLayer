//
//  XMLResponseDecoder.swift
//  NetwokingClient
//
//  Created by Carlos Jaramillo on 12/8/24.
//

import Foundation

public struct XMLResponseDecoder: ResponseDecodable {
    public init() {}
    
    public func decode<T: Decodable>(_ data: Data) throws -> T {
        let parser = XMLParser(data: data)
        let xmlDecoder = XMLDecoder<T>()
        parser.delegate = xmlDecoder
        
        if parser.parse() {
            if let result = xmlDecoder.decodedObject {
                return result
            } else {
                throw NSError(domain: "XMLDecoderError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode XML data."])
            }
        } else {
            throw parser.parserError ?? NSError(domain: "XMLParserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse XML data."])
        }
    }
}

class XMLDecoder<T: Decodable>: NSObject, XMLParserDelegate {
    private var currentElement: String = ""
    private var currentValue: String = ""
    private var dictionary: [String: String] = [:]
    private let decoder = JSONDecoder()
    var decodedObject: T?
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if currentElement == elementName {
            dictionary[elementName] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            currentValue = ""
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            decodedObject = try decoder.decode(T.self, from: jsonData)
        } catch {
            print("Error decoding XML to JSON: \(error)")
        }
    }
}
