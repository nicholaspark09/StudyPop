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
        }
    }
    
    @IBOutlet var cityLabel: UILabel!
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
