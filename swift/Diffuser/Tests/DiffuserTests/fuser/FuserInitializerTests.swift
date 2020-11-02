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
import SwiftCheck

class FuserInitializerTest: XCTestCase {

    func testFromAllWithVarArgsIsEqualToConstructor() {
        property("fromAll is the same as the Fuser's constructor") <-
            forAll(integerLists) { input in
                let source = TestSource()
                let fuser = Fuser.from(source)

                var outputLhs: [Int] = []
                var outputRhs: [Int] = []

                let fuserLhs = Fuser.fromAll(fuser, fuser)
                let fuserRhs = Fuser(fuser, fuser)

                let disposableLhs = fuserLhs.connect { outputLhs.append($0) }
                let disposableRhs = fuserRhs.connect { outputRhs.append($0) }
                input.forEach { source.emit($0) }
                disposableLhs.dispose()
                disposableRhs.dispose()

                XCTAssertEqual(outputRhs, outputLhs)
                return outputLhs == outputRhs
        }
    }

    func testFromAllIsEqualToConstructor() {
        property("fromAll is the same as the Fuser's constructor") <-
            forAll(integerLists) { input in
                let source = TestSource()
                let fuser = Fuser.from(source)

                var outputLhs: [Int] = []
                var outputRhs: [Int] = []

                let fuserLhs = Fuser.fromAll([fuser, fuser])
                let fuserRhs = Fuser([fuser, fuser])

                let disposableLhs = fuserLhs.connect { outputLhs.append($0) }
                let disposableRhs = fuserRhs.connect { outputRhs.append($0) }
                input.forEach { source.emit($0) }
                disposableLhs.dispose()
                disposableRhs.dispose()

                XCTAssertEqual(outputRhs, outputLhs)
                return outputLhs == outputRhs
        }
    }
}
