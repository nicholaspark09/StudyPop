//
//  GroupTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/30/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class GroupTableViewCell: UITableViewCell {

    var group: Group?{
        didSet{
            groupNameLabel.text = group!.name!
        }
    }
    
    @IBOutlet var cityLabel: UILabel!
    
    @IBOutlet var groupNameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
