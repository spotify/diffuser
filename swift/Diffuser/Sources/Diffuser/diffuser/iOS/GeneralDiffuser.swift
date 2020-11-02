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

public extension Diffuser {
    // Mark: Visibility

    /// Create a `Diffuser` which will hide `UIView`s when it is run with `true`, and show them otherwise.
    ///
    /// - Parameter views: The relevant `UIView`s
    /// - Returns: A Diffuser which will hide or show a list of `UIView`s if it is run with `true` or `false`
    /// respectively.
    static func hide(_ views: UIView...) -> Diffuser<Bool> {
        return .intoAlways { isHidden in
            views.forEach { view in
                view.isHidden = isHidden
            }
        }
    }

    /// Create a `Diffuser` which will show a list of `UIView`s when it is run with `true`, and hide them otherwise.
    ///
    /// - Parameter views: The relevant `UIView`s
    /// - Returns: A Diffuser which will show or hide a list of `UIView`s if it is run with `true` or `false`
    /// respectively.
    static func show(_ views: UIView...) -> Diffuser<Bool> {
        return .intoAlways { isVisible in
            views.forEach { view in
                view.isHidden = !isVisible
            }
        }
    }

    // Mark: Enabled

    /// Create a `Diffuser` which will enable user interaction for a list of `UIView`s  when it is run with `true`, and
    /// disable them otherwise.
    ///
    /// - Parameter views: The relevant `UIView`s
    /// - Returns: A Diffuser which will enable or disable a list of `UIView`s if it is run with `true` or `false`
    /// respectively.
    static func enableUserInteraction(_ views: UIView...) -> Diffuser<Bool> {
        return .intoAlways { isEnabled in
            views.forEach { view in
                view.isUserInteractionEnabled = isEnabled
            }
        }
    }

    /// Create a `Diffuser` which will disable user interaction for a list of `UIView`s  when it is run with `true`,
    /// and enable them otherwise.
    ///
    /// - Parameter views: The relevant `UIView`s
    /// - Returns: A Diffuser which will disable or enable a list of `UIView`s if it is run with `true` or `false`
    /// respectively.
    static func disableUserInteraction(_ views: UIView...) -> Diffuser<Bool> {
        return .intoAlways { isDisabled in
            views.forEach { view in
                view.isUserInteractionEnabled = !isDisabled
            }
        }
    }
    
    /// Create a `Diffuser` which will enable a list of `UIControl`s  when it is run with `true`, and disable them
    /// otherwise.
    ///
    /// - Note: Each control’s `isEnabled` state will be updated.
    ///
    /// - Parameter controls: The relevant `UIControl`s
    /// - Returns: A Diffuser which will enable or disable a list of `UIControl`s if it is run with `true` or `false`
    /// respectively.
    static func enable(_ controls: UIControl...) -> Diffuser<Bool> {
        .intoAlways { isEnabled in
            controls.forEach { control in
                control.isEnabled = isEnabled
            }
        }
    }
    
    /// Create a `Diffuser` which will disable a list of `UIControl`s  when it is run with `true`, and enable them
    /// otherwise.
    ///
    /// - Note: Each control’s `isEnabled` state will be updated.
    ///
    /// - Parameter controls: The relevant `UIControl`s
    /// - Returns: A Diffuser which will disable or enable a list of `UIControl`s if it is run with `true` or `false`
    /// respectively.
    static func disable(_ controls: UIControl...) -> Diffuser<Bool> {
        .intoAlways { isEnabled in
            controls.forEach { control in
                control.isEnabled = !isEnabled
            }
        }
    }

    // Mark: Color

    /// Create a `Diffuser` which will sets the background color of `UIView`s
    ///
    /// - Parameter views: The relevant `UIView`s
    /// - Returns: A Diffuser which will change the background color of the views it is created with based on the
    /// argument it is run with.
    static func intoBackgroundColor(_ views: UIView...) -> Diffuser<UIColor> {
        return .intoAlways { backgroundColor in
            views.forEach { view in
                view.backgroundColor = backgroundColor
            }
        }
    }
}

#endif
