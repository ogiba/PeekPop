//
//  PeekPopViewController.swift
//  PeekPop
//
//  Created by Robert Ogiba on 08.06.2017.
//  Copyright © 2017 Roy Marmelstein. All rights reserved.
//

import UIKit

public class PeekPopViewController: UIViewController {
    open var delegate: PeekPopViewControllerDelegate?

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            if let _orientation = delegate?.peekPop(viewController: self) {
                return _orientation
            }
            return .allButUpsideDown
        }
    }

}

public protocol PeekPopViewControllerDelegate {
    func peekPop(viewController: PeekPopViewController) -> UIInterfaceOrientationMask
}
