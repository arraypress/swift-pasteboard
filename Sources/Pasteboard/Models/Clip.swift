//
//  Clip.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  The pasteboard's contents at one moment: every kind present, most
//  specific first, and the raw type list for everything uninterpreted.
//

import Foundation

/// The pasteboard's contents at one moment.
public struct Clip: Codable, Sendable, Equatable {

    /// The broad kinds a clip can carry.
    public enum Kind: String, Codable, Sendable {
        case text
        case richText = "rich-text"
        case image
        case files
        case color
        /// Types the library does not interpret; see ``Clip/types``.
        case other
    }

    /// Everything present, most specific first: files before the image
    /// Finder also puts up, the image before its text fallback.
    public let kinds: [Kind]
    /// The plain text, if any.
    public let text: String?
    /// Whether an HTML flavour is present.
    public let hasHTML: Bool
    /// Whether an RTF flavour is present.
    public let hasRTF: Bool
    /// The HTML itself, when present.
    public let html: String?
    /// The image, when present, as PNG.
    public let image: ClipImage?
    /// File paths, when the clip is copied files.
    public let files: [String]
    /// The colour, when the clip is a colour.
    public let color: ClipColor?
    /// Every flavour on the pasteboard, with sizes — including the ones the
    /// library does not interpret.
    public let types: [ClipType]
    /// The pasteboard's change count when this clip was read.
    public let changeCount: Int

    /// What the clip most is; `nil` when the pasteboard is empty.
    public var primary: Kind? { kinds.first }

    /// Whether nothing readable is present.
    public var isEmpty: Bool { kinds.isEmpty && types.isEmpty }

    /// The files as URLs.
    public var fileURLs: [URL] { files.map { URL(fileURLWithPath: $0) } }

    /// A clip assembled field by field — reads come from
    /// ``Pasteboard/read()``; this is for tests and previews.
    public init(kinds: [Kind], text: String? = nil, hasHTML: Bool = false, hasRTF: Bool = false,
                html: String? = nil, image: ClipImage? = nil, files: [String] = [],
                color: ClipColor? = nil, types: [ClipType] = [], changeCount: Int = 0) {
        self.kinds = kinds
        self.text = text
        self.hasHTML = hasHTML
        self.hasRTF = hasRTF
        self.html = html
        self.image = image
        self.files = files
        self.color = color
        self.types = types
        self.changeCount = changeCount
    }
}
