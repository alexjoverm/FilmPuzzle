//
//  RankingViewController.swift
//  Videopuzzle
//
//  Created by Alex Jover Moralez, Simon Hintersonnleitner, David Kranewitter, Fabian Hoffmann on 23/02/15.
//  Copyright (c) 2015 FH Salzburg. All rights reserved.
//

import UIKit

class RankingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    @IBOutlet weak var test: UILabel!
    @IBOutlet weak var tableRanking: UITableView!
    @IBOutlet weak var noResultsLabel: UILabel!
    
    var myScore:Int! = 0
    var myName = ""
    var myGame:Int!
    var myDifficulty:Int!
    
    var rankNames = [String]()
    var rankScores = [Int]()
    
    @IBOutlet weak var rankTitle: UILabel!
 
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "background_1.jpg")!)

        
        tableRanking.dataSource = self
        tableRanking.delegate = self
        
        
        
        var dbmanager = DBManager.instance
        current_user = myName
        
        
        switch myDifficulty {
        case 0:
            rankTitle.text =  dbmanager.getVideoName(myGame) + " - Easy"
        case 1:
            rankTitle.text =  dbmanager.getVideoName(myGame) + " - Medium"
        case 2:
            rankTitle.text =  dbmanager.getVideoName(myGame) + " - Hard"
        case 3:
            rankTitle.text =  dbmanager.getVideoName(myGame) + " - Extrem"
        default:
            break
        }
        
        if (myName == "Insert your name"){
            myName = "PuzzlePlayer"
        }
        
        if (myScore > 0) {
            dbmanager.addScore( Score(ID: -1, user: myName, score: myScore, video: myGame, difficulty: myDifficulty) )
        }
        
        var scores = dbmanager.getScores(myGame, difficulty: myDifficulty);
        
        for sc in scores{
            rankNames.append(String(sc.user))
            rankScores.append(sc.score)
            
            var str = "ID: " + String(sc.ID) + " - User: " + String(sc.user)
            str += " - Score: " + String(sc.score) + " - VideoID: " + String(sc.video) + " - Title: " + dbmanager.getVideoName(sc.video) + " - Difficulty: " + String(sc.difficulty)
            println(str)
        }
        
        if(scores.count == 0){
            noResultsLabel.hidden = false
        }
        
        var nib = UINib(nibName: "CustomCell", bundle: nil)
        tableRanking.registerNib(nib, forCellReuseIdentifier: "CustomCell")
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        return rankNames.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell:CustomCell = tableView.dequeueReusableCellWithIdentifier("CustomCell") as! CustomCell
        
        cell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        cell.labelPosition.text = String(indexPath.row + 1)
        cell.labelName.text = rankNames[indexPath.row]
        cell.labelScore.text = String(format: "%02d", rankScores[indexPath.row] / 60) + ":" + String(format: "%02d", rankScores[indexPath.row] % 60)
        
        cell.labelPosition.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        cell.labelName.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        cell.labelScore.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        
        
        if(indexPath.row == 0){
            cell.labelPosition.textColor = UIColor(red: 1, green: 0.84, blue: 0.0, alpha: 1.0)
            cell.labelName.textColor = UIColor(red: 1, green: 0.84, blue: 0.0, alpha: 1.0)
            cell.labelScore.textColor = UIColor(red: 1, green: 0.84, blue: 0.0, alpha: 1.0)
        }
        else if(indexPath.row == 1){
            cell.labelPosition.textColor = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1.0)
            cell.labelName.textColor = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1.0)
            cell.labelScore.textColor = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1.0)
        }
        else if(indexPath.row == 2){
            cell.labelPosition.textColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
            cell.labelName.textColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
            cell.labelScore.textColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
        }
        
        
        return cell
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}
