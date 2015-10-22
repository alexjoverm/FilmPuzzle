//
//  MenueController.swift
//  Videopuzzle
//
//  Created by Alex Jover Moralez, Simon Hintersonnleitner, David Kranewitter, Fabian Hoffmann.
//  Copyright (c) 2015 FH Salzburg. All rights reserved.
//

import UIKit

var difficultLevel:Int! = 1;

class MenueViewController: UIViewController {
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
   
    @IBOutlet weak var label_one: UILabel!
    
    @IBOutlet weak var difficultyControl: UISegmentedControl!
    
    var imageView: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    @IBAction func buttonPressed(sender: UIButton) {
        videoId = sender.tag
        self.performSegueWithIdentifier("start", sender: sender)
    }
    
    @IBAction func rankButtonPressed(sender: UIButton) {
        println("RANKBUTTON")
        videoId = sender.tag
        self.performSegueWithIdentifier("goto_rank", sender: sender)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.difficultyControl.selectedSegmentIndex = difficultLevel
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "background_1.jpg")!)

    }

    override func viewDidAppear(animated: Bool) {
        self.scrollView.contentSize = CGSize(width: 300*8, height: self.scrollView.frame.size.height)
        for(var i=0;i<8;++i) {
            let f = CGRect(x: i*300,y: 0,width: 300,height: 275)
            let videoButton : UIButton = UIButton(frame: f)
            let name1 = "Video" + toString(i) + "_new.png"
            let name2 = "film_strip_medium.png"
           
            let image1 = UIImage(named: name1)
            let image2 = UIImage(named: name2)

            videoButton.setImage(image2, forState: UIControlState.Normal)
            videoButton.setBackgroundImage(image1, forState: UIControlState.Normal)
            
            videoButton.addTarget(self, action: "buttonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            videoButton.sizeToFit();
            videoButton.tag = i;
            self.scrollView.addSubview(videoButton)
            
            // RANKING
            
            let rect = CGRect(x: (i*300)+12,y: 154,width: 72,height: 72)
            let rankButton : UIButton = UIButton(frame: rect)
            
            let trophy_image = UIImage(named: "trophy.png")
            
            rankButton.setImage(trophy_image, forState: UIControlState.Normal)
            //rankButton.setBackgroundImage(image1, forState: UIControlState.Normal)
            
            rankButton.addTarget(self, action: "rankButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            //rankButton.sizeToFit();
            rankButton.tag = i;
            self.scrollView.addSubview(rankButton)
            
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func indexChanged(sender:UISegmentedControl)
    {
        difficultLevel = difficultyControl.selectedSegmentIndex;
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "start") {
            var svc = segue.destinationViewController as! ViewController;
            svc.difficulty = difficultLevel
        }
        
        if (segue.identifier == "goto_rank") {
            var svc = segue.destinationViewController as! RankingViewController;
            //svc.myScore = 0
            svc.myGame = videoId + 1
            svc.myDifficulty = difficultLevel
        }

    }

}
