//
//  EventPaymentTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/9/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class EventPaymentTableViewCell: UITableViewCell {

    
    @IBOutlet var paymentImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
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
