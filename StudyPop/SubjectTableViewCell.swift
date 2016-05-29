//
//  SubjectTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class SubjectTableViewCell: UITableViewCell {

    
    var subject: Subject?{
        didSet{
            subjectLabel?.text = subject!.name!
        }
    }
    
    @IBOutlet var subjectLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
