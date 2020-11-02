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

class GestureRecognizersTests: XCTestCase {

    private let control = UIControl()

    func testTapGestureRecognizerIsSettable() {
        assertFuser(
            Fuser<UITapGestureRecognizer>.fromTaps(control),
            setsRecognizerOfType: UITapGestureRecognizer.self
        )
    }

    func testPinchesGestureRecognizerIsSettable() {
        assertFuser(
            Fuser<UIPinchGestureRecognizer>.fromPinches(control),
            setsRecognizerOfType: UIPinchGestureRecognizer.self
        )
    }

    func testRotationGestureRecognizerIsSettable() {
        assertFuser(
            Fuser<UIRotationGestureRecognizer>.fromRotations(control),
            setsRecognizerOfType: UIRotationGestureRecognizer.self
        )
    }

    func testSwipesGestureRecognizerIsSettable() {
        assertFuser(
            Fuser<UISwipeGestureRecognizer>.fromSwipes(control),
            setsRecognizerOfType: UISwipeGestureRecognizer.self
        )
    }

    func testPansGestureRecognizerIsSettable() {
        assertFuser(
            Fuser<UIPanGestureRecognizer>.fromPans(control),
            setsRecognizerOfType: UIPanGestureRecognizer.self
        )
    }

    func testScreenEdgePansGestureRecognizerIsSettable() {
        assertFuser(
            Fuser<UIScreenEdgePanGestureRecognizer>.fromScreenEdgePans(control),
            setsRecognizerOfType: UIScreenEdgePanGestureRecognizer.self
        )
    }

    func testLongPressesGestureRecognizerIsSettable() {
        assertFuser(
            Fuser<UILongPressGestureRecognizer>.fromLongPresses(control),
            setsRecognizerOfType: UILongPressGestureRecognizer.self
        )
    }

    private func assertFuser<A>(_ fuser: Fuser<A>, setsRecognizerOfType recognizerType: AnyClass) {
        let disposable = fuser.connect { _ in }
        let recognizerWasAdded = control.gestureRecognizers?.first { recognizer in
            recognizer.isKind(of: recognizerType)
        } != nil
        XCTAssertTrue(recognizerWasAdded)

        disposable.dispose()
        let recognizerWasRemoved = control.gestureRecognizers?.first { recognizer in
            recognizer.isKind(of: recognizerType)
        } == nil
        XCTAssertTrue(recognizerWasRemoved)
    }
}

#endif
