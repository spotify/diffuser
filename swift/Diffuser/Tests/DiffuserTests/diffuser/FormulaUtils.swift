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

func effectsBehaveTheSame(_ formulas: Gen<Formula<Effect<Int>>>) -> Property {
    return behaveTheSame({ $0 }, formulas)
}

func diffusersBehaveTheSame(_ formulas: Gen<Formula<Diffuser<Int>>>) -> Property {
    return behaveTheSame({ .intoAlways($0) }, formulas)
}

struct Formula<I>: Arbitrary {
    let lhs: (I) -> Diffuser<Int>
    let rhs: (I) -> Diffuser<Int>

    static var arbitrary: Gen<Formula> {
        fatalError("Must be constructed manually")
    }
}

func formula<I>(lhs: @escaping (I) -> Diffuser<Int>, rhs: @escaping (I) -> Diffuser<Int>) -> Gen<Formula<I>> {
    return Gen.pure(Formula(lhs: lhs, rhs: rhs))
}

private func behaveTheSame<I>(
    _ effectAdapter: @escaping (@escaping Effect<Int>) -> I,
    _ formulasGen: Gen<Formula<I>>
    ) -> Property {
    return forAll(integerLists, formulasGen) { input, formula in
        var outputLhs: [Int] = []
        var outputRhs: [Int] = []

        let diffuserLhs = formula.lhs(effectAdapter { outputLhs.append($0) })
        let diffuserRhs = formula.rhs(effectAdapter { outputRhs.append($0) })

        input.forEach {
            diffuserLhs.run($0)
            diffuserRhs.run($0)
        }
        
        XCTAssertEqual(outputRhs, outputLhs)
        return outputLhs == outputRhs
    }
}
