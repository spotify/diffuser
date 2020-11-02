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
import XCTest

class GeneralTests: XCTestCase {

    // Mark: Visibility

    func testBindVisibleWhen() {
        let view = UIView()
        Diffuser<Bool>.show(view).run(true)
        XCTAssertFalse(view.isHidden)
        Diffuser<Bool>.show(view).run(false)
        XCTAssertTrue(view.isHidden)
    }

    func testBindHiddenWhen() {
        let view = UIView()
        Diffuser<Bool>.hide(view).run(true)
        XCTAssertTrue(view.isHidden)
        Diffuser<Bool>.hide(view).run(false)
        XCTAssertFalse(view.isHidden)
    }

    // Mark: Enabled/Disabled

    func testEnabledUserInteractionWhen() {
        let view = UIView()
        Diffuser<Bool>.enableUserInteraction(view).run(true)
        XCTAssertTrue(view.isUserInteractionEnabled)
        Diffuser<Bool>.enableUserInteraction(view).run(false)
        XCTAssertFalse(view.isUserInteractionEnabled)
    }

    func testDisabledUserInteractionWhen() {
        let view = UIView()
        Diffuser<Bool>.disableUserInteraction(view).run(true)
        XCTAssertFalse(view.isUserInteractionEnabled)
        Diffuser<Bool>.disableUserInteraction(view).run(false)
        XCTAssertTrue(view.isUserInteractionEnabled)
    }

    func testEnabledControlWhen() {
        let control = UIControl()
        Diffuser<Bool>.enable(control).run(true)
        XCTAssertTrue(control.isEnabled)
        Diffuser<Bool>.enable(control).run(false)
        XCTAssertFalse(control.isEnabled)
    }

    func testDisabledControlWhen() {
        let control = UIControl()
        Diffuser<Bool>.disable(control).run(true)
        XCTAssertFalse(control.isEnabled)
        Diffuser<Bool>.disable(control).run(false)
        XCTAssertTrue(control.isEnabled)
    }

    // Mark: Background color

    func testBindBackgroundColor() {
        let view = UIView()
        Diffuser<UIColor>.intoBackgroundColor(view).run(UIColor.black)
        XCTAssertEqual(UIColor.black, view.backgroundColor)
        Diffuser<UIColor>.intoBackgroundColor(view).run(UIColor.green)
        XCTAssertEqual(UIColor.green, view.backgroundColor)
    }
}


#endif
