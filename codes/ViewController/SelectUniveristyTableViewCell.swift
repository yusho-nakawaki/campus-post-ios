//
//  SelectUniveristyTableViewCell.swift
//  match
//
//  on 2021/03/23.
//

import UIKit

class SelectUniveristyTableViewCell: UITableViewCell {
    
    private let uniLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(uniLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        uniLabel.frame = CGRect(x: 20, y: 5, width: contentView.width - 40, height: 30)
    }
    
    public func configure(uni: String) {
        uniLabel.text = uni
    }

}
