//
//  EventTableViewCell.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/9/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {

    var event: Event?{
        didSet{
            titleLabel.text = event!.name!
            if event!.start != nil{
                let formatter = NSDateFormatter()
                formatter.dateFormat = "EEEE"
                dayLabel.text = "\(formatter.stringFromDate(event!.start!))"
                formatter.dateFormat = "MMM dd"
                dateLabel.text = "\(formatter.stringFromDate(event!.start!))"
                if event!.startString != nil{
                    formatter.dateFormat = "H:mm a"
                    hourLabel.text = "\(formatter.stringFromDate(event!.start!))"
                }
            }
            if event!.info != nil && event!.info! != ""{
                textView.text = event!.info!
            }
            if event!.currentpeople != nil{
                attendingLabel.text = "\(event!.currentpeople!.intValue)"
            }
        }
    }
    
    @IBOutlet var hourLabel: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var attendingLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
