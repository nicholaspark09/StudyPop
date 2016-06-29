//
//  AlertTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class AlertTableViewCell: UITableViewCell {

    
    @IBOutlet var alertImageView: UIImageView!
    @IBOutlet var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
