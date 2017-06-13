//
//  PeekPopViewGestureRecognizer.swift
//  PeekPop
//
//  Created by Robert Ogiba on 08.06.2017.
//  Copyright © 2017 Roy Marmelstein. All rights reserved.
//

import UIKit

class PeekPopViewGestureRecognizer: UIGestureRecognizer {
    
    let peekPopView: PeekPopView
    let peekPopManager: PeekPopManager
    
    var sourceView: UIView?
    fileprivate var startPoint: CGPoint?
    fileprivate var containerPositionInView: CGPoint?
    var anchoredToTop: Bool = false
    var initialMajorRadius: CGFloat = 0.0
    
    init(peekPopView: PeekPopView, peekPopManager: PeekPopManager){
        self.peekPopView = peekPopView
        self.peekPopManager = peekPopManager
        super.init(target: nil, action: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first, isTouchValid(touch) {
            let touchLocation = touch.location(in: self.view)
            self.startPoint = touchLocation
            self.containerPositionInView = self.calculatePostion(of: touch, in: self.view?.window)
            self.initialMajorRadius = touch.majorRadius
            self.state = .possible
        } else {
            self.state = .failed
        }

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if let touch = touches.first {
            let loc = touch.location(in: self.view)
            if let _startPoint = startPoint {
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
    
    func testForceChange(_ majorRadius: CGFloat) {
        if initialMajorRadius/majorRadius < 0.6  {
            peekPopManager.delegate?.peekPopManager(changeProgress: 0.99)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        touchesFinishedBehavior()
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        touchesFinishedBehavior()
        super.touchesCancelled(touches, with: event)
    }
    
    func touchesFinishedBehavior() {
        if anchoredToTop {
            peekPopManager.anchorToTop(withValue: -14.0)
        } else {
            peekPopManager.peekPopEnded()
        }
    }

    func isTouchValid(_ touch: UITouch) -> Bool {
        let sourceRect = sourceView?.frame ?? CGRect.zero
        let touchLocation = touch.location(in: self.view?.superview)
        return sourceRect.contains(touchLocation)
    }
}

extension PeekPopViewGestureRecognizer {
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
        if let _bounds = calculateBounds(for: position) {
            if _bounds.maxY <= (peekPopView.frame.height - 10 ){
                return true
            }
        }
        
        return false
    }
    
    func calculateBounds( for position: CGPoint) -> CGRect?{
        guard
            let _startPoint = startPoint else {
                return nil
        }
        let newY = position.y - _startPoint.y
        let newX = position.x - _startPoint.x
        
        let y = containerPositionInView!.y + newY
        let x = containerPositionInView!.x + newX
        
        return CGRect(x: x, y: y, width: peekPopView.targetPreviewView.frame.width, height: peekPopView.targetPreviewView.frame.height)
    }
    
    func checkTouchingTop(for position: CGPoint) -> Bool{
        if let _bounds = calculateBounds(for: position) {
            if _bounds.minY <= 0 {
                return true
            }
        }
        
        return false
    }
}
