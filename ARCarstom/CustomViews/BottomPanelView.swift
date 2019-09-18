//
//  BottomPanelView.swift
//  ARCarstom
//
//  Created by Максим Матусевич on 9/18/19.
//  Copyright © 2019 Максим Матусевич. All rights reserved.
//

import UIKit

class BottomPanelView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet var panel: UIView!
    @IBOutlet var more: UIView!
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    func initSubviews() {
        let nib = UINib(nibName: "BottomPanelView", bundle: nil)
        nib.instantiate(withOwner: self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)
        
        panel.layer.cornerRadius = 16
    }
}
