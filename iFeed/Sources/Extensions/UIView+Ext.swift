//
//  UIView+Ext.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    /// Adds a fade `CATransition` to the view's layer with the specified duration and ease-in-ease-out timing.
    /// Does nothing if a fade animation is already in progress on this layer.
    /// - Parameter duration: The length of the fade transition, in seconds.
    func fadeTransition(_ duration: CFTimeInterval) {
        let animationKey = CATransitionType.fade.rawValue

        guard layer.animation(forKey: animationKey) == nil else {
            return
        }

        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration

        layer.add(animation, forKey: animationKey)
    }
}
