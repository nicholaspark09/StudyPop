//
//  GroupRequestTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/22/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

protocol GroupRequestDelegate{
    func acceptIt(index:Int)
    func rejectIt(index:Int)
}

class GroupRequestTableViewCell: UITableViewCell {

    var request:GroupRequest?{
        didSet{
            nameLabel.text = request!.name!
            if request!.safekey == ""{
                acceptButton.hidden = true
                cancelButton.hidden = true
                memberImageView.hidden = true
            }
        }
    }
    var index = -1
    var delegate: GroupRequestDelegate?
    
    @IBOutlet var memberImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var acceptButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    @IBAction func acceptClicked(sender: UIButton) {
        
        if delegate != nil{
            delegate!.acceptIt(index)
        }
    }
    
    @IBAction func rejectClicked(sender: UIButton) {
        if delegate != nil{
            delegate!.rejectIt(index)
        }
    }
    

}
