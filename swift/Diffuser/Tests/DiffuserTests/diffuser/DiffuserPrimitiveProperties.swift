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

class DiffuserPrimitiveProperties: XCTestCase {
    func testIntoAlwaysProperties() {
        property("IntoAlways runs all effects in order") <- forAll { (input : [Int]) in
            var output: [Int] = []
            let diffuser: Diffuser<Int> = .intoAlways { n in output.append(n) }

            input.forEach(diffuser.run)

            XCTAssertEqual(input, output)
            return output == input
        }
    }

    func testIntoWhenProperties() {
        property("IntoWhen with alwaysChanged is the same as IntoAlways") <-
            // intoWhen({ true }, intoAlways(eff)) == intoAlways(eff)
            effectsBehaveTheSame(
                formula(
                    lhs: { eff in .intoWhen(alwaysChanged, .intoAlways(eff)) },
                    rhs: { eff in .intoAlways(eff) }
                )
            )

        property("IntoWhen runs effects when the value changes") <- forAll {  (input: [Int], didChangeWrapper: DidChangeInt) in
            //                             run('a');               --> a
            //
            // diff(a, b)               => run(a); run(b);         --> ab
            // !diff(a, b)              => run(a); run(b);         --> a
            //
            // diff(a,b) && diff(b,c)   => run(a); run(b); run(c); --> abc
            // diff(a,b) && !diff(b,c)  => run(a); run(b); run(c); --> ab
            // !diff(a,b) && diff(b,c)  => run(a); run(b); run(c); --> ac
            // !diff(a,b) && !diff(b,c) => run(a); run(b); run(c); --> a
            let didChange = didChangeWrapper.check

            var outputLhs: [Int] = []
            let diffuserLhs: Diffuser<Int> = .intoWhen(didChange, .intoAlways { n in outputLhs.append(n) })

            let outputRhs = generateExpectedChanges(input, didChange)

            input.forEach { diffuserLhs.run($0) }

            XCTAssertEqual(outputRhs, outputLhs)
            return outputRhs == outputLhs
        }
    }

    func testMapProperties() {
        property("map satisfies identity law") <-
            // map({ $0 }, diffuser) == diffuser
            effectsBehaveTheSame(
                formula(
                    lhs: { eff in .map({ $0 }, .intoAlways(eff)) },
                    rhs: { eff in .intoAlways(eff) }
                )
            )

        property("map applies transformation") <-
            // map(f, diffuser) == intoAlways { diffuser.run(f($0)) }
            diffusersBehaveTheSame(
                transformers.flatMap { transformer in
                    let f = transformer.transformation
                    return formula(
                        lhs: { diffuser in .map(f, diffuser) },
                        rhs: { diffuser in .intoAlways { diffuser.run(f($0)) } }
                    )
                }
            )

        property("map satisfies associativity law") <-
            // map(f, map(g, diffuser)) == map(g . f, diffuser)
            diffusersBehaveTheSame(
                Gen.zip(transformers, transformers).flatMap { (transformerF, transformerG) in
                    let f = transformerF.transformation
                    let g = transformerG.transformation
                    return formula(
                        lhs: { diffuser in .map(f, .map(g, diffuser)) },
                        rhs: { diffuser in .map({ g(f($0)) }, diffuser) }
                    )
                }
            )
    }

    func testInvertProperties() {
        var actual: Bool?
        let diffuser = Diffuser<Bool>.invert(.into({ value in
            actual = value
        }))

        diffuser.run(true)
        XCTAssertTrue(actual == false)

        diffuser.run(false)
        XCTAssertTrue(actual == true)
    }
}

private func generateExpectedChanges(_ input: [Int], _ didChange: (Int, Int) -> Bool) -> [Int] {
    if let first = input.first {
        var output: [Int] = []

        // Always include first from input, as there is no cache when first change happens
        output.append(first)
        let _ = input.dropFirst().reduce(first) { previous, current in
            if (didChange(previous, current)) {
                output.append(current)
            }
            return current
        }

        return output
    }
    return []
}
