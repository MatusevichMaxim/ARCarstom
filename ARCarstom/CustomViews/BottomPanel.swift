//
//  BottomPanel.swift
//  ARCarstom
//
//  Created by Максим Матусевич on 9/4/19.
//  Copyright © 2019 Максим Матусевич. All rights reserved.
//

import UIKit
import PureLayout

class BottomPanel: UIView {

    @IBOutlet var panelView: UIView!
    @IBOutlet var more: UIView!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        SetupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        SetupView()
    }
    
    private func SetupView() {
        panelView?.layer.cornerRadius = 16
    }
}
