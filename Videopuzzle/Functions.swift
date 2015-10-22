//
//  Functions.swift
//  Videopuzzle
//
//  Created by Alex Jover Moralez, Simon Hintersonnleitner, David Kranewitter, Fabian Hoffmann.
//  Copyright (c) 2015 FH Salzburg. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension ViewController{
    
    func animate (var tile:TileView?, var coordinates:CGPoint, var duration:NSTimeInterval = 0.4) {
        if tile != nil {
        UIView.animateWithDuration(duration ,
            delay: 0,
            options: UIViewAnimationOptions.CurveEaseOut,
            animations: {tile?.center = coordinates },
            completion: nil)
        }
    }
    
    func animatedShuffleSlots(var slots:[(SlotView)]) {
        delay(2.5) {
            for(var i = 0; i < self.tiles.count; i++) {
                self.animate(self.slots[i].tile(), coordinates: self.slots[i].center, duration: 0.8)
            }
            
            self.locked = false
            
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("updateCounter"), userInfo: nil, repeats: true)
        }
    }
    
    //code by Nate Cook, http://stackoverflow.com/a/24029847
    func shuffle<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
        let counter = count(list)
        for i in 0..<(counter - 1) {
            let j = Int(arc4random_uniform(UInt32(counter - i))) + i
            swap(&list[i], &list[j])
        }
        return list
    }
    
    //code by matt, http://stackoverflow.com/a/24318861
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}