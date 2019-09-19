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
    @IBOutlet var reduce: UIImageView!
    @IBOutlet var move: UIImageView!
    @IBOutlet var color: UIImageView!
    
    var reduceTapGR : BottomPanelTapGestureRecognizer!
    var moveTapGR : BottomPanelTapGestureRecognizer!
    var colorTapGR : BottomPanelTapGestureRecognizer!
    
    var currentModeId : Int = 0
    
    
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
        
        reduceTapGR = BottomPanelTapGestureRecognizer(target: self, action: #selector(self.onItemTapped(sender:)))
        moveTapGR = BottomPanelTapGestureRecognizer(target: self, action: #selector(self.onItemTapped(sender:)))
        colorTapGR = BottomPanelTapGestureRecognizer(target: self, action: #selector(self.onItemTapped(sender:)))
        
        reduceTapGR.id = 1
        moveTapGR.id = 2
        colorTapGR.id = 3
        
        reduce.addGestureRecognizer(reduceTapGR)
        move.addGestureRecognizer(moveTapGR)
        color.addGestureRecognizer(colorTapGR)
    
        panel.layer.cornerRadius = 16
        
        resetIcons()
    }
    
    @objc func onItemTapped(sender : BottomPanelTapGestureRecognizer) {
        resetIcons()
        
        switch sender.id {
        case 1:
            reduce.image = UIImage(named: "reduce_on")
            break
        case 2:
            move.image = UIImage(named: "move_on")
            break;
        default:
            color.image = UIImage(named: "color_wheel_on")
            break
        }
    }
    
    func resetIcons() {
        reduce.image = UIImage(named: "reduce_off")
        move.image = UIImage(named: "move_off")
        color.image = UIImage(named: "color_wheel_off")
    }
}
