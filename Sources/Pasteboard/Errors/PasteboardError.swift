//
//  PasteboardError.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  What can go wrong writing to the pasteboard.
//

import Foundation

/// What can go wrong writing to the pasteboard.
public enum PasteboardError: Error, CustomStringConvertible, Sendable {
    /// The data offered as an image is not one AppKit can decode.
    case notAnImage
    /// The message for people.
    public var description: String {
        switch self {
        case .notAnImage: return "the data is not an image AppKit can decode"
        }
    }
}
