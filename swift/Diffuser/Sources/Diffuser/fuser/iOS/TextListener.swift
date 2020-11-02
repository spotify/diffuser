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

import UIKit

public extension Fuser {
    /// Observe all text changes emitted by a `UITextView`.
    ///
    /// Note: This will overwrite any existing delegate on the `UITextView`.
    /// - Parameter textView: the `UITextView` which should be observed.
    static func fromTextChanges(_ textView: UITextView) -> Fuser<String> {
        .extractUnlessNil(
            { event in
                if case .didChange(let textView) = event {
                    return textView.text
                } else {
                    return nil
                }
            },
            .fromTextView(textView)
        )
    }

    /// Observe all text changes emitted by a `UITextField`.
    ///
    /// - Parameter textField: the `UITextField` which should be observed.
    static func fromTextChanges(_ textField: UITextField) -> Fuser<String> {
        .extractUnlessNil({ $0.text }, .fromEvents(textField, for: .editingChanged))
    }

    /// Observe all `TextViewEvent`s emitted by a `UITextView`. If you only want to be notified when the text changed,
    /// use `fromTextChanges(textView:)`.
    ///
    /// Note: This will overwrite any existing delegate on the `UITextView`.
    /// - Parameter textView: the `UITextView` which should be observed.
    static func fromTextView(_ textView: UITextView) -> Fuser<TextViewEvent> {
        .from { dispatch in
            // Retain the delegate until the Fuser is disposed.
            var textDelegate: TextDelegate? = TextDelegate(onEvent: dispatch)
            textView.delegate = textDelegate
            return AnonymousDisposable {
                // Remove the delegate unless it has already been changed
                if textView.delegate === textDelegate {
                    textView.delegate = nil
                }
                textDelegate = nil
            }
        }
    }
}

public enum TextViewEvent {
    case didChange(UITextView)
    case didBeginEditing(UITextView)
    case didEndEditing(UITextView)
    case didChangeSelection(UITextView)
}

private final class TextDelegate: NSObject, UITextViewDelegate {
    private let onEvent: Effect<TextViewEvent>

    init(onEvent: @escaping Effect<TextViewEvent>) {
        self.onEvent = onEvent
        super.init()
    }

    func textViewDidChange(_ textView: UITextView) {
        onEvent(.didChange(textView))
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        onEvent(.didBeginEditing(textView))
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        onEvent(.didEndEditing(textView))
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        onEvent(.didChangeSelection(textView))
    }
}

#endif
