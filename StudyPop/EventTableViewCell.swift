//
//  EventTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/9/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {

    var event: Event?{
        didSet{
            titleLabel.text = event!.name!
            print("The date is \(event!.start)")
            if event!.start != nil{
                dateLabel.text = "Date: \(event!.start!)"
            }else{
                dateLabel.text = ""
            }
        }
    }
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
