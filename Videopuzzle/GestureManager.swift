//
//  GestureManager.swift
//  Videopuzzle
//
//  Created by Alex Jover Moralez, Simon Hintersonnleitner, David Kranewitter, Fabian Hoffmann.
//  Copyright (c) 2015 FH Salzburg. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension ViewController {
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touchCount = touches.count
        absFingerPos = touches.first as? UITouch
    }
    
//////////////////////ROW/COL DRAG//////////////////////
    func handleLongPress(recognizer:UILongPressGestureRecognizer) {
        var highlightColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        if recognizer.state == .Began {
            //first tile pressed
            if !dragging && pressedTile1 == nil && !locked {
                startSlot = -1
                for var i:Int = 0 ; i < slots.count ; i += 1{
                    if(slots[i].tile() == recognizer.view! || slots[i] == recognizer.view!)
                    {
                        startSlot = i
                    }
                } //tile in grid?
                if startSlot >= 0 {
                    origin = recognizer.view!.center
                    self.view.bringSubviewToFront(recognizer.view!)

                    pressedTile1 = recognizer.view as? TileView
                }
                
            } //second tile pressed
            else if pressedTile1 != nil {
                var startSlot2 = -1
                for var i:Int = 0 ; i < slots.count ; i += 1{
                    if(slots[i].tile() == recognizer.view! || slots[i] == recognizer.view!)
                    {
                        startSlot2 = i
                    }
                } //tile in grid?
                if startSlot2 >= 0 {
                    pressedTile2 = recognizer.view as? TileView
                    
                    var firstRow = startSlot / cols
                    var firstCol = startSlot % cols
                    var secondRow = startSlot2 / cols
                    var secondCol = startSlot2 % cols
                    
                    //same row
                    if ( firstRow == secondRow ){
                        for var i:Int = 0 ; i < cols ; i += 1{
                            var currentSlot = slots[firstRow * cols + i]
                            movedRowSlots.append(currentSlot)
                            currentSlot.backgroundColor = highlightColor
                            movedRowSlots[i].tile()?.alpha = 0.5
                            if currentSlot.tile() != nil {
                                view.bringSubviewToFront(currentSlot.tile()!)
                            }
                        }
                        startRow = firstRow
                        dragSoundPlayer.prepareToPlay()
                        dragSoundPlayer.play()
                    }
                    //same col
                    else if ( firstCol == secondCol ) {
                        for var i:Int = 0 ; i < rows ; i += 1{
                            var currentSlot = slots[firstCol + i * cols]
                            movedColSlots.append(currentSlot)
                            currentSlot.backgroundColor = highlightColor
                            movedColSlots[i].tile()?.alpha = 0.5
                            if currentSlot.tile() != nil {
                                view.bringSubviewToFront(currentSlot.tile()!)
                            }
                        }
                        startCol = firstCol
                        dragSoundPlayer.prepareToPlay()
                        dragSoundPlayer.play()
                    }
                    else {

                    }

                }
            }
        }
        if recognizer.state == .Changed {
            clearHighlights()
            var x = absFingerPos?.locationInView(self.view).x
            var y = absFingerPos?.locationInView(self.view).y

            //Row
            if movedRowSlots.count > 0 {
                for var i:Int = 0 ; i < movedRowSlots.count ; i += 1{
                    //move row
                    movedRowSlots[i].tile()?.center.y = y!
                    if y <= slots[0].center.y {
                        movedRowSlots[i].tile()?.center.y = slots.first!.center.y
                    }
                    if y >= slots.last?.center.y {
                        movedRowSlots[i].tile()?.center.y = slots.last!.center.y
                    }
                }
                
                //detect snapping target
                targetRow = -1
                for var row:Int = 0 ; row < rows ; row += 1 {
                    for var col:Int = 0 ; col < cols ; col += 1 {
                        if movedRowSlots[col].tile() != nil &&
                            movedRowSlots[col].tile()?.center.y >= slots[row * cols].center.y - tileHeight / 2 &&
                            movedRowSlots[col].tile()?.center.y <= slots[row * cols].center.y + tileHeight / 2 {
                            
                                targetRow = row
                                break
                        }
                    }
                }
                
                
                if targetRow >= 0 {
                    for var i:Int = 0 ; i < cols ; i += 1 {
                        var slot = targetRow! * cols + i
                        slots[slot].backgroundColor = highlightColor
                        if (targetRow != startRow) {
                            slots[slot].alpha = 1
                        }
                        slots[slot].tile()?.alpha = 0.5
                    }
                }
                
            }
            //Col
            if movedColSlots.count > 0 {
                for var i:Int = 0 ; i < movedColSlots.count ; i += 1{
                    movedColSlots[i].tile()?.center.x = x!
                    if x <= slots[0].center.x {
                        movedColSlots[i].tile()?.center.x = slots.first!.center.x
                    }
                    if x >= slots.last?.center.x {
                        movedColSlots[i].tile()?.center.x = slots.last!.center.x
                    }
                }
                
                //detect snapping target
                targetCol = -1
                for var col:Int = 0 ; col < cols ; col += 1 {
                    for var row:Int = 0 ; row < rows ; row += 1 {
                        if movedColSlots[row].tile() != nil &&
                            movedColSlots[row].tile()?.center.x >= slots[col].center.x - tileWidth / 2 &&
                            movedColSlots[row].tile()?.center.x <= slots[col].center.x + tileWidth / 2 {
                            
                                targetCol = col
                                break
                        }
                    }
                }
                
                if targetCol >= 0 {
                    for var i:Int = 0 ; i < rows ; i += 1 {
                        var slot = targetCol! + cols * i
                        slots[slot].backgroundColor = highlightColor
                        if (targetCol != startCol) {
                            slots[slot].alpha = 1
                        }
                        slots[slot].tile()?.alpha = 0.5
                    }
                }
            }
        }
        
        if recognizer.state == .Ended {
            //target row?
            if targetRow >= 0 {
                //buffer moved tiles
                var movedTiles:[TileView?] = []
                for var i:Int = 0 ; i < movedRowSlots.count ; i += 1 {
                    if movedRowSlots[i].tile() == nil {
                        movedTiles.append(nil)
                    }
                    else {
                        movedTiles.append(movedRowSlots[i].tile()!)
                    }
                }
                //downwards or same row?
                if targetRow >= startRow {
                    for var row:Int = startRow! ; row <= targetRow ; row += 1 {
                        var counter = 0
                        for var slot:Int = row * cols ; slot < row * cols + cols ; slot += 1 {
                            if row == targetRow {
                                slots[slot].tile(movedTiles[counter])
                                animate(slots[slot].tile(), coordinates:slots[slot].center)
                                counter++
                            }
                            else {
                                slots[slot].tile(slots[slot + cols].tile())
                                animate(slots[slot].tile(), coordinates:slots[slot].center)
                            }
                        }
                    }
                }

                //upwards?
                if targetRow < startRow {
                    for var row:Int = startRow! ; row >= targetRow ; row -= 1 {
                        var counter = 0
                        for var slot:Int = row * cols ; slot < row * cols + cols ; slot += 1 {
                            if row == targetRow {
                                slots[slot].tile(movedTiles[counter])
                                animate(slots[slot].tile(), coordinates:slots[slot].center)
                                counter++
                            }
                            else {
                                slots[slot].tile(slots[slot - cols].tile())
                                animate(slots[slot].tile(), coordinates:slots[slot].center)
                            }
                        }
                    }
                }
                dropSoundPlayer.prepareToPlay()
                dropSoundPlayer.play()
            }
            //target col?
            if targetCol >= 0 {
                //buffer moved tiles
                var movedTiles:[TileView?] = []
                for var i:Int = 0 ; i < movedColSlots.count ; i += 1 {
                    if movedColSlots[i].tile() == nil {
                        movedTiles.append(nil)
                    }
                    else {
                        movedTiles.append(movedColSlots[i].tile()!)
                    }
                    
                }
                //rightwards or same column?
                if targetCol >= startCol {
                    for var col:Int = startCol! ; col <= targetCol ; col += 1 {
                        for var row:Int = 0 ; row < rows ; row += 1 {
                            var slot = col + row * cols
                            if col == targetCol {
                                    slots[slot].tile(movedTiles[row])
                                    animate(slots[slot].tile(), coordinates:slots[slot].center)
                            }
                            else {
                                    slots[slot].tile(slots[slot + 1].tile())
                                    animate(slots[slot].tile(), coordinates:slots[slot].center)
                            }
                        }
                    }
                }
                //leftwards?
                if targetCol < startCol {
                    for var col:Int = startCol! ; col >= targetCol ; col -= 1 {
                        for var row:Int = 0 ; row < rows ; row += 1 {
                            var slot = col + row * cols
                            if col == targetCol {
                                    slots[slot].tile(movedTiles[row])
                                    animate(slots[slot].tile(), coordinates:slots[slot].center)
                            }
                            else {
                                    slots[slot].tile(slots[slot - 1].tile())
                                    animate(slots[slot].tile(), coordinates:slots[slot].center)
                            }
                        }
                    }
                }
                dropSoundPlayer.prepareToPlay()
                dropSoundPlayer.play()
            }
            
            pressedTile1 = nil
            pressedTile2 = nil
            startRow = nil
            startCol = nil
            targetRow = nil
            targetCol = nil
            movedRowSlots = []
            movedColSlots = []
            clearHighlights()
            checkWin()
        }
    }
    
//////////////////////SINGLE TILE DRAG//////////////////////
    func handlePan(recognizer:UIPanGestureRecognizer) {
        
        if pressedTile1 == nil && !locked {
            var highlightColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
            switch recognizer.state{
                
            case UIGestureRecognizerState.Began :
                if ( movedTile == nil ) {
                    startSlot = -1
                    for var i:Int = 0 ; i < slots.count ; i += 1{
                        if(slots[i].center == recognizer.view!.center)
                        {
                            startSlot = i
                            slots[i].backgroundColor = highlightColor
                        }
                    }
                    
                    movedTile = recognizer.view as? TileView
                    origin = recognizer.view!.center
                    self.view.bringSubviewToFront(recognizer.view!)
                    
                    dragSoundPlayer.prepareToPlay()
                    dragSoundPlayer.play()
                    
                }

            case UIGestureRecognizerState.Changed :
                    if ( recognizer.view as? TileView == movedTile ) {
                        clearHighlights()
                        dragging = true
                        var fingerPosition = recognizer.locationInView(self.view)
                        
                        // Change translation
                        let translation = recognizer.translationInView(self.view)
                        
                        recognizer.view!.center = CGPoint(x:recognizer.view!.center.x + translation.x,
                            y:recognizer.view!.center.y + translation.y)
                        
                        recognizer.setTranslation(CGPointZero, inView: self.view)
                        
                        targetSlot = -1
                        for var i:Int = 0 ; i < slots.count ; i += 1{
                            var diffHor = abs( slots[i].center.x - fingerPosition.x)
                            var diffVer = abs( slots[i].center.y - fingerPosition.y)
                            slots[i].alpha = 0
                            
                            // is this tile underneath my finger?
                            if( diffHor <= getTileWidth() / 2 && diffVer  <= getTileHeight() / 2 )
                            {
                                if (slots[i].tile() != nil && slots[i].tile() != recognizer.view) {
                                    slots[i].alpha = 1
                                }
                                else {
                                    slots[i].alpha = 0.35
                                }
                                
                                
                                targetSlot = i
                                slots[i].tile()?.alpha = 0.6
                                //slots[i].tile()?.backgroundColor = UIColor.whiteColor();
                                slots[i].backgroundColor = highlightColor
                            }
                        }
                        
                    }
                
            case UIGestureRecognizerState.Ended :
                    dragging = false
                    if ( recognizer.view as? TileView == movedTile ) {
                        var tileInStartSlot : TileView?
                        
                        
                        if(targetSlot >= 0 )
                        {
                            slots[targetSlot].alpha = 0

                            if(startSlot >= 0)
                            {
                                //moving inside of puzzle
                                tileInStartSlot = slots[startSlot].tile()
                                var targetCenter = slots[targetSlot].center
                                if( slots[targetSlot].tile() != nil){
                                    slots[startSlot].tile(slots[targetSlot].tile()!)
                                    animate(slots[startSlot].tile()!, coordinates:origin!)
                                }
                                else {
                                    slots[startSlot].setTileNil()
                                }

                                slots[targetSlot].tile(tileInStartSlot!)
                                if slots[startSlot].tile() != nil {
                                    self.view.bringSubviewToFront(slots[startSlot].tile()!)
                                }
                                animate(slots[targetSlot].tile()!, coordinates:targetCenter)
                                slots[startSlot].tile()?.alpha = 1
                            }
                            else
                            {
                                //moving from outside in
                                var targetCenter = slots[targetSlot].center
                                if( slots[targetSlot].tile() != nil){
                                    self.view.bringSubviewToFront(slots[targetSlot].tile()!)
                                    animate(slots[targetSlot].tile()!, coordinates:origin!)
                                }
                                
                                slots[targetSlot].tile()?.alpha = 1
                                slots[targetSlot].tile(movedTile!)
                                animate(slots[targetSlot].tile()!, coordinates:targetCenter)
                            }
                        }
                        else
                        {
                            if(startSlot >= 0)
                            {
                                //moving from inside out
                                if slots[startSlot].tile() != nil {
                                    var newCenter = recognizer.view!.center
                                    if recognizer.view?.center.x >= slots[0].center.x - tileWidth
                                        && recognizer.view?.center.x <= slots[0].center.x {
                                            
                                            newCenter.x = CGFloat(slots[0].center.x - tileWidth - 5)
                                            
                                    }
                                    if recognizer.view?.center.x <= slots[slots.count - 1].center.x + tileWidth
                                        && recognizer.view?.center.x >= slots[slots.count - 1].center.x {
                                            
                                            newCenter.x = CGFloat(slots[slots.count - 1].center.x + tileWidth + 5)
                                            
                                    }
                                    if recognizer.view?.center.y <= slots[slots.count - 1].center.y + tileHeight
                                        && recognizer.view?.center.y >= slots[slots.count - 1].center.y {
                                            
                                            newCenter.y = CGFloat(slots[slots.count - 1].center.y + tileHeight + 5)
                                    }
                                    if recognizer.view?.center.y >= slots[0].center.y - tileHeight
                                        && recognizer.view?.center.y <= slots[0].center.y {
                                            
                                            newCenter.y = CGFloat(slots[0].center.y - tileHeight - 5)
                                    }
                                    animate(slots[startSlot].tile(), coordinates: newCenter)
                                }

                                slots[startSlot].setTileNil()
                                slots[startSlot].tile()?.alpha = 1
                                
                            }
                            else
                            {
                                //moving outside
                                
                                    var newCenter = recognizer.view!.center
                                    if recognizer.view?.center.x >= slots[0].center.x - tileWidth
                                        && recognizer.view?.center.x <= slots[0].center.x {
                                            
                                            newCenter.x = CGFloat(slots[0].center.x - tileWidth - 5)
                                            
                                    }
                                    if recognizer.view?.center.x <= slots[slots.count - 1].center.x + tileWidth
                                        && recognizer.view?.center.x >= slots[slots.count - 1].center.x {
                                            
                                            newCenter.x = CGFloat(slots[slots.count - 1].center.x + tileWidth + 5)
                                            
                                    }
                                    if recognizer.view?.center.y <= slots[slots.count - 1].center.y + tileHeight
                                        && recognizer.view?.center.y >= slots[slots.count - 1].center.y {
                                            
                                            newCenter.y = CGFloat(slots[slots.count - 1].center.y + tileHeight + 5)
                                    }
                                    if recognizer.view?.center.y >= slots[0].center.y - tileHeight
                                        && recognizer.view?.center.y <= slots[0].center.y {
                                            
                                            newCenter.y = CGFloat(slots[0].center.y - tileHeight - 5)
                                    }
                                    animate(movedTile, coordinates: newCenter)
                                }

                            
                        }
                        dropSoundPlayer.prepareToPlay()
                        dropSoundPlayer.play()
                        movedTile?.alpha = 1
                        movedTile = nil
                        center_old = CGPointMake(0, 0)
                        checkWin()
                    }

            default:
                break
            }
        }
    }
    
    func clearHighlights () {
        for var i = 0; i < tiles.count; i++ {
            slots[i].backgroundColor = UIColor(white: 1, alpha: 1.0)
            tiles[i].alpha = 1
            slots[i].alpha = 0
        }
    }
    
    func checkWin() {
        
        had_won = true
        
        for(var i = 0; i < tiles.count; i++)
        {
            if (tiles[i] != slots[i].tile())
            {
                had_won = false
            }
        }
        
        if (had_won)
        {
            timer.invalidate()
            var dbmanager = DBManager.instance
            
            your_score.text = String(format: "%02d", minutes) + " : " + String(format: "%02d", score % 60)
            timer_label.hidden = true
            
            if (dbmanager.gotInHighscore(videoId, score: score, difficulty: difficulty)) {
                name_field.hidden = false
                did_highscore.hidden = false
                to_rank.setTitle("Insert", forState: UIControlState.Normal)
            }
            
            score_header.hidden = false
            your_score.hidden = false
            to_rank.hidden = false
        }
    }
}