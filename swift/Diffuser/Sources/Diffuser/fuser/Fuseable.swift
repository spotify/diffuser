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

/// A `Fuseable` is something which can produce output.
///
/// It has an `Output<Event>`, which it can use to send output. The lifecycle of this `Output` will be managed for you when you implement `Fuseable`.
/// Note that this means that you will not know if anyone is listening to the output that is produced. If you need a more sophisticated lifecycle, declare
/// a local fuser directly instead.
public protocol Fuseable {
    associatedtype Event

    var output: Output<Event> { get }
}

public extension Fuser {
    /// Start a Fuser which receives the output of a `Fuseable`.
    static func fromFuseable<F: Fuseable>(_ fuseable: F) -> Fuser<A> where F.Event == A {
        return fuseable.output.fuser
    }
}

public final class Output<Event> {
    private var outputs: [UUID: ((Event) -> Void)] = [:]
    private(set) public lazy var fuser = Fuser<Event>
        .from { output in
            let uuid = UUID()
            self.outputs[uuid] = output
            return AnonymousDisposable {
                self.outputs[uuid] = nil
            }
        }

    public init() {}

    /// Send an `Event` to anything which is currently connected to the input of this object.
    /// If nothing is connected, the event will be dropped.
    public func send(_ event: Event) {
        outputs.values.forEach { output in
            output(event)
        }
    }
}
