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

#if canImport(UIKit)

import UIKit

/// Generic Wrapper for Objective-C's target:selector: APIs
class Action<Input>: NSObject {

    private let action: (Input) -> Void
    let selector: Selector

    init(_ action: @escaping (Input) -> Void) {
        self.action = action
        self.selector = #selector(run(_:))
    }

    // `Any` is required here due to Objective-C. The safety of the down-cast is verified in the initializer
    @objc private func run(_ input: Any) {
        action(input as! Input)
    }
}

#endif
