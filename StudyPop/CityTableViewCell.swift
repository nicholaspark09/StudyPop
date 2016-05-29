//
//  CityTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class CityTableViewCell: UITableViewCell {

    var city:City?{
        didSet{
            titleLabel?.text = city!.name!
        }
    }
    
    
    
    @IBOutlet var titleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
