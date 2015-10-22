//
//  CreditViewController.swift
//  Videopuzzle
//
//  Created by Alex Jover Moralez, Simon Hintersonnleitner, David Kranewitter, Fabian Hoffmann.
//  Copyright (c) 2015 FH Salzburg. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CreditViewController : UIViewController {

    @IBOutlet weak var egg: UILabel!
    @IBAction func egg(sender: UILongPressGestureRecognizer) {
        egg.text = "The Answer is 42..."
    }
    
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "background_1.jpg")!)
        

    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}