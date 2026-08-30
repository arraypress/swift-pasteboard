//
//  Clip.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  What is on the pasteboard, as a value: every kind it carries, the text
//  and files themselves, an image as PNG with its size, and the raw type
//  list for everything else. A `Clip` is what a read returns and what a
//  watcher yields — the pasteboard's contents at one change count, safe to
//  pass around after the pasteboard has moved on.
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

/// An image from the pasteboard, held as PNG.
///
/// Encodes as its dimensions and size only — a JSON description should say
/// what the image is, not carry two megabytes of base64.
public struct ClipImage: Sendable, Equatable {
    /// The image as PNG bytes, whatever flavour it arrived in.
    public let png: Data
    /// Pixels across.
    public let width: Int
    /// Pixels down.
    public let height: Int
    /// The PNG's size in bytes.
    public let bytes: Int

    /// An image from its PNG bytes and pixel size.
    public init(png: Data, width: Int, height: Int) {
        self.png = png
        self.width = width
        self.height = height
        self.bytes = png.count
    }
}

extension ClipImage: Codable {
    enum CodingKeys: String, CodingKey { case width, height, bytes }

    /// Decodes the description only; the pixels are not carried by JSON.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        png = Data()
        width = try c.decode(Int.self, forKey: .width)
        height = try c.decode(Int.self, forKey: .height)
        bytes = try c.decode(Int.self, forKey: .bytes)
    }
}

/// A colour from the pasteboard, in sRGB.
public struct ClipColor: Codable, Sendable, Equatable {
    /// Red, 0–255.
    public let red: Int
    /// Green, 0–255.
    public let green: Int
    /// Blue, 0–255.
    public let blue: Int
    /// Opacity, 0–1.
    public let alpha: Double
    /// `#RRGGBB`.
    public var hex: String { String(format: "#%02X%02X%02X", red, green, blue) }

    /// A colour from sRGB components.
    public init(red: Int, green: Int, blue: Int, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

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

    /// The text as a URL, when it is one link and nothing else — one token
    /// with a scheme a person means as a link.
    public var url: URL? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              !trimmed.contains(where: \.isWhitespace),
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https", "file", "mailto", "ftp"].contains(scheme)
        else { return nil }
        return url
    }

    /// Whether ``url`` would give a link.
    public var looksLikeURL: Bool { url != nil }

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
