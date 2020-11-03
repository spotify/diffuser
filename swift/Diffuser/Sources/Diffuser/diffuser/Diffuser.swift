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

public typealias DidChange<A> = (A, A) -> Bool
public typealias Effect<A> = (A) -> Void

/// A `Diffuser` wraps a side-effecting function.
///
/// When `.run(value)` is called on a `Diffuser`, it will decide if it should forward `value` to its side-effecting function.
/// E.g., `Diffuser`s created using `.into` and `.intoAll` only forward calls when the input value is different from
/// the previous value, or if `run` was called for the first time.
/// `intoWhen` can be to specify more nuanced caching. `intoAlways` will always run its function.
///
/// `Diffuser`s can be combined to orchestrate groups of side-effects. E.g., `intoAll` can be used to merge a list of `Diffuser`s
/// with the same input type, and `map` can be used to change a `Diffuser`'s input type.
///
/// `<A>` is the type of values that this `Diffuser` can be `run` with.
public struct Diffuser<A> {

    private let effect: Effect<A>

    init(effect: @escaping Effect<A>) {
        self.effect = effect
    }

    /// The side-effects associated with this `Diffuser` will always be executed if `run` is being
    /// called for the first time. Otherwise, whether they are executed will depend on how the `Diffuser`
    /// was created. For example, a `Diffuser` created with `into` will only execute its effects
    /// when the `newValue` differs from the previous `newValue` that was supplied to `run`.
    ///
    /// - Parameter newValue: The value to execute side effects based on.
    public func run(_ newValue: A) {
        self.effect(newValue)
    }

    static func notEqual<A: Equatable>(a: A, b: A) -> Bool {
        return a != b
    }

    init(
        effect: @escaping Effect<A>,
        didChange: @escaping DidChange<A>
    ) {
        var cache: A?

        func shouldRunWithNewValue(_ newValue: A) -> Bool {
            switch cache {
            case .none: return true
            case .some(let oldValue): return didChange(oldValue, newValue)
            }
        }

        func run(_ newValue: A) {
            if !shouldRunWithNewValue(newValue) {
                effect(newValue)
            }
            cache = newValue
        }

        self.init(effect: run)
    }
}

extension Diffuser where A: Equatable {
    /// Merge a list of Diffusers parameterized by the same type. The merged Diffuser will only forward calls
    /// to its children if the input changes (according to its own `Equatable` implementation)
    ///
    /// - Parameter children: the list of Diffusers to merge
    public init(_ children: [Diffuser<A>]) {
        let effect: (A) -> Void = { newValue in
            children.forEach { diffuser in diffuser.run(newValue) }
        }
        self.init(effect: effect, didChange: Diffuser.notEqual)
    }

    /// Merge a list of Diffusers parameterized by the same type. The merged Diffuser will only forward calls
    /// to its children if the input changes (according to its own `Equatable` implementation)
    ///
    /// - Parameter children: the list of Diffusers to merge
    public init(_ children: Diffuser<A>...) {
        let effect: (A) -> Void = { newValue in
            children.forEach { diffuser in diffuser.run(newValue) }
        }
        self.init(effect: effect, didChange: Diffuser.notEqual)
    }
}
