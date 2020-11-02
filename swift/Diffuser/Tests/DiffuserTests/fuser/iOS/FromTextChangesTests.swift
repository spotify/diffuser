// Copyright (c) 2019 Spotify AB.
//
// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

#if canImport(UIKit)

import Diffuser
import UIKit
import XCTest

final class FromTextChangesTests: XCTestCase {
    func testDelegateIsSetAndRemoved() {
        let textView = UITextView()

        let connection = Fuser<UITextView>.fromTextView(textView).connect { _ in }

        XCTAssertNotNil(textView.delegate)

        connection.dispose()

        XCTAssertNil(textView.delegate)
    }

    func testDelegateIsSetAndRemovedWhenUsingHelper() {
        let textView = UITextView()

        let connection = Fuser<String>.fromTextChanges(textView).connect { _ in }

        XCTAssertNotNil(textView.delegate)

        connection.dispose()

        XCTAssertNil(textView.delegate)
    }

    func testDelegateIsNotRemovedWhenItHasBeenReassigned() {
        let textView = UITextView()
        let connection = Fuser<String>.fromTextChanges(textView).connect { _ in }

        class FakeDelegate: NSObject, UITextViewDelegate {}
        let fakeDelegate = FakeDelegate()
        textView.delegate = fakeDelegate

        connection.dispose()

        XCTAssertTrue(fakeDelegate === textView.delegate)
    }

    func testEventIsDispatchedWhenTextFieldEndsEditing() {
        let textView = UITextView()
        var text = ""
        let connection = Fuser<String>.fromTextChanges(textView).connect { newText in
            text = newText
        }

        let expectedText = "test text"
        textView.text = expectedText
        textView.delegate?.textViewDidChange?(textView)

        XCTAssertEqual(expectedText, text)

        connection.dispose()
    }

    func testExpectedEventsAreEmitted() {
        let textView = UITextView()
        var event: TextViewEvent?
        let connection = Fuser<TextViewEvent>.fromTextView(textView).connect { newEvent in
            event = newEvent
        }

        textView.delegate?.textViewDidBeginEditing?(textView)
        guard case .didBeginEditing(let view1) = event, view1 === textView else {
            XCTFail("Expected .didBeginEditing(\(textView)), got: \(String(describing: event))")
            return
        }

        textView.delegate?.textViewDidEndEditing?(textView)
        guard case .didEndEditing(let view2) = event, view2 === textView else {
            XCTFail("Expected .didEndEditing(\(textView)), got: \(String(describing: event))")
            return
        }

        textView.delegate?.textViewDidChangeSelection?(textView)
        guard case .didChangeSelection(let view3) = event, view3 === textView else {
            XCTFail("Expected .didChangeSelection(\(textView)), got: \(String(describing: event))")
            return
        }

        textView.delegate?.textViewDidChange?(textView)
        guard case .didChange(let view4) = event, view4 === textView else {
            XCTFail("Expected .didChange(\(textView)), got: \(String(describing: event))")
            return
        }

        connection.dispose()
    }

    func testUITextFieldTextChanges() {
        // Given: a `TextField`
        let fakeTextField = FakeUITextField()

        // When: Wrapping the `TextField` in a `Fuser` which observes its text changes
        let connection = Fuser<UITextField>.fromTextChanges(fakeTextField).connect { _ in }

        // Then: It should have assigned a target for its `.editingChanged` `UIControl.Event`
        XCTAssertEqual(UIControl.Event.editingChanged, fakeTextField.hasTargetForControlEvent)

        // And: When the fuser connection is disposed it should remove that target.
        connection.dispose()
        XCTAssertEqual(UIControl.Event.editingChanged, fakeTextField.hasRemovedTargetForControlEvent)
    }
}

private final class FakeUITextField: UITextField {
    var hasTargetForControlEvent: UIControl.Event?
    var hasRemovedTargetForControlEvent: UIControl.Event?

    override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        hasTargetForControlEvent = controlEvents
    }

    override func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        hasRemovedTargetForControlEvent = controlEvents
    }
}

#endif
