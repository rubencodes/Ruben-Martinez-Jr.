//
//  FollowerCard.swift
//  Twindr
//
//  Created by Ruben on 12/28/14.
//  Copyright (c) 2014 Ruben. All rights reserved.
//

import Foundation
import UIKit

class ProfileCard : UIView {
    var delegate : ProfileCardDelegate?
    
    var id : String?
    @IBOutlet var image: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var body: UITextView!
    
    var overlay: UIImageView!
    
    var dismissGesture : UIPanGestureRecognizer?
        
    //original centerpoint of view
    var originalPoint : CGPoint?
    
    // distance from center where the action applies. Higher = swipe further in order for the action to be called
    let ACTION_MARGIN = 120 as CGFloat
    // Higher = stronger rotation angle
    let ROTATION_ANGLE = Float(2)*Float(M_PI) as Float
    // strength of rotation. Higher = weaker rotation
    let ROTATION_STRENGTH = 320 as CGFloat
    // the maximum rotation allowed in radians.  Higher = card can keep rotating longer
    let ROTATION_MAX = 1 as CGFloat
    // how quickly the card shrinks. Higher = slower shrinking
    let SCALE_STRENGTH = 4 as Float
    // upper bar for how much the card shrinks. Higher = shrinks less
    let SCALE_MAX = 0.93 as Float
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
        
        self.activateGesture()
        
        //prepare overlay
        self.overlay = UIImageView(frame: self.bounds)
        self.overlay!.alpha = 0
        self.addSubview(self.overlay)
        self.bringSubviewToFront(self.overlay)
    }
    
    func setup() {
        self.layer.cornerRadius = 8
        self.layer.shadowRadius = 1
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSizeMake(0, 0)
    }
    
    func activateGesture() {
        //prepare swipe gesture
        self.dismissGesture = UIPanGestureRecognizer(target: self, action: "dragged:")
        self.addGestureRecognizer(dismissGesture!)
    }
    
    //what to do when card is dragged
    func dragged(gestureRecognizer : UIPanGestureRecognizer) {
        let xDistance = gestureRecognizer.translationInView(self).x
        let yDistance = gestureRecognizer.translationInView(self).y
        let distance  = sqrt(pow(xDistance, 2) + pow(yDistance, 2))
        
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.Began:
            self.originalPoint = self.center
            break
        case UIGestureRecognizerState.Changed:
            let rotationStrength = Float(min(xDistance / ROTATION_STRENGTH, ROTATION_MAX))
            let rotationAngle = ROTATION_ANGLE * rotationStrength / Float(16)
            let scale = CGFloat(max(Float(1) - fabsf(rotationStrength) / SCALE_STRENGTH, SCALE_MAX))
            self.center = CGPointMake(self.originalPoint!.x + xDistance, self.originalPoint!.y + yDistance)
            let transform = CGAffineTransformMakeRotation(CGFloat(rotationAngle))
            let scaleTransform = CGAffineTransformScale(transform, scale, scale)
            self.transform = scaleTransform
            
            //update overlay
            self.updateOverlay(distance)
            
            break
        case UIGestureRecognizerState.Ended:
            //if swipe exceeds margins, perform action, else reset
            self.superview!
            if distance > ACTION_MARGIN {
                self.nextAction(xDistance, yDistance: yDistance)
            } else {
                self.resetViewPositionAndTransformations()
            }
            break
        case UIGestureRecognizerState.Possible:break
        case UIGestureRecognizerState.Cancelled:break
        case UIGestureRecognizerState.Failed:break
        }
    }
    
    func resetViewPositionAndTransformations() {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.center = self.originalPoint!
            self.transform = CGAffineTransformMakeRotation(0)
            self.overlay.alpha = 0
        })
    }
    
    func updateOverlay(distance : CGFloat) {
        overlay.image = UIImage(named: "OverlayYES")
        var overlayStrength = CGFloat(min(fabsf(Float(distance)) / 150, 1))
        self.overlay.alpha = overlayStrength
    }
    
    func nextAction(xDistance : CGFloat, yDistance : CGFloat) {
        let slope = yDistance/xDistance
        let positiveX = xDistance >= 0
        let positiveY = yDistance >= 0
        let finishPoint : CGPoint?
        
        if (!positiveX && !positiveY) || (!positiveX && positiveY) {
            finishPoint = CGPointMake(self.center.x - 300, self.center.y - slope*300)
        } else {
            finishPoint = CGPointMake(self.center.x + 300, self.center.y + slope*300)
        }
        
        UIView.animateWithDuration(0.9,
            animations: {
                () -> Void in
                self.updateOverlay(300)
                self.center = finishPoint!
                self.transform = CGAffineTransformMakeRotation(1)
            }, completion: {
                (Bool) -> Void in
                self.removeFromSuperview()
        })
        
        delegate!.cardSwiped(self)
    }
}

protocol ProfileCardDelegate {
    func cardSwiped(card : ProfileCard)
}