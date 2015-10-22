//
//  ViewController.swift
//  Videopuzzle
//
//  Created by Alex Jover Moralez, Simon Hintersonnleitner, David Kranewitter, Fabian Hoffmann.
//  Copyright (c) 2015 FH Salzburg. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftSpinner

// Public variables
var videoId = 0;
var current_user = "Insert your name"

let loadingMessages = ["Creating awesomeness...", "Blaming the director...", "Taming the diva...", "Mining for diamonds...", "Climbing data trees...", "Feeding the kittens...", "Cutting out the pieces...", "Such performance...", "Warp speed...", "Breaking sound barrier...", "♫ Elevator music ♫ ...", "I don't hate you...", "Shovelling coal...", "The floor is lava...", "Testing your patience...", "Don't think of purple hippos...", "Damn I've lost the game...", "Where's the ANY key?...", "So, how are you?...", "Calling Lenhart's mother...", "Don't panic...", "Entering maze...", "Entering the Matrix...", "May the force be with you...", "Look, a penny...", "Penny, Penny, Penny...", "Creating Universe (may take a while)", "While(true)...", "Loading message...", "Being humorous...", "Consulting the oracle...", "♫ This was a triumph...", "One Mississippi, two Missis...", "Loading stuff...", "There is no spoon...", "Rethinking...", "On the other hand...", "Taking the red pill...", "I know what I'm doing..", "π = 3...", "Are you waiting for me?...", "Dividing by 0...", "Ain't nobody got time for that...", "You should see what I see...", "Your mother called...", "Inventing the wheel...", "The cake is a lie..."]

    var remainingMessages = loadingMessages

class TileView : UIView {}

class SlotView : UIView {
    func exchangeTile(var tileInTargetSlot : TileView?, var old_center:CGPoint) -> TileView? {
        let movedTile = self.tile_
        self.tile_?.center = old_center
        self.tile_ = tileInTargetSlot
        return movedTile
    }

    func tile(newTile:TileView?) {
        self.tile_ = newTile
    }
    
    func tile() -> TileView? {
        return tile_
    }
    
    func setTileNil () {
        self.tile_ = nil
    }

    private
    var tile_:TileView?
}

class ViewController: UIViewController, UITextFieldDelegate {
    // Flags
    var locked = false
    var had_won = false
    var dragging:Bool = false
    
    //Declarations/initializations
    var puzzleSize:CGFloat = 0.75
    var rows:Int!
    var cols:Int!
    var difficulty:Int!
    var tileAmounts: [[Int]] = [[3,4],[4,5],[5,6],[6,7]] // [Rows,Cols]
    var score = 0
    var minutes = 0
    var tiles = [TileView]()
    var slots = [SlotView]()
    var tileWidth = CGFloat(0.0)
    var tileHeight = CGFloat(0.0)
    var boundsView : UIView?
    var player : AVQueuePlayer?
    var timer = NSTimer()
    var videoURL : NSURL!
    
    // For tile movements
    var targetSlot = -1
    var startSlot = -1
    var pressedTile1:TileView?
    var pressedTile2:TileView?
    var movedTile:TileView?
    var movedTile2:TileView?
    var absFingerPos:UITouch? = nil
    var origin:CGPoint?
    var center_old:CGPoint =  CGPointMake(0, 0);
    
    // Row/Col movement
    var startRow:Int?
    var startCol:Int?
    var targetRow:Int?
    var targetCol:Int?
    var movedRowSlots = [SlotView]()
    var movedColSlots = [SlotView]()

    // SoundPlayer settings
    var dragSoundPlayer = AVAudioPlayer()
    var dropSoundPlayer = AVAudioPlayer()
    var dragSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("drag", ofType: "mp3")!)
    var dropSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("drop", ofType: "mp3")!)
    
    //Outlets
    @IBOutlet weak var score_header: UILabel!
    @IBOutlet weak var your_score: UILabel!
    @IBOutlet weak var timer_label: UILabel!
    @IBOutlet weak var did_highscore: UILabel!
    @IBOutlet weak var to_rank: UIButton!
    @IBOutlet weak var name_field: UITextField!

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getTileWidth() -> CGFloat {
        return tileWidth
    }
    
    func getTileHeight() -> CGFloat {
        return tileHeight
    }

    override func observeValueForKeyPath(keyPath: String,
        ofObject object: AnyObject,
        change: [NSObject : AnyObject],
        context: UnsafeMutablePointer<Void>) {
            if(keyPath=="currentItem") {
                // Take the item which just finished playing and re-add it at the end of the queue
                let d = change as NSDictionary
                let oldItem = d.objectForKey(NSKeyValueChangeOldKey) as! AVPlayerItem
                player?.insertItem(oldItem, afterItem: nil)
            }
            else {
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            }
        }
    
    override func viewDidAppear(animated: Bool) {
        // Lock game before shuffeling
        locked = true
        
        // Set Video
        videoURL = NSBundle.mainBundle().URLForResource("Video\(videoId)",withExtension:"mp4")!
        
        // Creating a video-only composition - this seems to be the only way
        // to get a smoothly looping video with the AVPlayer
        let tAsset : AVURLAsset = AVURLAsset.assetWithURL(videoURL) as! AVURLAsset
        let tAssetVideoTrack : AVAssetTrack = tAsset.tracksWithMediaType(AVMediaTypeVideo)[0] as! AVAssetTrack
        let tEditRange : CMTimeRange = tAssetVideoTrack.timeRange
        let tComposition : AVMutableComposition = AVMutableComposition()
        let tTrack : AVMutableCompositionTrack = tComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        
        // Insert some copies (as many as possible without causing a long delay at the start)
        for (var i = 0; i < 100; i++) {
            tTrack.insertTimeRange(tEditRange, ofTrack:tAssetVideoTrack, atTime:tComposition.duration, error:nil)
        }
        
        // Using a queued player to make it easy to keep it running forever. Note that the queue
        // will still have noticable delays between videos. Odd. But given that we have 100 of them
        // running in a row in the composition, that rarely happens.
        player = AVQueuePlayer(items: [AVPlayerItem(asset: tComposition), AVPlayerItem(asset: tComposition)])
        player!.muted = true
        
        // Register an observer which keeps the queue running if we run out of the 2*100 videos
        player!.addObserver(self, forKeyPath: "currentItem", options: NSKeyValueObservingOptions.New|NSKeyValueObservingOptions.Old,context: nil)
        
        // **** Set dimensions ****
        //    - 1 : Calculate the size we want to give the video (73% of the screen size)
        
        var originalVideoSize = (player!.currentItem.asset.tracksWithMediaType(AVMediaTypeVideo)[0] as! AVAssetTrack).naturalSize
        var videoFactor = originalVideoSize.height / originalVideoSize.width
        var screenSize = self.view.frame.size;
        
        var videoSize = CGSizeMake(screenSize.width * puzzleSize, 0.0)
        videoSize.height = videoSize.width * videoFactor
        
        name_field.delegate = self
//        CACurrentMediaTime()
        //    - 2 : Amount of tile according to difficulty
        
        rows = tileAmounts[difficulty][0]
        cols = tileAmounts[difficulty][1]
        
        // Set the tiles sizes according to the video size
        tileWidth = videoSize.width / CGFloat(cols)
        tileHeight = videoSize.height / CGFloat(rows)
        
        // Position Puzzle
        var offsetX = (self.view.frame.width - videoSize.width) / 2.0
        var offsetY = (self.view.frame.height - videoSize.height) / 4.0
        
        // Create Slots/Tiles
        for(var y=0;y<rows;y++) {
            for(var x=0;x<cols;x++) {
                // Calculate size of tiles
                var tile_x = tileWidth * CGFloat(x)
                var tile_y = tileHeight * CGFloat(y)
                
                // TileView has Layer that houses the player
                var layer = AVPlayerLayer(player: player!)
                layer.frame = CGRect(x: -tile_x, y: -tile_y, width: videoSize.width, height: videoSize.height)
                layer.videoGravity = kCAGravityTopLeft;
                layer.contentsGravity = kCAGravityTopLeft;
                layer.masksToBounds = true
                
                // Add offsets
                tile_x += offsetX
                tile_y += offsetY
                
                // Tile
                var tileView = TileView(frame: CGRect(x: tile_x, y: tile_y, width:tileWidth, height:tileHeight))
                // Slot
                var slotView = SlotView(frame: CGRect(x:tile_x,y:tile_y,width:tileWidth,height:tileHeight))
                //slotView.backgroundColor = UIColor(white: 1, alpha: 0)
                slotView.alpha = 0
                slots.append(slotView)
                
                //Gesture recognizers
                let lpr = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
                lpr.minimumPressDuration = 0.4
                slotView.addGestureRecognizer(lpr)
                view.addSubview(slotView)
                
                
                tileView.clipsToBounds = true
                tileView.layer.masksToBounds = true;
                tileView.layer.addSublayer(layer)
                view.clipsToBounds = true
                view.layer.masksToBounds = true
                layer.opaque = true
                
                
                let pr = UIPanGestureRecognizer(target: self, action:"handlePan:")
                tileView.addGestureRecognizer(lpr)
                tileView.addGestureRecognizer(pr)
                tiles.append(tileView)
                
            }
        }
        
        boundsView = UIView(frame: CGRect(x: offsetX, y: offsetY, width:videoSize.width, height:videoSize.height))
        boundsView!.layer.borderColor = UIColor.whiteColor().CGColor
        boundsView!.layer.borderWidth = 1
        boundsView!.hidden = true
        view.addSubview(boundsView!)
        
        // Preshuffle tiles / Visual shuffel in AnimatedShuffleSlots()
        var shuffleSlots = shuffle(slots)
        for(var i = 0; i < tiles.count; i++) {
            shuffleSlots[i].exchangeTile(tiles[i], old_center: shuffleSlots[i].center)
            view.addSubview(tiles[i])
        }
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        // Start video
        player!.play()
        
        // Preload video
        player?.prerollAtRate(0.1, completionHandler: { (value: Bool) in self.playerDidLoad() })
    }
    
    func playerDidLoad() {
        boundsView!.hidden = false
        SwiftSpinner.hide()
        animatedShuffleSlots(slots)
    }
    
    override func viewDidLoad() {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // do some task
            dispatch_async(dispatch_get_main_queue()) {
                var id = Int(arc4random_uniform(UInt32(remainingMessages.count)))
                SwiftSpinner.show(remainingMessages[id], animated: true)
                remainingMessages.removeAtIndex(id)
                if remainingMessages.count == 0 {
                    remainingMessages = loadingMessages
                }
            }
        }
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "background_1.jpg")!)

        var error:NSError?
        dragSoundPlayer = AVAudioPlayer(contentsOfURL: dragSound, error: &error)
        dropSoundPlayer = AVAudioPlayer(contentsOfURL: dropSound, error: &error)
        dragSoundPlayer.volume = 0.10
        dropSoundPlayer.volume = 0.30
        score = 0
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "background_1.jpg")!)
        
        score_header.hidden = true
        your_score.hidden = true
        did_highscore.hidden = true
        to_rank.hidden = true
        name_field.hidden = true
        name_field.placeholder = current_user
    }

    override func viewDidDisappear(animated: Bool) {
        // Thoroughly clean up our stuff to avoid memory leaks / players that keep on playing
        // and eat up CPU time
        for tv in tiles {
            tv.removeFromSuperview()
        }
        tiles.removeAll(keepCapacity: true)
        for sv in slots {
            sv.removeFromSuperview()
        }
        slots.removeAll(keepCapacity: true)
        boundsView!.removeFromSuperview()
        player!.removeObserver(self, forKeyPath: "currentItem")
        player!.pause()
        player!.cancelPendingPrerolls()
        player = nil
    }
    
    func updateCounter() {
        minutes = score / 60
        self.timer_label.text = "Time " + String(format: "%02d", minutes) + ":" + String(format: "%02d", score % 60)
        score++
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "show_rank") {
            var svc = segue.destinationViewController as! RankingViewController;
            svc.myScore = score
            if (name_field.text == ""){
                svc.myName = current_user
            }
            else {
                svc.myName = name_field.text
            }
            svc.myGame = videoId + 1
            svc.myDifficulty = difficulty
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.performSegueWithIdentifier("show_rank", sender: self)
        return true
    }
    
    func keyboardWillShow(sender: NSNotification) {
        self.view.frame.origin.y -= 370
    }
    func keyboardWillHide(sender: NSNotification) {
        self.view.frame.origin.y += 370
    }
  }
