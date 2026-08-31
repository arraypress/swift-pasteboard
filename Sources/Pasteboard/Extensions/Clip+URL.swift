//
//  Clip+URL.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  The clip's one derived reading: its text as a link. The rule itself
//  lives in Support/URLDetection; this only delegates.
//

import Foundation

extension Clip {

    /// The text as a URL, when it is one link and nothing else — one token
    /// with a scheme a person means as a link.
    public var url: URL? { URLDetection.url(from: text) }

    /// Whether ``url`` would give a link.
    public var looksLikeURL: Bool { url != nil }
}
