//
//  KindOrdering.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  Which kinds a clip is, most specific first — pure decision, testable
//  without a pasteboard in the room: copied files also put up an icon
//  and a path string, and an image often carries a text fallback.
//

import Foundation

/// Orders a clip's kinds, most specific first.
enum KindOrdering {

    /// The kinds present, in the order a consumer should prefer them.
    /// `.other` appears only when nothing readable is present but raw
    /// types are — an empty pasteboard stays empty.
    static func kinds(hasFiles: Bool, hasImage: Bool, hasText: Bool,
                      hasRich: Bool, hasColor: Bool, hasOtherTypes: Bool) -> [Clip.Kind] {
        var kinds: [Clip.Kind] = []
        if hasFiles { kinds.append(.files) }
        if hasImage { kinds.append(.image) }
        if hasText { kinds.append(.text) }
        if hasRich { kinds.append(.richText) }
        if hasColor { kinds.append(.color) }
        if kinds.isEmpty && hasOtherTypes { kinds.append(.other) }
        return kinds
    }
}
