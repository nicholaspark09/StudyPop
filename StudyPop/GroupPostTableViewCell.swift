//
//  GroupPostTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/19/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class GroupPostTableViewCell: UITableViewCell {

    var post:GroupPost?{
        didSet{
            nameLabel.text = post!.name!
            infoTextView.text = post!.pretty!
            print("The post date is \(post!.created)")
            if post!.created != nil{
                dateLabel.text = post!.created!.description
            }
        }
    }
    
    
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var memberImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var infoTextView: UITextView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
