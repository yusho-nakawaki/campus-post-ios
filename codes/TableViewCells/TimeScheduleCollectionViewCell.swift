//
//  TimeScheduleCollectionViewCell.swift
//  Match
//
//  on 2021/01/10.
//

import UIKit


class TimeScheduleCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var teacherLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var marginBottomHeight: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        subjectLabel.textColor = .black
        teacherLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        placeLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        
        subjectLabel.numberOfLines = 0
        
        if contentView.height < 110 {
            marginBottomHeight.constant = 2
        }
    }
    
    
    public func configure(model: TimeScheduleStruct) {
        subjectLabel.text = model.subject
        teacherLabel.text = model.teacher
        placeLabel.text = model.place ?? ""
    }
    
}
