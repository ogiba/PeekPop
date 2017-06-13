//
//  PeekPopControllerView.swift
//  PeekPop
//
//  Created by Robert Ogiba on 06.06.2017.
//  Copyright © 2017 Roy Marmelstein. All rights reserved.
//

import UIKit

class PeekPopControllerView: PeekPopView {
    var targetVC: UIViewController?
    
    override func setup() {
        self.targetPreviewView = PeekPopTargetPreviewControllerView()
        
        self.addSubview(blurredBaseImageView)
        self.addSubview(blurredImageViewFirst)
        self.addSubview(blurredImageViewSecond)
        self.addSubview(overlayView)
        self.addSubview(sourceImageView)
        self.addSubview(targetPreviewView)
        self.addSubview(button)
    }
    
    override func didAppear() {
        blurredBaseImageView.frame = self.bounds
        blurredImageViewFirst.frame = self.bounds
        blurredImageViewSecond.frame = self.bounds
        overlayView.frame = self.bounds
        
        targetPreviewView.frame.size = sourceViewRect.size
        if let _vc = targetVC {
            (targetPreviewView as? PeekPopTargetPreviewControllerView)?.targetVC = _vc
            (targetPreviewView as? PeekPopTargetPreviewControllerView)?.controllerContainer.addSubview(_vc.view)
        }
        
        sourceImageView.frame = sourceViewRect
        sourceImageView.image = sourceViewScreenshot
        
        sourceViewCenter = CGPoint(x: sourceViewRect.origin.x + sourceViewRect.size.width/2, y: sourceViewRect.origin.y + sourceViewRect.size.height/2)
        sourceToCenterXDelta = self.bounds.size.width/2 - sourceViewCenter.x
        sourceToCenterYDelta = self.bounds.size.height/2 - sourceViewCenter.y
        sourceToTargetWidthDelta = self.bounds.size.width - targePreviewPadding.width - sourceViewRect.size.width
        sourceToTargetHeightDelta = self.bounds.size.height - targePreviewPadding.height - sourceViewRect.size.height
        
        if buttonAvailable {
            setupButton()
        }
    }
    
    override func changeLayer() {
         (targetPreviewView as? PeekPopTargetPreviewControllerView)?.container.layer.cornerRadius = 0
    }
    
    override func moveContainer(by newPosition: CGPoint) {
        (targetPreviewView as? PeekPopTargetPreviewControllerView)?.container.frame.origin = newPosition
    }
    
    override func moveContainer(byX x: CGFloat, y: CGFloat) {
        (targetPreviewView as? PeekPopTargetPreviewControllerView)?.container.frame.origin = CGPoint(x: x, y: y)
    }
    
    override func anchorToTop(withValue value: CGFloat = 0) {
        UIView.animate(withDuration: 0.4) {[weak self]() in
            (self?.targetPreviewView as? PeekPopTargetPreviewControllerView)?.container.frame.origin = CGPoint(x: 0, y: value)
        }
        
        initializeGestureRecognizer()
    }
}

class PeekPopTargetPreviewControllerView: PeekPopTargetPreviewView {
    var container = UIView()
    var controllerContainer = UIView()
    var targetVC:UIViewController?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        container.frame = self.bounds
        controllerContainer.frame = self.bounds
        controllerContainer.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        
        if let _vc = targetVC {
            _vc.view.frame = self.bounds
        }
    }
    
    override func setup() {
        self.addSubview(container)
        container.layer.cornerRadius = 15
        container.clipsToBounds = true
        container.addSubview(controllerContainer)
        controllerContainer.isUserInteractionEnabled = false
    }
}
