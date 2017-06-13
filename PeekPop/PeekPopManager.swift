//
//  PeekPopManager.swift
//  PeekPop
//
//  Created by Roy Marmelstein on 12/03/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation

class PeekPopManager {
    
    let peekPop: PeekPop
    
    var viewController: UIViewController { get {return peekPop.viewController} }
    var targetViewController: UIViewController?
    var delegate: PeekPopManagerDelegate?
    
    var peekPopView: PeekPopView?
    lazy var peekPopWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = UIWindowLevelAlert
        let viewController = PeekPopViewController()
        window.rootViewController = viewController
        return window
    }()

    init(peekPop: PeekPop) {
        self.peekPop = peekPop
        self.delegate = peekPop
    }
    
    //MARK: PeekPop
    
    /// Prepare peek pop view if peek and pop gesture is possible
    func peekPopPossible(_ context: PreviewingContext, touchLocation: CGPoint) -> Bool {
        
        // Return early if no target view controller is provided by delegate method
        guard let targetVC = context.delegate?.previewingContext(context, viewControllerForLocation: touchLocation) else {
            return false
        }
        
        // Create PeekPopView
        let view: PeekPopView
        
        if peekPop.useViewControllerPreview {
            view = PeekPopControllerView()
        } else {
            view = PeekPopView()
        }
        
        view.delegate = self
        view.showActionButton = peekPop.showActionButton
        
        if let title = context.delegate?.previewingContext?(context, actionTitleFor: targetVC) {
            view.button.setTitle(title, for: .normal)
        }
        
        if let state = context.delegate?.previewingContext?(context, targetViewController: targetVC, buttonAvability: view.buttonAvailable) {
            view.buttonAvailable = state
        }
        
        if let buttonAction = context.delegate?.previewingContext?(context, targetViewController: targetVC) {
            view.buttonAction = buttonAction
        }
        
        peekPopView = view

        let snappedView: UIView
        var screenShotImage: UIImage?
        
        snappedView = peekPop.blurOnlyCurrentView ? viewController.view : UIApplication.shared.keyWindow ?? viewController.view
        screenShotImage = snappedView.screenshotView()
        
        // Take view controller screenshot
        if let viewControllerScreenshot = screenShotImage {
            peekPopView?.viewControllerScreenshot = viewControllerScreenshot
            peekPopView?.blurredScreenshots = self.generateBlurredScreenshots(viewControllerScreenshot)
        }
        
        // Take source view screenshot
        let rect = snappedView.convert(context.sourceRect, from: context.sourceView)
        peekPopView?.sourceViewScreenshot = snappedView.screenshotView(true, rect: rect)
        peekPopView?.sourceViewRect = snappedView.convert(rect, to: nil)

        // Take target view controller screenshot
        targetVC.view.frame = viewController.view.bounds
        
        if let _view = peekPopView as? PeekPopControllerView {
            _view.targetVC = targetVC
        } else {
            peekPopView?.targetViewControllerScreenshot = targetVC.view.screenshotView(false)
        }
        targetViewController = targetVC
        return true
    }
    
    func generateBlurredScreenshots(_ image: UIImage) -> [UIImage] {
        var images = [UIImage]()
        images.append(image)
        for i in 1...3 {
            let radius: CGFloat = CGFloat(Double(i) * 8.0 / 3.0)
            if let blurredScreenshot = blurImageWithRadius(image, radius: radius) {
                images.append(blurredScreenshot)
            }
        }
        return images
    }
    
    func blurImageWithRadius(_ image: UIImage, radius: CGFloat) -> UIImage? {
        return image.applyBlur(withRadius: CGFloat(radius), tintColor: nil, saturationDeltaFactor: 1.0, maskImage: nil)
    }
    
    func moveView(by point: CGPoint) {
        peekPopView?.moveContainer(by: point)
    }
    
    func moveView(byY y: CGFloat) {
        peekPopView?.moveContainer(byX: 0, y: y)
    }
    
    func anchorToTop(withValue value: CGFloat) {
        peekPopView?.anchorToTop(withValue:  value)
    }
    
    func changeButton(availability isAvailable: Bool){
        if isAvailable {
            peekPopView?.showButton()
        } else {
            peekPopView?.hideButton()
        }
    }

    
    /// Add window to heirarchy when peek pop begins
    func peekPopBegan(_ context: PreviewingContext?) {
        peekPopWindow.alpha = 0.0
        peekPopWindow.isHidden = false
        peekPopWindow.makeKeyAndVisible()
        
        if let _context = context, let _vc = peekPopWindow.rootViewController as? PeekPopViewController {
            _context.delegate?.previewingContext?(_context, peekPopViewController: _vc)
        }
        
        if let peekPopView = peekPopView {
            peekPopWindow.addSubview(peekPopView)
        }
        
        peekPopView?.frame = UIScreen.main.bounds
        peekPopView?.didAppear()
        
        UIView.animate(withDuration: 0.15, animations: { () -> Void in
            self.peekPopWindow.alpha = 1.0
        })
    }
    
    /**
     Animated progress for context
     
     - parameter progress: A value between 0.0 and 1.0
     - parameter context:  PreviewingContext
     */
    func animateProgressForContext(_ progress: CGFloat, context: PreviewingContext?) {
        (progress < 0.99) ? peekPopView?.animateProgress(progress) : commitTarget(context)
    }
    
    /**
     Commit target.
     
     - parameter context: PreviewingContext
     */
    func commitTarget(_ context: PreviewingContext?){
        guard let targetViewController = targetViewController, let context = context else {
            return
        }
        context.delegate?.previewingContext(context, commitViewController: targetViewController)
        peekPopEnded()
    }
    
    /**
     Peek pop ended
     
     - parameter animated: whether or not window removal should be animated
     */
    func peekPopEnded() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.peekPopWindow.alpha = 0.0
            }, completion: { (finished) -> Void in
                self.peekPop.peekPopGestureRecognizer?.resetValues()
                self.peekPopWindow.isHidden = true
                self.peekPopView?.removeFromSuperview()
                self.peekPopView = nil
        }) 
    }
}

extension PeekPopManager: PeekPopViewDelegate {
    func peekPopView(actionTapped tapped: Bool) {

    }

    func peekPopView(initializeGestureRecognizerFor view: PeekPopView) -> Bool {
        let gestureRecognizer = PeekPopViewGestureRecognizer(peekPopView: view, peekPopManager: self)
        gestureRecognizer.sourceView = view
        gestureRecognizer.delegate = view
        view.addGestureRecognizer(gestureRecognizer)
        return false
    }
    
    func peekPopView(tapped button: UIButton) {
        peekPopEnded()
    }
}

protocol PeekPopManagerDelegate {
    func peekPopManager(changeProgress progress: CGFloat)
}
