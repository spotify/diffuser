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

class ControlEventsTests: XCTestCase {

    private let control = FakeControl()
    private let event = UIControl.Event.touchUpOutside
    private lazy var fuser: Fuser<UIControl> = .fromEvents(control, for: event)

    func testTargetIsNotSetBeforeConnecting() {
        XCTAssertFalse(control.hasTarget)
    }

    func testTargetIsSetWhenConnecting() {
        let disposable = fuser.connect { _ in }
        XCTAssertTrue(control.hasTarget)
        disposable.dispose()
    }

    func testControlEventsMatchTheFusersEventType() {
        let disposable = fuser.connect { _ in }
        XCTAssertNotNil(control.eventType)
        if let eventType = control.eventType {
            XCTAssertEqual(event, eventType)
        } else {
            XCTFail("Expected an event type to be set")
        }
        disposable.dispose()
    }

    func testTargetIsRemovedAfterDisposing() {
        let disposable = fuser.connect { _ in }
        disposable.dispose()
        XCTAssertFalse(control.hasTarget)
    }
}

private class FakeControl: UIControl {
    var hasTarget = false
    var eventType: UIControl.Event?

    override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        hasTarget = true
        eventType = controlEvents
    }

    override func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        hasTarget = false
    }
}

#endif
