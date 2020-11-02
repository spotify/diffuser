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

import Foundation

/// A `Fuser<A>` is a stream of events of type `A`.
/// It supports:
///    - `connect`: start listening to events from the Fuser. A callback function is supplied to connect.
///    - `dispose`: stop listening to events. Can be called on objects returned by `connect`.
///    - `extract`: apply a function to every event emitted by a Fuser.
public class Fuser<A> {
    public typealias Disposable = _Disposable

    private let lock = NSRecursiveLock()
    private let source: AnySource<A>;

    public init(source: AnySource<A>) {
        self.source = source
    }

    public init(_ children: [Fuser<A>]) {
        self.source = AnySource { effect in
            let disposables = children.map { $0.connect(effect) }

            return AnonymousDisposable {
                // TODO review thread safety of this operation
                disposables.forEach { $0.dispose() }
            }
        }
    }

    public convenience init(_ children: Fuser<A>...) {
        self.init(children)
    }

    /// Start observing the events of a `Fuser`. Remember to call `.dispose()` on the disposable returned when
    /// connecting. Otherwise you may leak resources.
    ///
    /// - Parameter effect: the side-effect which should be performed when the `Fuser` emits an event
    /// - Returns: a disposable which can be called to unsubscribe from the `Fuser`'s events
    public func connect(_ effect: @escaping Effect<A>) -> Disposable {
        var isDisposed = false

        let safeEffect: Effect<A> = { value in
            self.lock.synchronized {
                if !isDisposed {
                    effect(value)
                }
            }
        }

        let disposable = source.connect(safeEffect)

        return AnonymousDisposable {
            self.lock.synchronized {
                isDisposed = true
            }
            disposable.dispose()
        }
    }
}

public extension Fuser {
    /// Create a `Fuser` when given a `Source`.
    static func from<S: Source>(_ source: S) -> Fuser<A> where S.A == A {
        return Fuser(source: AnySource(source));
    }

    /// See `from(Source)`
    /// This is a shorthand for creating a `Fuser` from a closure directly.
    static func from(_ source: @escaping (@escaping Effect<A>) -> Disposable) -> Fuser<A> {
        return from(AnySource(source))
    }

    /// `fromAll` merges a list of `Fuser`s.
    /// Connecting to this returned `Fuser` will internally connect to each of the merged `Fuser`s, and calling `dispose`
    /// will disconnect from all of these connections.
    static func fromAll(_ children: [Fuser<A>]) -> Fuser<A> {
        return Fuser(children)
    }

    /// Vararg variant of `fromAll([Fuser<..>])`
    static func fromAll(_ children: Fuser<A>...) -> Fuser<A> {
        return Fuser(children)
    }

    /// `extract` takes a function which it applies to each event emitted by a `Fuser`.
    ///
    /// We intentionally do not provide other combinators than `extract`, like `flatMap`, `filter`, or `reduce`. The `Fuser`
    /// is designed for aggregating UI-events and should be placed in the UI-layer of an application. `extract` is primarily
    /// intended for converting from UIKit types to types from your domain. Any additional interpretation of events should
    /// be placed outside of the `Fuser` and outside the UI-layer.
    ///
    /// - Parameters:
    ///   - transformation: the function to be applied to each event emitted by the `fuser` parameter
    ///   - fuser: the fuser to which the `transformation` function should be applied
    static func extract<B>(
        _ transformation: @escaping (B) -> A,
        _ fuser: Fuser<B>
    ) -> Fuser<A> {
        return Fuser<A>(source: AnySource { effect in
            return fuser.connect { b in
                let a = transformation(b)
                effect(a)
            }
        })
    }

    /// Extract a constant from each event emitted by a `Fuser`.
    ///
    /// - Parameters:
    ///   - constant: the constant that should be emitted everytime the `fuser` parameter emits an event
    ///   - fuser: the fuser to which the `transformation` function should be applied
    static func extractConstant<B>(
        _ constant: A,
        _ fuser: Fuser<B>
    ) -> Fuser<A> {
        return Fuser<A>(source: AnySource { effect in
            return fuser.connect { b in
                effect(constant)
            }
        })
    }

    /// `extractUnlessNil` takes a function which it applies to each event emitted by a `Fuser`. The event is dropped if the function
    /// returns `nil`.
    ///
    /// - Parameters:
    ///   - transformation: the function to be applied to each event emitted by the `fuser` parameter. The event will be ignored if
    ///   this function returns `nil`
    ///   - fuser: the fuser to which the `transformation` function should be applied
    static func extractUnlessNil<B>(
        _ transformation: @escaping (B) -> A?,
        _ fuser: Fuser<B>
    ) -> Fuser<A> {
        return Fuser<A>(source: AnySource { effect in
            return fuser.connect { b in
                if let a = transformation(b) {
                    effect(a)
                }
            }
        })
    }
}

private extension NSRecursiveLock {
    @discardableResult
    func synchronized<R>(closure: () -> R) -> R {
        lock()
        defer {
            self.unlock()
        }

        return closure()
    }
}
