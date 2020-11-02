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

public extension Diffuser {
    /// Create a `Diffuser` which maps into a field of an object.
    ///
    /// - Parameters:
    ///   - keyPath: The keypath of the field which should be mapped into
    ///   - diffuser: The Diffuser which will receive the field that was mapped into.
    /// - Returns: A Diffuser which maps into a field of an object.
    static func map<B>(
        _ keyPath: KeyPath<A, B>,
        _ diffuser: Diffuser<B>
    ) -> Diffuser<A> {
        let transform: (A) -> B = path(keyPath)
        let diffuser: Diffuser<B> = diffuser
        return Diffuser.map(transform, diffuser)
    }

    /// Create a `Diffuser` which applies the diffused value into the `keyPath` on the list of subjects.
    ///
    /// ## Example
    ///
    /// ```swift
    /// class LiveListenersView {
    ///     var listenerCount: Int
    /// }
    ///
    /// let diffuser = Diffuser<MyView>.intoAll(
    ///     .map(\.liveListeners, .intoKeypath(\.listenerCount, on: headerView.liveListeners))
    /// )
    /// diffuser.run(model)
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to a writeable property on the `Subject` with type `A`.
    ///   - subjects: The relevant subjects.
    /// - Returns: A `Diffuser` which sets the given `keyPath` on the list of subjects.
    static func intoKeypath<Subject>(
        _ keyPath: ReferenceWritableKeyPath<Subject, A>,
        on subjects: Subject...
    ) -> Diffuser<A> {
        .intoAlways { value in
            subjects.forEach { subject in
                subject[keyPath: keyPath] = value
            }
        }
    }

    /// Create a `Diffuser` which applies the diffused value into the `keyPath` for an optional property on the list of
    /// subjects.
    ///
    /// ## Example
    ///
    /// ```swift
    /// class LiveListenersView {
    ///     var listenerCount: Int?
    /// }
    ///
    /// let diffuser = Diffuser<MyView>.intoAll(
    ///     .map(\.liveListeners, .intoKeypath(\.listenerCount, on: headerView.liveListeners))
    /// )
    /// diffuser.run(model)
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to a writeable property on the `Subject` with type `A?`.
    ///   - subjects: The relevant subjects.
    /// - Returns: A `Diffuser` which sets the given `keyPath` on the list of subjects.
    static func intoKeypath<Subject>(
        _ keyPath: ReferenceWritableKeyPath<Subject, A?>,
        on subjects: Subject...
    ) -> Diffuser<A> {
        .intoAlways { value in
            subjects.forEach { subject in
                subject[keyPath: keyPath] = value
                return
            }
        }
    }
}

private func path<A, B>(_ keyPath: KeyPath<A, B>) -> (A) -> B {
    return { a in
        return a[keyPath: keyPath]
    }
}
