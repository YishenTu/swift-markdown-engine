//
//  MarkdownTextMutationTests.swift
//  MarkdownEngineTests
//
//  Exact native edit descriptors for embedders that maintain their own
//  source authority or mirror an edit into another presentation.
//

import AppKit
import SwiftUI
import Testing
@testable import MarkdownEngine

@MainActor
@Suite("Markdown text mutation callback")
struct MarkdownTextMutationTests {

    private func makeEditor(
        _ text: String,
        onTextMutation: @escaping (MarkdownTextMutation) -> Void
    ) -> NativeTextView {
        _ = NSApplication.shared
        let wrapper = NativeTextViewWrapper(
            text: .constant(text),
            fontName: "SF Pro",
            fontSize: 16,
            onTextMutation: onTextMutation
        )
        let coordinator = wrapper.makeCoordinator()
        let textView = NativeTextView(
            frame: NSRect(x: 0, y: 0, width: 600, height: 400)
        )
        textView.isEditable = true
        textView.delegate = coordinator
        coordinator.textView = textView
        coordinator.rebuildTextStorageAndStyle(textView, from: text)
        coordinator.lastSyncedText = text
        coordinator.lastComputedStorage = text
        coordinator.previousDisplayLength = (text as NSString).length
        return textView
    }

    @Test("reports the exact accepted UTF-16 replacement")
    func reportsExactAcceptedReplacement() {
        var received: [MarkdownTextMutation] = []
        let textView = makeEditor("- [x] **fast** item") {
            received.append($0)
        }

        textView.insertText(
            "0",
            replacementRange: NSRange(location: 12, length: 0)
        )

        #expect(textView.string == "- [x] **fast0** item")
        #expect(
            received == [
                MarkdownTextMutation(
                    range: NSRange(location: 12, length: 0),
                    replacement: "0"
                )
            ]
        )
    }

    @Test("a proposed edit alone emits no completed mutation")
    func proposedEditDoesNotEmitMutation() throws {
        var received: [MarkdownTextMutation] = []
        let textView = makeEditor("alpha") {
            received.append($0)
        }
        let coordinator = try #require(
            textView.delegate as? NativeTextViewCoordinator
        )

        #expect(
            coordinator.textView(
                textView,
                shouldChangeTextIn: NSRange(location: 5, length: 0),
                replacementString: "x"
            )
        )
        #expect(received.isEmpty)
    }
}
