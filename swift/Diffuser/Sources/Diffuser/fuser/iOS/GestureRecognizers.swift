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

/// Fuser wrappers for all UIGestureRecognizers

public extension Fuser {
    /// Create a `Fuser` of `UITapGestureRecognizer`s for an arbitrary UIView.
    ///
    /// - Parameter view: The view to listen to
    /// - Returns: A fuser of `UITapGestureRecognizer`s
    static func fromTaps(_ view: UIView) -> Fuser<UITapGestureRecognizer> {
        return fromGestures(view, UITapGestureRecognizer.init)
    }

    /// Create a `Fuser` of `UIPinchGestureRecognizer`s for an arbitrary UIView.
    ///
    /// - Parameter view: The view to listen to
    /// - Returns: A fuser of `UIPinchGestureRecognizer`s
    static func fromPinches(_ view: UIView) -> Fuser<UIPinchGestureRecognizer> {
        return fromGestures(view, UIPinchGestureRecognizer.init)
    }

    /// Create a `Fuser` of `UIRotationGestureRecognizer`s for an arbitrary UIView.
    ///
    /// - Parameter view: The view to listen to
    /// - Returns: A fuser of `UIRotationGestureRecognizer`s
    static func fromRotations(_ view: UIView) -> Fuser<UIRotationGestureRecognizer> {
        return fromGestures(view, UIRotationGestureRecognizer.init)
    }

    /// Create a `Fuser` of `UISwipeGestureRecognizer`s for an arbitrary UIView.
    ///
    /// - Parameter view: The view to listen to
    /// - Returns: A fuser of `UISwipeGestureRecognizer`s
    static func fromSwipes(_ view: UIView) -> Fuser<UISwipeGestureRecognizer> {
        return fromGestures(view, UISwipeGestureRecognizer.init)
    }

    /// Create a `Fuser` of `UIPanGestureRecognizer`s for an arbitrary UIView.
    ///
    /// - Parameter view: The view to listen to
    /// - Returns: A fuser of `UIPanGestureRecognizer`s
    static func fromPans(_ view: UIView) -> Fuser<UIPanGestureRecognizer> {
        return fromGestures(view, UIPanGestureRecognizer.init)
    }

    /// Create a `Fuser` of `UIScreenEdgePanGestureRecognizer`s for an arbitrary UIView.
    ///
    /// - Parameter view: The view to listen to
    /// - Returns: A fuser of `UIScreenEdgePanGestureRecognizer`s
    static func fromScreenEdgePans(_ view: UIView) -> Fuser<UIScreenEdgePanGestureRecognizer> {
        return fromGestures(view, UIScreenEdgePanGestureRecognizer.init)
    }

    /// Create a `Fuser` of `UILongPressGestureRecognizer`s for an arbitrary UIView.
    ///
    /// - Parameter view: The view to listen to
    /// - Returns: A fuser of `UILongPressGestureRecognizer`s
    static func fromLongPresses(_ view: UIView) -> Fuser<UILongPressGestureRecognizer> {
        return fromGestures(view, UILongPressGestureRecognizer.init)
    }

    /// Create a `Fuser` of a supplied subclass of `UIGestureRecognizer`s.
    ///
    /// It is likely better to use one of the other gesture recognizer `Fuser`s instead, such as `fromTaps`.
    static func fromGestures<Gesture: UIGestureRecognizer>(
        _ view: UIView,
        _ gesture: @escaping () -> Gesture
    ) -> Fuser<Gesture> {
        return .from { (dispatch: @escaping Effect<Gesture>) in
            let action = Action<Gesture>(dispatch)
            let recognizer = gesture()
            recognizer.addTarget(action, action: action.selector)
            view.addGestureRecognizer(recognizer)
            return AnonymousDisposable {
                view.removeGestureRecognizer(recognizer)
                recognizer.removeTarget(action, action: action.selector)
            }
        }
    }
}

#endif
