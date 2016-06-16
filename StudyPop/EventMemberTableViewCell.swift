//
//  EventMemberTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class EventMemberTableViewCell: UITableViewCell {

    
    @IBOutlet var memberImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    var imageData: NSData?{
        didSet{
            let decodedimage = UIImage(data:imageData!)
            self.memberImageView.translatesAutoresizingMaskIntoConstraints = true
            self.memberImageView.image = decodedimage
            self.memberImageView.layer.masksToBounds = false
            self.memberImageView.layer.cornerRadius = self.memberImageView.frame.height/2
            self.memberImageView.clipsToBounds = true
        }
    }
    
    var eventMember: EventMember?{
        didSet{
            nameLabel?.text = eventMember!.name!
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
