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
    /// Create a Diffuser which always executes its side-effect regardless of the value.
    ///
    /// This function is useful as a building block for more complex Diffusers, but it is unlikely that you would use
    /// it on its own. Consider using `into` instead.
    ///
    /// - Parameter effect: The side-effect which should be performed when `run` is called on this Diffuser.
    /// - Returns: A Diffuser which always executes its side-effect when given a value.
    static func intoAlways(
        _ effect: @escaping Effect<A>
    ) -> Diffuser<A> {
        return Diffuser(effect: effect)
    }

    /// Add an additional layer of caching to an existing Diffuser.
    ///
    /// This function is useful as a building block for more complex Diffusers, but it is unlikely that you would use
    /// it on its own. Consider using `into` instead.
    ///
    /// - Parameter didChange: a function which returns determines if the side-effect should be executed given the
    /// previous value and the current value that the Diffuser is `run` with. if `run` is called for the first time,
    /// the side-effect will be executed regardless, and this function will not be run.
    /// - Parameter diffuser: the diffuser to wrap
    /// - Returns: a diffuser which wraps the diffuser parameter with an additional caching policy.
    static func intoWhen(
        _ didChange: @escaping DidChange<A>,
        _ diffuser: Diffuser<A>
    ) -> Diffuser<A> {
        return Diffuser(
            effect: diffuser.run,
            didChange: didChange
        )
    }

    /// Create a Diffuser by wrapping a side-effecting function with a caching layer.
    ///
    /// This function is useful as a building block for more complex Diffusers, but it unlikely is that you would use it
    /// on its own. Consider using `into` instead.
    ///
    /// - Parameter didChange: A function which returns determines if the side-effect should be executed given the
    /// previous value and the current value that the Diffuser is `run` with. If `run` is called for the first time,
    /// the side-effect will be executed regardless, and this function will not be run.
    /// - Parameter effect: The side-effect to execute
    /// - Returns: A Diffuser which wraps the diffuser parameter with an additional caching policy.
    static func intoWhen(
        _ didChange: @escaping DidChange<A>,
        _ effect: @escaping Effect<A>
    ) -> Diffuser<A> {
        return Diffuser(
            effect: effect,
            didChange: didChange
        )
    }

    /// Create a Diffuser which will only run its side-effecting function once, when it receives its first value.
    /// - Parameter effect: a side-effect which should be run once.
    static func intoOnce(
        _ effect: @escaping Effect<A>
    ) -> Diffuser<A> {
        var didRun = false
        return Diffuser { a in
            if !didRun {
                effect(a)
                didRun = true
            }
        }
    }

    /// Change the input type of a Diffuser using a transformation function.  The transformation function is always called when `run` is
    /// called on the `diffuser`.
    ///
    /// - Parameter transform: The function which determines how the Diffuser parameters input should be changed.
    /// - Parameter diffuser: The Diffuser you wish to change the input type of.
    /// - Returns: A Diffuser with a transformed input type.
    static func map<B>(
        _ transform: @escaping (A) -> B,
        _ diffuser: Diffuser<B>
    ) -> Diffuser<A> {
        return Diffuser { diffuser.run(transform($0)) }
    }
}

public extension Diffuser where A: Equatable {
    /// Create a Diffuser from a side-effecting function. The Diffuser will cache its inputs using the input type's
    /// definition of equality.
    ///
    /// - Parameter effect: a side-effect which should be run when the input changes
    /// - Returns: A Diffuser which runs side-effect when its input changes.
    static func into(
        _ effect: @escaping Effect<A>
    ) -> Diffuser<A> {
        return Diffuser(
            effect: effect,
            didChange: Diffuser.notEqual
        )
    }

    /// Merge a list of Diffusers parameterized by the same type. The merged Diffuser will only forward calls
    /// to its children if the input changes (according to its own `Equatable` implementation)
    ///
    /// - Parameter children: the list of Diffusers to merge
    /// - Returns: A merged Diffuser which forwards any values it is `run` with to all
    /// its children.
    static func intoAll(
        _ children: [Diffuser<A>]
    ) -> Diffuser<A> {
        return Diffuser(children)
    }

    /// Merge a list of Diffusers parameterized by the same type. The merged Diffuser will only forward calls
    /// to its children if the input changes (according to its own `Equatable` implementation)
    ///
    /// - Parameter children: the list of Diffusers to merge
    /// - Returns: A merged Diffuser which forwards any values it is `run` with to all
    /// its children.
    static func intoAll(
        _ children: Diffuser<A>...
    ) -> Diffuser<A> {
        return Diffuser(children)
    }
}

public extension Diffuser where A == Bool {
    /// Inverts the `Bool` value.
    ///
    /// - Parameter diffuser: The `Diffuser` you wish to invert the value for.
    /// - Returns: A `Diffuser` with an inverted boolean value.
    static func invert(_ diffuser: Diffuser<A>) -> Diffuser<A> {
        return map({ !$0 }, diffuser)
    }
}
