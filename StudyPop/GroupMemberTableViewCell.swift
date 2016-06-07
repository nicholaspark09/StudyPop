//
//  GroupMemberTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/7/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class GroupMemberTableViewCell: UITableViewCell {

    var groupMember: GroupMember?{
        didSet{
            memberName?.text = groupMember!.name!
        }
    }
    
    @IBOutlet var memberImageView: UIImageView!
    @IBOutlet var memberName: UILabel!
    var imageData:NSData?{
        didSet{
            let decodedimage = UIImage(data:imageData!)
            self.memberImageView.translatesAutoresizingMaskIntoConstraints = true
            self.memberImageView.image = decodedimage
            self.memberImageView.layer.masksToBounds = false
            self.memberImageView.layer.cornerRadius = self.memberImageView.frame.height/2
            self.memberImageView.clipsToBounds = true
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
