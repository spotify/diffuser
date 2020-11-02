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

class KeyPathDiffuserPropertiesTests: XCTestCase {
    func testMapWithKeypath() {
        property("map() with a keyPath is the same as map() with a function") <-
            // map(\Int.hashValue, diffuser) == map({ $0.hashValue() } , diffuser)
            diffusersBehaveTheSame(
                formula(
                    lhs: { diffuser in .map(\Int.hashValue, diffuser) },
                    rhs: { diffuser in .map({ $0.hashValue }, diffuser) }
                )
        )
    }

    func testIntoWithKeypath() {
        struct Model {
            let value: String
        }
        class Subject {
            var property: String = ""
        }

        let subject1 = Subject()
        let subject2 = Subject()

        Diffuser<Model>
            .map(\.value, .intoKeypath(\.property, on: subject1, subject2))
            .run(Model(value: "expected"))

        XCTAssertEqual(subject1.property, "expected")
        XCTAssertEqual(subject2.property, "expected")
    }

    func testIntoWithKeypathOptionalProperty() {
        struct Model {
            let value: String
        }
        class Subject {
            var property: String?
        }

        let subject1 = Subject()
        let subject2 = Subject()

        Diffuser<Model>
            .map(\.value, .intoKeypath(\.property, on: subject1, subject2))
            .run(Model(value: "expected"))

        XCTAssertEqual(subject1.property, "expected")
        XCTAssertEqual(subject2.property, "expected")
    }
}
