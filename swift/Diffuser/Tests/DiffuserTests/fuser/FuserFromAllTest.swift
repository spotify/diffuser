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

class FuserFromAllTest: XCTestCase {

    func testFromFromAllLaws() {
        FuserLaws(fuserFrom: { source in
            .fromAll([.from(source)])
        }).verify()

        // convenience vararg version
        FuserLaws(fuserFrom: { source in
            .fromAll(.from(source))
        }).verify()
    }

    func testFromAllCombinesMultipleFusers() {
        property("fromAll() combines multiple fusers into one") <-
            // fromAll(fusers).connect { output(it) } == fusers.map { fuser -> fuser.connect { output(it) } }
            forAll(integerLists, integersBetween0And10, Int.arbitrary) { input, numberOfFusers, seed in
                let sources = (1...numberOfFusers).map { _ in TestSource() }
                let fusers = sources.map { source in Fuser.from(source) }
                srand48(seed)

                var outputLhs: [Int] = []
                var outputRhs: [Int] = []

                // LHS: fromAll(fusers).connect { output(it) }
                let disposablesLhs = Fuser.fromAll(fusers).connect { outputLhs.append($0) }

                // RHS: fusers.map { fuser -> fuser.connect { output(it) }
                let disposablesRhs = fusers.map { fuser in fuser.connect { outputRhs.append($0) }}

                input.forEach { n in
                    if !sources.isEmpty {
                        let randomIndex = abs(Int(drand48()) % sources.count)
                        let source = sources[randomIndex]
                        source.emit(n)
                    }
                }

                disposablesLhs.dispose()
                disposablesRhs.forEach { $0.dispose() }

                XCTAssertEqual(outputRhs, outputLhs)
                return outputLhs == outputRhs
            }
    }

    func testFromAllDisposesChildFusers() {
        property("fromAll() disposes all child Fusers when disposed") <-
            forAll(integersBetween0And10) { numberOfFusers in
                let sources = (1...numberOfFusers).map { _ in DisposableSource() }
                let fusers = sources.map { source in Fuser.from(source) }

                let disposable = Fuser.fromAll(fusers).connect { _ in }
                disposable.dispose()

                let allWereDisposed = sources.reduce(true, { acc, x in acc && x.isDisposed })
                return allWereDisposed
            }
    }

    func testFromAllWithVarargsCombinesFusers() {
        let source = TestSource()
        let fuser1 = Fuser.extract({ $0 * 10 }, .from(source))
        let fuser2 = Fuser.extract({ $0 * 100 }, .from(source))
        let fuser3 = Fuser.extract({ $0 * 1000 }, .from(source))

        var output: Set<Int> = []

        let mergedFuser = Fuser.fromAll(fuser1, fuser2, fuser3)
        let disposable = mergedFuser.connect { output.insert($0) }

        source.emit(1)
        source.emit(2)
        source.emit(3)

        disposable.dispose()

        XCTAssertEqual([10, 100, 1000, 20, 200, 2000, 30, 300, 3000], output)
    }

    func testFromAllWithVarargsDisposesArguments() {
        let sources = [DisposableSource(), DisposableSource(), DisposableSource()]
        let fusers = [Fuser.from(sources[0]), Fuser.from(sources[1]), Fuser.from(sources[2])]
        let mergedFuser = Fuser.fromAll(fusers[0], fusers[1], fusers[2])

        let disposable = mergedFuser.connect { _ in }
        disposable.dispose()

        let allWereDisposed = sources.reduce(true) { acc, x in acc && x.isDisposed }

        XCTAssertTrue(allWereDisposed)
    }
}
