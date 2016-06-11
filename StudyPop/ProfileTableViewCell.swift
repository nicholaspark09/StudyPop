//
//  ProfileTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/7/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

    var profile: Profile?{
        didSet{
            if profile!.name != nil && profile!.name! != ""{
                nameLabel?.text = profile!.name!
            }else{
                nameLabel?.text = "No name"
            }
            if profile!.city != nil{
                cityLabel.text = self.profile!.city!.name!
            }
        }
    }
    
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    var thumbData:NSData?{
        didSet{
            let decodedimage = UIImage(data:thumbData!)
            self.profileImageView.translatesAutoresizingMaskIntoConstraints = true
            self.profileImageView.image = decodedimage
            self.profileImageView.layer.masksToBounds = false
            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.height/2
            self.profileImageView.clipsToBounds = true
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
