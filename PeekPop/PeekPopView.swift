//
//  PeekPopView.swift
//  PeekPop
//
//  Created by Roy Marmelstein on 09/03/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import UIKit

class PeekPopView: UIView {
    
    //MARK: Constants
    
    // These are 'magic' values
    let targePreviewPadding = CGSize(width: 28, height: 140)
    
    var sourceViewCenter = CGPoint.zero
    var sourceToCenterXDelta: CGFloat = 0.0
    var sourceToCenterYDelta: CGFloat = 0.0
    var sourceToTargetWidthDelta: CGFloat = 0.0
    var sourceToTargetHeightDelta: CGFloat = 0.0
    
    var showActionButton: Bool = false
    var delegate: PeekPopViewDelegate?
    var gestureInitialized: Bool = false

    //MARK: Screenshots
    
    var viewControllerScreenshot: UIImage? = nil {
        didSet {
            blurredScreenshots.removeAll()
        }
    }
    var targetViewControllerScreenshot: UIImage? = nil
    var sourceViewScreenshot: UIImage?
    var blurredScreenshots = [UIImage]()
    
    var sourceViewRect = CGRect.zero
    
    //MARK: Subviews

    // Blurry image views, used for interpolation
    var blurredBaseImageView = UIImageView()
    var blurredImageViewFirst = UIImageView()
    var blurredImageViewSecond = UIImageView()
    
    //Action button
    var button = UIButton()
    
    // Overlay view
    var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.85, alpha: 0.5)
        return view
    }()
    
    // Source image view
    var sourceImageView = UIImageView()
    
    // Target preview view
    var targetPreviewView = PeekPopTargetPreviewView()

    //MARK: Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    
    func setup() {
        self.addSubview(blurredBaseImageView)
        self.addSubview(blurredImageViewFirst)
        self.addSubview(blurredImageViewSecond)
        self.addSubview(overlayView)
        self.addSubview(sourceImageView)
        self.addSubview(targetPreviewView)
    }
    
    func didAppear() {
        blurredBaseImageView.frame = self.bounds
        blurredImageViewFirst.frame = self.bounds
        blurredImageViewSecond.frame = self.bounds
        overlayView.frame = self.bounds
        
        targetPreviewView.frame.size = sourceViewRect.size
        targetPreviewView.imageViewFrame = self.bounds
        targetPreviewView.imageView.image = targetViewControllerScreenshot
   
        sourceImageView.frame = sourceViewRect
        sourceImageView.image = sourceViewScreenshot
        
        sourceViewCenter = CGPoint(x: sourceViewRect.origin.x + sourceViewRect.size.width/2, y: sourceViewRect.origin.y + sourceViewRect.size.height/2)
        sourceToCenterXDelta = self.bounds.size.width/2 - sourceViewCenter.x
        sourceToCenterYDelta = self.bounds.size.height/2 - sourceViewCenter.y
        sourceToTargetWidthDelta = self.bounds.size.width - targePreviewPadding.width - sourceViewRect.size.width
        sourceToTargetHeightDelta = self.bounds.size.height - targePreviewPadding.height - sourceViewRect.size.height
        
        setupButton()
    }
    
    func setupButton() {
        guard showActionButton else {
            button.isHidden = true
            return
        }
        
        button.isHidden = true
        button.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7)
        button.frame = CGRect(x: 0.0, y: 0.0, width: sourceViewRect.size.width + sourceToTargetWidthDelta, height: 50.0)
        button.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height + button.frame.size.height)
        button.layer.cornerRadius = 15.0
        button.setTitleColor(UIColor(red:0.00, green:0.53, blue:0.76, alpha:1.00), for: .normal)
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
    }
    
    func animateProgressiveBlur(_ progress: CGFloat) {
        if blurredScreenshots.count > 2 {
            let blur = progress*CGFloat(blurredScreenshots.count - 1)
            let blurIndex = Int(blur)
            let blurRemainder = blur - CGFloat(blurIndex)
            blurredBaseImageView.image = blurredScreenshots.last
            blurredImageViewFirst.image = blurredScreenshots[blurIndex]
            blurredImageViewSecond.image = blurredScreenshots[blurIndex + 1]
            blurredImageViewSecond.alpha = CGFloat(blurRemainder)
        }
    }
    
    func animateProgress(_ progress: CGFloat) {
        
        sourceImageView.isHidden = progress > 0.33
        targetPreviewView.isHidden = progress < 0.33

        // Source rect expand stage
        if progress < 0.33 {
            let adjustedProgress = min(progress*3,1.0)
            animateProgressiveBlur(adjustedProgress)
            let adjustedScale: CGFloat = 1.0 - CGFloat(adjustedProgress)*0.015
            let adjustedSourceImageScale: CGFloat = 1.0 + CGFloat(adjustedProgress)*0.015
            blurredImageViewFirst.transform = CGAffineTransform(scaleX: adjustedScale, y: adjustedScale)
            blurredImageViewSecond.transform = CGAffineTransform(scaleX: adjustedScale, y: adjustedScale)
            overlayView.alpha = CGFloat(adjustedProgress)
            sourceImageView.transform = CGAffineTransform(scaleX: adjustedSourceImageScale, y: adjustedSourceImageScale)
        }
        // Target preview reveal stage
        else if progress < 0.45 {
            let targetAdjustedScale: CGFloat = min(CGFloat((progress - 0.33)/0.1), CGFloat(1.0))
            targetPreviewView.frame.size = CGSize(width: sourceViewRect.size.width + sourceToTargetWidthDelta*targetAdjustedScale, height: sourceViewRect.size.height + sourceToTargetHeightDelta*targetAdjustedScale)
            targetPreviewView.center = CGPoint(x: sourceViewCenter.x + sourceToCenterXDelta*targetAdjustedScale, y: sourceViewCenter.y + sourceToCenterYDelta*targetAdjustedScale)
        }
        // Target preview expand stage
        else if progress < 0.96 {
            let targetAdjustedScale = min(CGFloat(1 + (progress-0.66)/6),1.1)
            targetPreviewView.transform = CGAffineTransform(scaleX: targetAdjustedScale, y: targetAdjustedScale)
        }
        // Commit target view controller
        else {
            targetPreviewView.frame = self.bounds
            self.changeLayer()
        }
    }
    
    func changeLayer() {
        targetPreviewView.imageContainer.layer.cornerRadius = 0
    }
}

extension PeekPopView {
    func moveContainer(by newPosition: CGPoint) {
        targetPreviewView.imageContainer.frame.origin = newPosition
    }
    
    func moveContainer(byX x: CGFloat, y: CGFloat) {
        targetPreviewView.imageContainer.frame.origin = CGPoint(x: x, y: y)
    }
    
    func anchorToTop(withValue value: CGFloat = 0) {
        UIView.animate(withDuration: 0.4) {[weak self]() in
            self?.targetPreviewView.imageContainer.frame.origin = CGPoint(x: 0, y: value)
        }
        
        initializeGestureRecognizer()
    }
    
    func showButton() {
        if showActionButton {
            button.isHidden = false
        }
        
        UIView.animate(withDuration: 0.4) {[weak self]() in
            if let shouldShow =  self?.showActionButton, shouldShow {
                if let _boundsHeight = self?.bounds.size.height, let _buttonHeight = self?.button.frame.size.height, let _buttonXPosition = self?.button.center.x {
                    self?.button.center = CGPoint(x: _buttonXPosition, y: _boundsHeight - _buttonHeight + 10.0)
                }
            }
        }
    }
    
    func hideButton() {
        guard showActionButton else {
            button.isHidden = true
            return
        }
        
        UIView.animate(withDuration: 0.4) {[weak self]() in
            if let _boundsHeight = self?.bounds.size.height, let _buttonHeight = self?.button.frame.size.height, let _buttonXPosition = self?.button.center.x {
                self?.button.center = CGPoint(x: _buttonXPosition, y: _boundsHeight + _buttonHeight)
            }
        }
    }
    
    func buttonAction(_ sender: UIButton) {
        self.delegate?.peekPopView?(tapped: sender)
    }
}

//MARK: UIGestureRecognizer
extension PeekPopView: UIGestureRecognizerDelegate {
    func initializeGestureRecognizer() {
        if !gestureInitialized {
            self.gestureInitialized = self.delegate?.peekPopView?(initializeGestureRecognizerFor: self) ?? false
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == button {
            return false
        } else {
            return true
        }
    }
}

class PeekPopTargetPreviewView: UIView {
    
    var imageContainer = UIImageView()
    var imageView = UIImageView()
    var imageViewFrame = CGRect.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageContainer.frame = self.bounds
        imageView.frame = imageViewFrame
        imageView.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
    }
    
    func setup() {
        self.addSubview(imageContainer)
        imageContainer.layer.cornerRadius = 15
        imageContainer.clipsToBounds = true
        imageContainer.addSubview(imageView)
    }
}

@objc
protocol PeekPopViewDelegate: class {
    func peekPopView(actionTapped tapped: Bool)
    
    @objc optional func peekPopView(initializeGestureRecognizerFor view: PeekPopView) -> Bool
    
    @objc optional func peekPopView(tapped button: UIButton)
}
