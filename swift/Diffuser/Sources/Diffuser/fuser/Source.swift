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

/// A `Source` takes a side-effecting function which it will call when it wants to emit an event.
/// When given such a function, it will return a `Disposable` which can be called when the consumer no longer
/// wants to receive events.
public protocol Source {
    associatedtype A

    /// - Parameter effect: A side-effecting function which it will call whenever it wants to emit an event.
    /// - Returns: A `Disposable` which can be called when this connection should be torn down.
    func connect(_ effect: @escaping Effect<A>) -> Fuser<A>.Disposable
}

/// `AnySource` creates a source when given a function that matches the type of the only function in `Source`'s
/// protocol.
public class AnySource<T>: Source {
    public typealias A = T

    private let connectFn: (@escaping Effect<A>) -> Fuser<A>.Disposable

    public init<S: Source>(_ source: S) where S.A == T {
        self.connectFn = source.connect
    }

    public init(_ connect: @escaping (@escaping Effect<T>) -> Fuser<A>.Disposable) {
        self.connectFn = connect
    }

    public func connect(_ effect: @escaping Effect<T>) -> Fuser<A>.Disposable {
        return self.connectFn(effect)
    }
}
