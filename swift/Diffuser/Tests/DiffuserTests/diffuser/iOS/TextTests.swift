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

import XCTest
import Diffuser

class TextTests: XCTestCase {
    struct A: Equatable {
        let expectedText = "expectedText"
    }

    // Mark: UILabel
    func testBindingTextSetsUILabelText() {
        let label = UILabel()
        Diffuser.map(\A.expectedText, .intoText(label)).run(A())

        XCTAssertEqual(A().expectedText, label.text)
    }

    // Mark: UITextField
    func testBindingTextSetsUITextFieldText() {
        let textField = UITextField()
        Diffuser.map(\A.expectedText, .intoText(textField)).run(A())

        XCTAssertEqual(A().expectedText, textField.text)
    }

    // Mark: UITextView
    func testBindingTextSetsUITextViewText() {
        let textView = UITextView()
        Diffuser.map(\A.expectedText, .intoText(textView)).run(A())

        XCTAssertEqual(A().expectedText, textView.text)
    }

    // Mark: General
    func testMultipleViewsCanBeBoundAsVarargs() {
        let textViews = [UITextView(), UITextView(), UITextView()]
        Diffuser.map(\A.expectedText, .intoText(textViews[0], textViews[1], textViews[2])).run(A())
        textViews.forEach { textView in
            XCTAssertEqual(A().expectedText, textView.text)
        }
    }
}

#endif
