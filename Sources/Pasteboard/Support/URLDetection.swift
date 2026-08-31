//
//  URLDetection.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  When copied text is a link. The rule is deliberately narrow — one
//  token, a scheme a person means as a link — and it lives here as a
//  pure function so the narrowness is pinned by tests directly, not
//  through a pasteboard.
//

import Foundation

/// Deciding whether text is one link and nothing else.
enum URLDetection {

    /// The schemes a person plausibly means as a clickable link.
    static let schemes: Set<String> = ["http", "https", "file", "mailto", "ftp"]

    /// The text as a URL, when it is one whitespace-free token carrying
    /// one of the accepted schemes; `nil` for prose, bare domains and
    /// anything else.
    static func url(from text: String?) -> URL? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              !trimmed.contains(where: \.isWhitespace),
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              schemes.contains(scheme)
        else { return nil }
        return url
    }
}
