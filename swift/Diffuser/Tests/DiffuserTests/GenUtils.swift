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

struct DidChangeInt: Arbitrary {
    let check: DidChange<Int>

    static var arbitrary: Gen<DidChangeInt> {
        return Gen<DidChangeInt>.fromElements(of: [
            DidChangeInt(check: { a, b in a != b }),
            DidChangeInt(check: { a, b in a < b }),
            DidChangeInt(check: { a, b in a >= b }),
            DidChangeInt(check: { a, b in a == b }),
            ])
    }
}

let didChanges: Gen<DidChangeInt> = DidChangeInt.arbitrary

struct IntTransformation: Arbitrary {
    let transformation: (Int) -> Int

    static var arbitrary: Gen<IntTransformation> {
        return  Gen<IntTransformation>.fromElements(of: [
            IntTransformation(transformation: { $0 + 1 }),
            IntTransformation(transformation: { $0 - 50 }),
            IntTransformation(transformation: { $0 * 2 }),
            IntTransformation(transformation: { -$0 }),
            ])
    }
}

let transformers: Gen<IntTransformation> = IntTransformation.arbitrary

let integerLists = [Int].arbitrary.map { $0.map { n in abs(n % 3) } }

let integersBetween0And10 = Int.arbitrary.map { n in abs(n % 10) + 1 }

func alwaysChanged(a: Int, b: Int) -> Bool {
    return true
}
