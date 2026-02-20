//
//  Message.swift
//  Echoed
//
//  Created by Trevor (personal) on 2024-10-12.
//

import Foundation

public struct Message: Codable, Identifiable {
    public let id: String
    let anchorId: String
    let type: MessageType
    let title: String
    let content: String
    let options: [String]? // Optional
}

public enum TagType: String, Codable {
    case number
    case string
    case timestamp
    case boolean
}

public enum MessageType: String, Codable {
    case multiChoice
    case textInput
    case yesNo
    case thumbsUpDown
}


public struct TagCondition: Codable {
    let key: String
    let operation: ComparisonOperation
    let value: AnyCodable
}

public enum ComparisonOperation: String, Codable {
    case equals
    case notEquals
    case greaterThan
    case lessThan
    case contains
    case notContains
}

public struct RuleSet: Codable {
    let id: String
    let name: String
    let conditions: [TagCondition]
    let messageIds: [String]
}

// This helper struct allows us to encode/decode Any types
public struct AnyCodable: Codable {
    public let value: Any
       
       public init(_ value: Any) {
           self.value = value
       }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictionaryValue as [String: Any]:
            try container.encode(dictionaryValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}
