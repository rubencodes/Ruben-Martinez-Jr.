//
//  CustomProgressView.swift
//  Ruben Martinez Jr.
//
//  Created by Ruben on 4/17/15.
//  Copyright (c) 2015 Ruben.Codes. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class ProgressButton : UIButton {
    let greenColor = UIColor(red: 145/255, green: 230/255, blue: 118/255, alpha: 1)
    var parts : Int?
    var part : Int? {
        didSet {
            self.animate()
        }
    }
    var progress : CGFloat {
        return part != nil && parts != nil ? CGFloat(part! + 1)/CGFloat(parts!) : 0
    }
    var foregroundColor : UIColor? {
        didSet {
            self.progressView.backgroundColor = self.foregroundColor
        }
    }
    var progressView = UIView()
    
    func setupProgressView() {
        self.progressView.frame = self.frame
        self.progressView.backgroundColor = self.foregroundColor ?? greenColor
        self.addSubview(self.progressView)
        self.insertSubview(self.progressView, belowSubview: self.titleLabel!)
        self.progressView.setNeedsDisplay()
    }
    
    func progressRect() -> CGRect {
        return CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: progress * self.frame.width, height: self.frame.height))
    }
    
    override func addTarget(target: AnyObject?, action: Selector, forControlEvents controlEvents: UIControlEvents) {
        let tap = UITapGestureRecognizer(target: target!, action: action)
        tap.numberOfTapsRequired = 1

        self.addGestureRecognizer(tap)
    }
    
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    func animate() {
        let finalRect = self.progressRect()

        var animation = POPSpringAnimation(propertyNamed: kPOPLayerScaleX)
        animation.toValue = finalRect.width/self.frame.width
        animation.springBounciness = 15
        
        self.progressView.frame.origin = CGPointZero
        self.progressView.layer.position = self.progressView.frame.origin
        self.progressView.layer.anchorPoint = CGPointZero
        self.progressView.layer.pop_addAnimation(animation, forKey: "grow")
    }
}