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
            if group!.thumbblob != nil{
                setupImage()
            }
        }
    }
    
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var groupNameLabel: UILabel!
    @IBOutlet var groupImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupImage(){
        if group != nil && group!.thumbblob != nil{
            if let decodedimage = UIImage(data: group!.thumbblob!){
                self.groupImageView.translatesAutoresizingMaskIntoConstraints = true
                self.groupImageView.image = decodedimage as UIImage
                self.groupImageView.layer.masksToBounds = false
                self.groupImageView.layer.cornerRadius = self.groupImageView.frame.height/2
                self.groupImageView.clipsToBounds = true
                self.groupImageView.contentMode = UIViewContentMode.ScaleAspectFit
            }
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
