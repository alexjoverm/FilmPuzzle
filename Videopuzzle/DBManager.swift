//
//  DBManager.swift
//  Videopuzzle
//
//  Created by Alex Jover Moralez, Simon Hintersonnleitner, David Kranewitter, Fabian Hoffmann.
//  Copyright (c) 2015 FH Salzburg. All rights reserved.
//

import Foundation


struct Score {
    var ID: Int = -1
    var user: String
    var score: Int
    var video: Int
    var difficulty:Int
}

struct Video{
    var ID: Int = -1
    var filename: String
    var difficulty: Int  //0: easy, 1: medium, 2: hard
}





class DBManager  {
    static let instance = DBManager()
    
    let database: FMDatabase!
    let maxScores:Int = 15;
    
    var currentDifficulty:Int = 2;
    
    
    // ***** Init the required vars to work with the DB
    
    init(){
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = dirPaths[0] as! String
        var databasePath = docsDir.stringByAppendingPathComponent("videopuzzle.sqlite")
        
        var fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(databasePath) {
            var fromPath: NSString = NSBundle.mainBundle().resourcePath!.stringByAppendingPathComponent("videopuzzle.sqlite")
            fileManager.copyItemAtPath(fromPath as String, toPath: databasePath, error: nil)
        }
        
        database = FMDatabase(path: databasePath)
    }
    
    
    
    //***** VIDEOS functions *****
    
    func getVideos() -> [Video]{
        
        database.open()
        var resultSet: FMResultSet! = database.executeQuery("SELECT * FROM video", withArgumentsInArray: nil)
        
        var rollNoColumn: String = "student_rollno"
        var nameColumn: String = "student_name"
        
        var result = [Video]()
        
        if (resultSet != nil) {
            while resultSet.next() {
                result.append(
                  Video(ID: Int(resultSet.intForColumn("ID")),
                    filename: String(resultSet.stringForColumn("filename")),
                    difficulty: Int(resultSet.intForColumn("difficulty")))
                )
            }
        }
        database.close()
        
        return result
    }
    
    func addVideo(video: Video){
        
        database.open();
        database.executeUpdate("INSERT INTO video (filename, difficulty, colcount) VALUES (?, ?)",
                withArgumentsInArray: [video.filename, video.difficulty])
        database.close();
    }
    
    func cleanVideos(){
        database.open()
        database.executeUpdate("DELETE FROM video", withArgumentsInArray: nil)
        database.executeUpdate("DELETE FROM sqlite_sequence WHERE name='video'", withArgumentsInArray: nil)
        database.close()
    }
    
    
    
    func getVideoName(ID: Int) -> String{
        var title = "Empty Gametitle"
        
        database.open()
        var resultSet: FMResultSet! = database.executeQuery("SELECT title as title FROM video WHERE ID=?",
            withArgumentsInArray: [ID])
        
        if (resultSet != nil) {
            resultSet.next()
            title = String(resultSet.stringForColumn("title"))
        }
        
        database.close()
        
        return title;
    }

    
    
    
    
    
    //***** SCORES functions *****
    
    
    
    
    
    func addScore(score: Score){
        
        var count:Int = 0
        
        database.open();
        
        
        var aux: FMResultSet! = database.executeQuery("select count(*) as cnt from score WHERE videoID = ? AND difficulty = ?", withArgumentsInArray: [score.video, score.difficulty])
        
        if (aux != nil) {
            aux.next();
            count = Int(aux.intForColumn("cnt"))
        }
        
        // if more than 15, just update the minimum
        if(count == maxScores){
            var idSet = database.executeQuery("SELECT ID, MAX(score) as score FROM score", withArgumentsInArray: nil)
            idSet.next();
            database.executeUpdate("UPDATE score SET user=?, score=?, videoID=?, difficulty=? WHERE ID=?",
                withArgumentsInArray: [score.user, score.score, score.video, score.difficulty, Int(idSet.intForColumn("ID"))])
        }
        else{ // otherwise, insert it
            database.executeUpdate("INSERT INTO score (user, score, videoID, difficulty) VALUES (?, ?, ?, ?)",
                withArgumentsInArray: [score.user, score.score, score.video, score.difficulty])
        }
        
        database.close();
    }
    
    
    
    func gotInHighscore(idVideo: Int, score: Int, difficulty: Int) -> Bool{

        var leastScore = 1000000
        var count = 0
        
        database.open()
        var resultSet: FMResultSet! = database.executeQuery("SELECT MAX(SCORE) as score FROM score WHERE videoID=? AND difficulty=?",
            withArgumentsInArray: [idVideo, difficulty])
        if (resultSet != nil) {
            resultSet.next()
            var leastScore = Int(resultSet.intForColumn("score"))
        }
            
        var resultSet2: FMResultSet! = database.executeQuery("SELECT COUNT(*) as count FROM score WHERE videoID=? AND difficulty=?",
            withArgumentsInArray: [idVideo, difficulty])
        if (resultSet != nil) {
            resultSet.next()
            count = Int(resultSet2.intForColumn("count"))
        }
        
        
        database.close()
        
        if (count <= 15 || score < leastScore) {
            return true
        }
        else {
            return false
        }
    }

    
    
    // Returns array of Scores
    
    func getScores(idVideo: Int, difficulty: Int) -> [Score]{
        
        database.open()
        var resultSet: FMResultSet! = database.executeQuery("SELECT * FROM score WHERE videoID=? AND difficulty=? ORDER BY score ASC",
            withArgumentsInArray: [idVideo, difficulty])
        
        var result = [Score]()
        
        if (resultSet != nil) {
            while resultSet.next() {
                result.append(
                    Score(
                        ID: Int(resultSet.intForColumn("ID")),
                        user: String(resultSet.stringForColumn("user")),
                        score: Int(resultSet.intForColumn("score")),
                        video: Int(resultSet.intForColumn("videoID")),
                        difficulty: Int(resultSet.intForColumn("difficulty"))
                    )
                )
                
            }
        }
        database.close()
        
        return result
    }
    
    func cleanScores(){
        database.open()
        database.executeUpdate("DELETE FROM score", withArgumentsInArray: nil)
        
        // also clean autoincrement indexes
        database.executeUpdate("DELETE FROM sqlite_sequence WHERE name='score'", withArgumentsInArray: nil)
        database.close()
    }
    
    
}

