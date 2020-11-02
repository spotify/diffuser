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

import Diffuser
import XCTest

class AnonymousDisposableTests: XCTestCase {
    func testCallsDisposeOnDispose() {
        var disposeCalled = false
        let anonymousDisposable = AnonymousDisposable {
            disposeCalled = true
        }

        XCTAssertFalse(disposeCalled)
        anonymousDisposable.dispose()
        XCTAssertTrue(disposeCalled)
    }

    func testCallsDisposeOnDeinit() {
        var disposeCalled = false
        var anonymousDisposable: AnonymousDisposable? = AnonymousDisposable {
            disposeCalled = true
        }

        XCTAssertFalse(disposeCalled)
        anonymousDisposable = nil
        XCTAssertTrue(disposeCalled)
    }

    func testDisposeIsIdempotent() {
        var disposeCallCount = 0
        let anonymousDisposable = AnonymousDisposable {
            disposeCallCount += 1
        }

        anonymousDisposable.dispose()
        XCTAssertEqual(1, disposeCallCount)
        anonymousDisposable.dispose()
        XCTAssertEqual(1, disposeCallCount)
    }
}
