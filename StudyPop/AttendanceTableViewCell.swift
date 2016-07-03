//
//  AttendanceTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/3/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class AttendanceTableViewCell: UITableViewCell {

    var attendance:Attendance?{
        didSet{
            nameLabel.text = attendance!.fromEventMember!.name!
        }
    }
    
    
    @IBOutlet var memberImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
