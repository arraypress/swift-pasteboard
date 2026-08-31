//
//  ClipType.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  One flavour the pasteboard carries, by UTI and size.
//

import Foundation

/// One flavour the pasteboard carries, with its size.
public struct ClipType: Codable, Sendable, Equatable {
    /// The UTI, as the pasteboard names it — `public.utf8-plain-text`,
    /// `public.png`, `com.apple.finder.noderef`, …
    public let identifier: String
    /// How many bytes that flavour holds.
    public let bytes: Int

    /// A flavour by identifier and size.
    public init(identifier: String, bytes: Int) {
        self.identifier = identifier
        self.bytes = bytes
    }
}
