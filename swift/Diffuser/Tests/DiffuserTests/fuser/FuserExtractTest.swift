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

class FuserExtractTest: XCTestCase {

    func testFuserExtractLaws() {
        FuserLaws { source in
            return .extract({ $0 }, .from(source))
        }.verify()
    }

    func testFuserIdentityLaw() {
        property("Fuser conforms to identity law") <-
            // extract(id, fuser) == fuser
            forAll(integerLists) { input in
            let source = TestSource()
            let fuser = Fuser.from(source)

            var outputLhs: [Int] = []
            var outputRhs: [Int] = []

            // LHS: extract(id, fuser)
            let fuserLhs = Fuser.extract({ $0 }, fuser)

            // RHS: fuser
            let fuserRhs = fuser

            let disposableLhs = fuserLhs.connect { outputLhs.append($0) }
            let disposableRhs = fuserRhs.connect { outputRhs.append($0) }
            input.forEach { source.emit($0) }
            disposableLhs.dispose()
            disposableRhs.dispose()

            XCTAssertEqual(outputRhs, outputLhs)
            return outputLhs == outputRhs
        }
    }

    func testFuserAssociativity() {
        property("Fuser conforms to associativity law") <-
            // extract(f, extract(g, fuser)) == extract({ f(g(it)) }, fuser)
            forAll(integerLists, transformers, transformers) { input, transformerF, transformerG in
                let f = transformerF.transformation
                let g = transformerG.transformation
                let source = TestSource()
                let fuser = Fuser.from(source)

                var outputLhs: [Int] = []
                var outputRhs: [Int] = []

                // LHS: extract(f, extract(g, fuser))
                let fuserLhs = Fuser.extract(f, .extract(g, fuser))

                // RHS: extract({ f(g(it)) }, fuser)
                let fuserRhs = Fuser.extract({ f(g($0)) }, fuser)

                let disposableLhs = fuserLhs.connect { outputLhs.append($0) }
                let disposableRhs = fuserRhs.connect { outputRhs.append($0) }
                input.forEach { source.emit($0) }
                disposableLhs.dispose()
                disposableRhs.dispose()

                XCTAssertEqual(outputRhs, outputLhs)
                return outputLhs == outputRhs
            }
    }

    func testExtractAppliesTransformation() {
        property("extract() applies transformation to all values") <-
            // extract(f, fuser).connect { output(it) } == fuser.connect { output(f(it)) }
            forAll(integerLists, transformers) { input, transformerF in
                let f = transformerF.transformation
                let source = TestSource()
                let fuser = Fuser.from(source)

                var outputLhs: [Int] = []
                var outputRhs: [Int] = []

                // LHS: extract(f, fuser).connect { output(it) }
                let disposableLhs = Fuser.extract(f, fuser).connect { outputLhs.append($0) }

                // RHS: fuser.connect { output(f(it)) }
                let disposableRhs = fuser.connect { outputRhs.append(f($0)) }

                input.forEach { source.emit($0) }

                disposableLhs.dispose()
                disposableRhs.dispose()

                XCTAssertEqual(outputRhs, outputLhs)
                return outputLhs == outputRhs
            }
    }

    func testExtractConstant() {
         property("""
            extractConstant() is the same as extract() with a constant-returning function
         """) <-
            // extractConstant(constant, fuser) == extract({ _ in constant }, fuser)
            forAll(integerLists, integersBetween0And10) { input, constant in
                let source = TestSource()
                let fuser = Fuser.from(source)

                var outputLhs: [Int] = []
                var outputRhs: [Int] = []

                let disposableLhs = Fuser.extractConstant(constant, fuser)
                    .connect { outputLhs.append($0) }

                let disposableRhs = Fuser.extract({ _ in constant }, fuser)
                    .connect { outputRhs.append($0) }

                input.forEach { source.emit($0) }

                disposableLhs.dispose()
                disposableRhs.dispose()

                XCTAssertEqual(outputRhs, outputLhs)
                return outputLhs == outputRhs
            }
     }

    func testExtractUnlessNil() {
        let lists = Gen
            .fromElements(of: [1, 2, 3])
            .proliferate(withSize: 10)

        property("extractUnlessNil() emits all non-nil inputs") <-
            forAll(lists) { input in
                let source = TestSource()
                let fuser = Fuser.from(source)

                var output: [Int] = []

                let disposable = Fuser
                    .extractUnlessNil({ $0 == 3 ? nil : $0 }, fuser)
                    .connect { output.append($0) }

                input.forEach { source.emit($0) }

                disposable.dispose()

                let expectedOutput = input.filter { $0 != 3 }
                XCTAssertEqual(expectedOutput, output)
                return expectedOutput == output
        }
    }
}
