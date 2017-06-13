//
//  PeekPopGestureRecognizer.swift
//  PeekPop
//
//  Created by Roy Marmelstein on 06/03/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class PeekPopGestureRecognizer: UIGestureRecognizer
{
    
    var context: PreviewingContext?
    let peekPopManager: PeekPopManager
    
    let interpolationSpeed: CGFloat = 0.02
    let previewThreshold: CGFloat = 0.66
    let commitThreshold: CGFloat = 0.99
    
    var progress: CGFloat = 0.0
    var targetProgress: CGFloat = 0.0 {
        didSet { updateProgress() }
    }
    
    var initialMajorRadius: CGFloat = 0.0
    var displayLink: CADisplayLink?
    
    var peekPopStarted = false
    var startPoint: CGPoint?
    var containerPostionInView: CGPoint?
    var anchoredToTop: Bool = false
    
    //MARK: Lifecycle
    
    init(peekPop: PeekPop) {
        self.peekPopManager = PeekPopManager(peekPop: peekPop)
        super.init(target: nil, action: nil)
    }
    
    //MARK: Touch handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent)
    {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first, let context = context, isTouchValid(touch)
        {
            let touchLocation = touch.location(in: self.view)
            self.startPoint = touchLocation
            self.containerPostionInView = self.calculatePostion(of: touch, in: self.view?.window)
            
            self.state = (context.delegate?.previewingContext(context, viewControllerForLocation: touchLocation) != nil) ? .possible : .failed
            if self.state == .possible {
                self.perform(#selector(delayedFirstTouch), with: touch, afterDelay: 0.2)
            }
        }
        else {
            self.state = .failed
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent)
    {
        super.touchesMoved(touches, with: event)
        if(self.state == .possible){
            self.cancelTouches()
        }
        if let touch = touches.first, peekPopStarted == true {
            if let loc = touches.first?.location(in: self.view), let _startPoint = startPoint {
                let newY = loc.y - _startPoint.y
                
                if checkBoundary(for: loc){
                    self.peekPopManager.moveView(byY: newY)
                    
                    let touchingTop = checkTouchingTop(for: loc)
                    
                    self.anchoredToTop = touchingTop
                    self.peekPopManager.changeButton(availability: touchingTop)
                }
            }
            testForceChange(touch.majorRadius)
        }
    }
    
    func delayedFirstTouch(_ touch: UITouch) {
        if isTouchValid(touch) {
            self.state = .began
            if let context = context {
                let touchLocation = touch.location(in: self.view)
                _ = peekPopManager.peekPopPossible(context, touchLocation: touchLocation)
                context.delegate?.previewingContext?(context, peekPopShown: true)
            }
            peekPopStarted = true
            initialMajorRadius = touch.majorRadius
            peekPopManager.peekPopBegan(context)
            targetProgress = previewThreshold
            
            
        }
    }
    
    func testForceChange(_ majorRadius: CGFloat) {
        if initialMajorRadius/majorRadius < 0.6  {
            targetProgress = 0.99
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if !anchoredToTop {
            self.cancelTouches()
        } else {
            self.peekPopManager.anchorToTop(withValue: -14.0)
        }
        
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        if !anchoredToTop {
            self.cancelTouches()
        } else {
            self.peekPopManager.anchorToTop(withValue: -14.0)
        }
        
        super.touchesCancelled(touches, with: event)
    }
    
    func resetValues() {
        self.startPoint = nil
        self.containerPostionInView = nil
        self.anchoredToTop = false
        self.state = .cancelled
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        peekPopStarted = false
        progress = 0.0
        
        if let _context = context {
            _context.delegate?.previewingContext?(_context, peekPopShown: false)
        }
    }
    
    func cancelTouches() {
        self.startPoint = nil
        self.containerPostionInView = nil
        self.anchoredToTop = false
        self.state = .cancelled
        peekPopStarted = false
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if progress < commitThreshold {
            targetProgress = 0.0
        }
    }
    
    func isTouchValid(_ touch: UITouch) -> Bool {
        let sourceRect = context?.sourceView.frame ?? CGRect.zero
        let touchLocation = touch.location(in: self.view?.superview)
        return sourceRect.contains(touchLocation)
    }
    
    func updateProgress() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(animateToTargetProgress))
        displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
    }
    
    func animateToTargetProgress() {
        if progress < targetProgress {
            progress = min(progress + interpolationSpeed, targetProgress)
            if progress >= targetProgress {
                displayLink?.invalidate()
            }
        }
        else {
            progress = max(progress - interpolationSpeed*2, targetProgress)
            if progress <= targetProgress {
                progress = 0.0
                displayLink?.invalidate()
                peekPopManager.peekPopEnded()
            }
        }
        peekPopManager.animateProgressForContext(progress, context: context)
    }
}

extension PeekPopGestureRecognizer {
    func calculatePostion(of touch: UITouch, in window: UIWindow?) -> CGPoint?{
        guard let _startPoint = startPoint else {
            return nil
        }
        
        let touchWindowLocation = touch.location(in: window)
        let newY = touchWindowLocation.y - _startPoint.y
        let newX = touchWindowLocation.x - _startPoint.x
        return CGPoint(x: newX, y: newY)
    }
    
    func checkBoundary(for position: CGPoint) -> Bool{
        guard let _peekPopView = peekPopManager.peekPopView else {
            return false
        }
        
        if let _bounds = calculateBounds(for: position) {
            if _bounds.maxY <= (_peekPopView.frame.height - 10 ){
                return true
            }
        }
        
        return false
    }
    
    func calculateBounds( for position: CGPoint) -> CGRect?{
        guard
            let _startPoint = startPoint,
            let _peekPopView = peekPopManager.peekPopView else {
            return nil
        }
        let newY = position.y - _startPoint.y
        let newX = position.x - _startPoint.x
        
        let y = containerPostionInView!.y + newY
        let x = containerPostionInView!.x + newX
        
        return CGRect(x: x, y: y, width: _peekPopView.targetPreviewView.frame.width, height: _peekPopView.targetPreviewView.frame.height)
    }
    
    func checkTouchingTop(for position: CGPoint) -> Bool{
        if let _bounds = calculateBounds(for: position) {
            if _bounds.minY <= 20 {
                return true
            }
        }

        return false
    }
}
