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

class IntoPropertiesTest: XCTestCase {
    
    func testIntoWhen() {
        property("intoWhen taking effect with alwaysChanged is same as intoAlways") <-
            // intoWhen({ true }, eff) == intoAlways(eff)
            effectsBehaveTheSame(
                formula(
                    lhs: { eff in .intoWhen(alwaysChanged, eff) },
                    rhs: { eff in .intoAlways(eff) }
                )
            )
        
        property("intoWhen which takes effect is the same as intoWhen which takes diffuser") <-
            // intoWhen(didChange, eff) == intoWhen(didChange, intoAlways(eff))
            effectsBehaveTheSame(
                didChanges.flatMap { didChangeWrapper in
                    let didChange = didChangeWrapper.check
                    return formula(
                        lhs: { eff in .intoWhen(didChange, eff) },
                        rhs: { eff in .intoWhen(didChange, .intoAlways(eff)) }
                    )
                }
            )
    }

    func testInto() {
        property("into is same as intoWhen with non-equality") <-
            // into(eff) == intoWhen((!=), intoAlways(eff))
            effectsBehaveTheSame(
                formula(
                    lhs: { eff in .into(eff) },
                    rhs: { eff in .intoWhen({ a, b in a != b }, .intoAlways(eff)) }
                )
            )
    }

    func testIntoOnceIsSameAsIntoWhenWhichAlwaysReturnsFalse() {
        property("intoOnce(eff) is the same as intoWhen(false, intoAlways(eff))") <-
            // intoOnce(eff) == intoWhen({ _, _ in false }, intoAlways(eff))
            effectsBehaveTheSame(
                formula(
                    lhs: { eff in .intoOnce(eff) },
                    rhs: { eff in .intoWhen({ _, _ in false }, .intoAlways(eff)) }
                )
            )
    }
    
    func testIntoAll() {
        property("Running `intoAll` on a list of `intoAlways` Diffusers is the same as running a list of `into` Diffusers individually in order") <-
            forAll(integerLists, integersBetween0And10) { input, d in
                var outputLhs: [Int] = []
                let range = (0...d)
                let diffusersListLhs = range.map { (i: Int) -> Diffuser<Int> in
                    let diffuser: Diffuser<Int> = .into { _ in outputLhs.append(i) }
                    return diffuser
                }

                var outputRhs: [Int] = []
                let diffusersListRhs = range.map { (i: Int) -> Diffuser<Int> in
                    let diffuser: Diffuser<Int> = .intoAlways { _ in outputRhs.append(i) }
                    return diffuser
                }
                let diffuserRhs = Diffuser.intoAll(diffusersListRhs)

                input.forEach { value in
                    diffusersListLhs.forEach { diffuser in diffuser.run(value) }

                    diffuserRhs.run(value)
                }

                XCTAssertEqual(outputRhs, outputLhs)
                return outputLhs == outputRhs
            }
    }

    func testIntoAllWithVarArgsIsSameAsIntoAllWithList() {
        property("intoAll with varargs is the same as intoAll with list") <-
            // intoAll(a, a, a) == intoAll([a, a, a])
            diffusersBehaveTheSame(
                formula(
                    lhs: { diffuser in .intoAll(diffuser, diffuser, diffuser) },
                    rhs: { diffuser in .intoAll([diffuser, diffuser, diffuser]) }
                )
            )
    }

    func testIntoAlwaysList() {
        property("Running `intoAlways` on a list of `intoAlways` Diffusers is the same as running a list of `intoAlways` Diffusers individually in order") <-
        forAll(integerLists, integersBetween0And10) { input, d in
            var outputLhs: [Int] = []
            let range = (0...d)
            let diffusersListLhs = range.map { (i: Int) -> Diffuser<Int> in
                let diffuser: Diffuser<Int> = .intoAlways { _ in outputLhs.append(i) }
                return diffuser
            }

            var outputRhs: [Int] = []
            let diffusersListRhs = range.map { (i: Int) -> Diffuser<Int> in
                let diffuser: Diffuser<Int> = .intoAlways { _ in outputRhs.append(i) }
                return diffuser
            }
            let diffuserRhs = Diffuser.intoAlways(diffusersListRhs)

            input.forEach { value in
                diffusersListLhs.forEach { diffuser in diffuser.run(value) }

                diffuserRhs.run(value)
            }

            XCTAssertEqual(outputRhs, outputLhs)
            return outputLhs == outputRhs
        }
    }

    func testIntoAlwaysListMapInto_intoAllMapInto_equivalence() {
        property("Running `intoAlways` on a list of `map -> into` Diffusers is the same as running `intoAll` on a list of `map -> into` Diffusers") <-
        forAll(integerLists, integersBetween0And10) { input, d in
            var outputLhs: [Int] = []
            let diffuserLhs: Diffuser<Int> = .intoAlways(
                .map(\.bitWidth, .into { _ in outputLhs.append(d) }),
                .map({ $0 * 2 }, .into { _ in outputLhs.append(d + 1) }),
                .map({ $0 % 2 == 0 }, .into { _ in outputLhs.append(d + 2) })
            )

            var outputRhs: [Int] = []
            let diffuserRhs: Diffuser<Int> = .intoAll(
                .map(\.bitWidth, .into { _ in outputRhs.append(d) }),
                .map({ $0 * 2 }, .into { _ in outputRhs.append(d + 1) }),
                .map({ $0 % 2 == 0 }, .into { _ in outputRhs.append(d + 2) })
            )

            input.forEach { value in
                diffuserLhs.run(value)
                diffuserRhs.run(value)
            }

            XCTAssertEqual(outputRhs, outputLhs)

            input.forEach { value in
                diffuserLhs.run(value)
                diffuserRhs.run(value)
            }

            XCTAssertEqual(outputRhs, outputLhs)

            input.forEach { value in
                diffuserLhs.run(value + 1)
                diffuserRhs.run(value + 1)
            }

            XCTAssertEqual(outputRhs, outputLhs)

            return outputLhs == outputRhs
        }
    }

    func testIntoAlwaysWithVarArgsIsSameAsIntoAlwaysWithList() {
        property("intoAll with varargs is the same as intoAll with list") <-
        // intoAlways(a, a, a) == intoAlways([a, a, a])
        diffusersBehaveTheSame(
            formula(
                lhs: { diffuser in .intoAlways(diffuser, diffuser, diffuser) },
                rhs: { diffuser in .intoAlways([diffuser, diffuser, diffuser]) }
            )
        )
    }


    func testDiffuserInitializerWithListIsSameAsIntoAllWithList() {
        property("Diffuser initializer with list is the same as intoAll with list") <-
            // Diffuser([a, a, a]) == intoAll([a, a, a])
            diffusersBehaveTheSame(
                formula(
                    lhs: { diffuser in Diffuser([diffuser, diffuser, diffuser]) },
                    rhs: { diffuser in .intoAll([diffuser, diffuser, diffuser]) }
                )
        )
    }

    func testDiffuserInitializerWithVarArgsIsSameAsIntoAllWithList() {
        property("Diffuser initializer with varargs is the same as intoAll with list") <-
            // Diffuser(a, a, a) == intoAll([a, a, a])
            diffusersBehaveTheSame(
                formula(
                    lhs: { diffuser in Diffuser(diffuser, diffuser, diffuser) },
                    rhs: { diffuser in .intoAll([diffuser, diffuser, diffuser]) }
                )
        )
    }

    func testNilDoesNotInterfereWithCaching() {
        var output: [Int?] = []
        let diffuser: Diffuser<Int?> = .into { value in
            output.append(value)
        }

        diffuser.run(nil)
        diffuser.run(1)
        diffuser.run(2)
        diffuser.run(nil)
        diffuser.run(2)

        XCTAssertEqual([nil, 1, 2, nil, 2], output)
    }

    func testMultipleNilsAreTreatedAsEqualValues() {
        var output: [Int?] = []
        let diffuser: Diffuser<Int?> = .into { value in
            output.append(value)
        }
        diffuser.run(nil)
        diffuser.run(nil)
        diffuser.run(nil)

        XCTAssertEqual([nil], output)
    }
}
