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
import SwiftCheck
import XCTest

class FuserLaws {

    private let identityFuser: (AnySource<Int>) -> Fuser<Int>

    init(fuserFrom fuserFactory: @escaping (AnySource<Int>) -> Fuser<Int>) {
        self.identityFuser = fuserFactory
    }

    func verify() {
        valuesAreDispatchedInOrder()
        valuesAreOnlyDispatchedAfterConnect()
        valuesAreNotDispatchedAfterDispose()
        callingDisposeDisposesTheSource()
        canBeConnectedToMultipleTimes()
        connectionsCanBeDisposedIndependently()
    }

    func valuesAreDispatchedInOrder() {
        // events after connect are sent in order
        let source = TestSource()
        let fuser = identityFuser(AnySource(source))
        var output: [Int] = []

        let disposable = fuser.connect { output.append($0) }
        source.emit(1)
        source.emit(2)
        source.emit(3)
        disposable.dispose()

        XCTAssertEqual([1, 2, 3], output)
    }

    func valuesAreOnlyDispatchedAfterConnect() {
        // events after connect are dispatched
        let source = TestSource()
        let fuser = identityFuser(AnySource(source))
        var output: [Int] = []

        source.emit(1)
        let disposable = fuser.connect { output.append($0) }
        source.emit(2)
        source.emit(3)
        disposable.dispose()

        XCTAssertEqual([2, 3], output)
    }

    func valuesAreNotDispatchedAfterDispose() {
        let source = AfterDisposeEmittingSource()
        let fuser = identityFuser(AnySource(source))
        var output: [Int] = []

        let disposable = fuser.connect { output.append($0) }
        source.emit(1)
        source.emit(2)
        disposable.dispose()
        source.emit(3)

        XCTAssertEqual([1, 2], output)
    }

    func callingDisposeDisposesTheSource() {
        let source = DisposableSource()
        let fuser = identityFuser(AnySource(source))

        let disposable = fuser.connect { _ in }

        XCTAssertFalse(source.isDisposed)
        disposable.dispose()
        XCTAssertTrue(source.isDisposed)
    }

    func canBeConnectedToMultipleTimes() {
        let source = TestSource()
        let fuser = identityFuser(AnySource(source))

        var output1: [Int] = []
        let connection1 = fuser.connect { output1.append($0) }

        var output2: [Int] = []
        let connection2 = fuser.connect { output2.append($0) }

        let input = [1, 2, 3]
        input.forEach { source.emit($0) }

        connection1.dispose()
        connection2.dispose()

        XCTAssertEqual(input, output1)
        XCTAssertEqual(input, output2)
    }

    func connectionsCanBeDisposedIndependently() {
        let source = TestSource()
        let fuser = identityFuser(AnySource(source))

        var output1: [Int] = []
        let connection1 = fuser.connect { output1.append($0) }

        var output2: [Int] = []
        let connection2 = fuser.connect { output2.append($0) }

        source.emit(1)
        source.emit(2)
        connection1.dispose()
        source.emit(3)
        connection2.dispose()

        XCTAssertEqual([1, 2], output1)
        XCTAssertEqual([1, 2, 3], output2)
    }
}
