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
import Foundation

class AfterDisposeEmittingSource: Source {
    typealias A = Int

    var output: Effect<Int>? = nil
    var isDisposed = false

    func emit(_ n: Int) {
        // Will try to emit even if disposed
        output?(n)
    }

    func connect(_ effect: @escaping Effect<Int>) -> Fuser<A>.Disposable {
        if (isDisposed) {
            fatalError("This source can only connect once")
        }

        self.output = effect

        return AnonymousDisposable { [unowned self] in
            self.isDisposed = true
        }
    }
}

class DisposableSource: Source {
    typealias A = Int

    var isDisposed = false

    func connect(_ effect: @escaping Effect<Int>) -> Fuser<A>.Disposable {
        if (isDisposed) {
            fatalError("This source can only connect once")
        }

        return AnonymousDisposable { [unowned self] in
            self.isDisposed = true
        }
    }
}

class TestSource: Source {
    typealias A = Int

    var outputs: [UUID: Effect<Int>] = [:]

    func emit(_ n: Int) {
        // Will try to emit even if disposed
        outputs.values.forEach { output in
            output(n)
        }
    }

    func connect(_ effect: @escaping Effect<Int>) -> Fuser<A>.Disposable {
        let id = UUID()
        outputs[id] = effect

        return AnonymousDisposable { [unowned self] in
            self.outputs.removeValue(forKey: id)
        }
    }
}
