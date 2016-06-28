//
//  EventPostTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/28/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class EventPostTableViewCell: UITableViewCell {

    
    var post:EventPost?{
        didSet{
            nameLabel.text = post!.name!
            textView.text = post!.pretty!
            if post!.created != nil{
                dateLabel.text = post!.created!.description
            }
        }
    }
    
    
    
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
