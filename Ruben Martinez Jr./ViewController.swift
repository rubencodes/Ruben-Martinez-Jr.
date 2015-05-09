//
//  ViewController.swift
//  Ruben Martinez Jr.
//
//  Created by Ruben on 4/14/15.
//  Copyright (c) 2015 Ruben.Codes. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ProfileCardDelegate, UINavigationBarDelegate, UIGestureRecognizerDelegate {
    let ProfileCardNib = UINib(nibName: "ProfileCard", bundle: NSBundle.mainBundle())
    let HEADER_BOTTOM = 69
    let MAX_DECK_SIZE = 10
    let CARD_HEIGHT = 330 as Int
    let CARD_WIDTH = 300 as Int
    var buttonNext: ProgressButton?
    
    var cardX : Int? {
        //X is half of total width minus notification width
        return (Int(self.view.frame.width) - self.CARD_WIDTH)/2
    }
    var cardY : Int? {
        //Y is half the midpoint between header's bottom and button's top minus half the height of the card
        return (self.HEADER_BOTTOM + Int(self.view.frame.height - (self.buttonNext?.frame.height ?? 0)))/2 - self.CARD_HEIGHT/2
    }
    var about : NSArray?
    
    var currentCard = 0
    var lastCardSwiped : Int?
    
    var delegate = UIApplication.sharedApplication().delegate! as! AppDelegate
    var deck : [ProfileCard] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let unswipeL = UIScreenEdgePanGestureRecognizer(target: self, action: "unswipe:")
        unswipeL.edges = UIRectEdge.Left
        unswipeL.minimumNumberOfTouches = 1
        unswipeL.maximumNumberOfTouches = 1
        
        let unswipeR = UIScreenEdgePanGestureRecognizer(target: self, action: "unswipe:")
        unswipeR.edges = UIRectEdge.Right
        unswipeR.minimumNumberOfTouches = 1
        unswipeR.maximumNumberOfTouches = 1
        
        self.view.addGestureRecognizer(unswipeL)
        self.view.addGestureRecognizer(unswipeR)
        
        self.setupButton()
        self.loadInfo()
    }
    
    func setupButton() {
        let buttonHeight = self.view.frame.height * 0.10
        
        let YESframe = CGRect(x: 0, y: self.view.frame.height - buttonHeight, width: self.view.frame.width, height: buttonHeight)

        self.buttonNext = ProgressButton()
        self.buttonNext!.frame = YESframe
        self.buttonNext!.setupProgressView()
        self.buttonNext!.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
        self.buttonNext!.setTitle("Next", forState: UIControlState.Normal)
        self.buttonNext!.backgroundColor = UIColor(red: 107/255, green: 188/255, blue: 82/255, alpha: 1)
        self.buttonNext!.addTarget(self, action: "tapNext", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(self.buttonNext!)
        self.buttonNext!.setNeedsDisplay()
    }
    
    var lastSwipeLocation : CGPoint?
    func unswipe(sender : UIScreenEdgePanGestureRecognizer) {
        if let cardNumber = lastCardSwiped { //if we have a last swiped card
            if sender.state == UIGestureRecognizerState.Began || sender.state == UIGestureRecognizerState.Changed {
                let touch = sender.locationOfTouch(0, inView: self.view)
                let x = sender.edges == UIRectEdge.Right ? touch.x : touch.x - CGFloat(self.CARD_WIDTH)
                let y = touch.y - CGFloat(self.CARD_HEIGHT/2)
                let frame = CGRect(x: x, y: y, width: CGFloat(self.CARD_WIDTH), height: CGFloat(self.CARD_HEIGHT))
                
                if sender.state == UIGestureRecognizerState.Began { //side swipe began, insert card
                    let card = createCardNumber(cardNumber, withFrame: frame)
                    self.view.insertSubview(card, aboveSubview: self.deck.first!)
                    
                    self.deck = [card] + self.deck //add new card to top of deck
                }
                if sender.state == UIGestureRecognizerState.Changed { //user is dragging card, move it
                    let card = deck.first!
                    card.frame = frame
                    lastSwipeLocation = touch
                }
            } else if sender.state == UIGestureRecognizerState.Ended { //finished dragging, move card to center
                let card = deck.first!
                let cardOnLeft = lastSwipeLocation!.x < CGFloat(self.cardX!)
                let cardOnRight = lastSwipeLocation!.x > CGFloat(self.cardX! + self.CARD_WIDTH)
                if !cardOnLeft && !cardOnRight  {
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        card.frame = CGRect(x: self.cardX!, y: self.cardY!, width: self.CARD_WIDTH, height: self.CARD_HEIGHT)
                        card.transform = CGAffineTransformMakeRotation(0)
                    })
                    
                    lastCardSwiped = lastCardSwiped! > 0 ? lastCardSwiped! - 1 : nil
                    
                    self.deck.last!.removeFromSuperview()
                    self.deck.removeLast()
                    currentCard -= 1
                    
                    self.buttonNext!.part  = self.deck.first!.tag
                    self.buttonNext!.setNeedsDisplay()
                } else {
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        if cardOnLeft {
                            card.frame = CGRect(x: card.frame.origin.x - 300, y: card.frame.origin.y, width: CGFloat(self.CARD_WIDTH), height: CGFloat(self.CARD_HEIGHT))
                        } else {
                            card.frame = CGRect(x: card.frame.origin.x + 300, y: card.frame.origin.y, width: CGFloat(self.CARD_WIDTH), height: CGFloat(self.CARD_HEIGHT))
                        }
                        
                        card.transform = CGAffineTransformMakeRotation(0)
                    }) { (complete) in
                        //remove the card we added
                        self.deck.first!.removeFromSuperview()
                        self.deck.removeAtIndex(0)
                    }
                }
            }
        }
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition  {
        return UIBarPosition.TopAttached
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadInfo() {
        //load in card data
        if let path = NSBundle.mainBundle().pathForResource("About", ofType: "plist") {
            about = NSArray(contentsOfFile: path)
        }
        if let dict = about {
            //activate inital cards
            for i in 1...2 {
                self.addCardToDeck()
            }
            self.deck.first!.activateGesture()
            
            self.buttonNext!.parts = dict.count
            self.buttonNext!.part  = 0
            self.buttonNext!.setNeedsDisplay()
        }
    }
    
    func addCardToDeck() {
        let cardNumber = currentCard%about!.count
        let card = createCardNumber(cardNumber, withFrame: CGRect(x: cardX!, y: cardY!, width: self.CARD_WIDTH, height: self.CARD_HEIGHT))
        
        //add card to view behind last card and display
        if self.deck.isEmpty {
            self.view.addSubview(card)
        } else {
            self.view.insertSubview(card, belowSubview: self.deck.last!)
        }
        
        //store card for later
        self.deck.append(card)
        
        currentCard++
    }
    
    func createCardNumber(number : Int, withFrame frame : CGRect) -> ProfileCard {
        let thisCardInfo = about![number] as! NSDictionary
        
        //load deck
        var card = self.ProfileCardNib.instantiateWithOwner(self, options: nil).first! as! ProfileCard
        card.delegate = self
        card.tag = number
        
        card.frame = frame
        self.addParallax(card)
        card.image.image = UIImage(named: (thisCardInfo["Image"] ?? "Me") as! String)
        card.title.text = thisCardInfo["Title"] as? String ?? ""
        card.body.text  = thisCardInfo["Body"]  as? String ?? "N/A"
        card.body.textAlignment = NSTextAlignment.Center
        card.body.font = UIFont.systemFontOfSize(16)
        card.setNeedsDisplay()
        
        return card
    }
    
    func tapNext() {
        let card = self.deck.first!
        card.nextAction(-300, yDistance: 0)
    }
    
    func cardSwiped(card : ProfileCard) {
        lastCardSwiped = self.deck[0].tag
        //remove card from deck
        self.deck.removeAtIndex(0)
        
        //begin gesture recognition
        self.deck.first!.activateGesture()
        self.buttonNext!.part = self.deck.first!.tag
        
        if self.deck.count == 1 {
            self.addCardToDeck()
        }
    }
    
    @IBAction func showLinks() {
        let prompt = UIAlertController(title: "Links", message: "Visit these pages to connect with Ruben!", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let twitter = UIAlertAction(title: "Twitter", style: UIAlertActionStyle.Default) { (action) -> Void in
            "http://twitter.com/rubencodes".openURL()
            return
        }
        let linkedin = UIAlertAction(title: "LinkedIn", style: UIAlertActionStyle.Default) { (action) -> Void in
            "http://linkedin.com/in/rubencodes".openURL()
            return
        }
        let github = UIAlertAction(title: "GitHub", style: UIAlertActionStyle.Default) { (action) -> Void in
            "http://github.com/rubencodes".openURL()
            return
        }
        
        let website = UIAlertAction(title: "Ruben's Website", style: UIAlertActionStyle.Default) { (action) -> Void in
            "http://ruben.codes".openURL()
            return
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        prompt.addAction(twitter)
        prompt.addAction(linkedin)
        prompt.addAction(github)
        prompt.addAction(website)
        prompt.addAction(cancel)
        self.presentViewController(prompt, animated: true, completion: nil)
    }
    
    @IBAction func showContactOptions() {
        let prompt = UIAlertController(title: "Contact", message: "Job offer? Award to present? Contact Ruben via these methods!", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let email = UIAlertAction(title: "Email", style: UIAlertActionStyle.Default) { (action) -> Void in
            "mailto:ruben.martinez93@gmail.com".openURL()
            return
        }
        let phone = UIAlertAction(title: "Phone", style: UIAlertActionStyle.Default) { (action) -> Void in
            "tel:2108600656".openURL()
            return
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        prompt.addAction(email)
        prompt.addAction(phone)
        prompt.addAction(cancel)
        self.presentViewController(prompt, animated: true, completion: nil)
    }
    
    func addParallax(myView : UIView) {
        // Set vertical effect
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y",
            type: .TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -20
        verticalMotionEffect.maximumRelativeValue = 20
        
        // Set horizontal effect
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x",
            type: .TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -20
        horizontalMotionEffect.maximumRelativeValue = 20
        
        // Create group to combine both
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        // Add both effects to your view
        myView.addMotionEffect(group)
    }
}

extension String {
    func openURL() {
        if let url = NSURL(string: self) {
            UIApplication.sharedApplication().openURL(url)
        } else {
            print("Error - Invalid URL")
        }
    }
}