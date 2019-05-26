import Foundation
import UIKit
import PureLayout

class SettingsPanel: UIView {
    
    var moveButton = UIView()
    var moveImage = UIImageView(image: UIImage(named: "ic_translate"))
    var scaleButton = UIView()
    var scaleImage = UIImageView(image: UIImage(named: "ic_increaseSize"))
    var brushButton = UIView()
    var brushImage = UIImageView(image: UIImage(named: "ic_pipette"))
    
    var moveBtnX: NSLayoutConstraint?
    var scaleBtnX: NSLayoutConstraint?
    var brushBtnX: NSLayoutConstraint?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        brushButton.backgroundColor = .white
        brushButton.layer.cornerRadius = 20
        addSubview(brushButton)
        brushButton.addSubview(brushImage)
        
        scaleButton.backgroundColor = .white
        scaleButton.layer.cornerRadius = 20
        addSubview(scaleButton)
        scaleButton.addSubview(scaleImage)
        
        moveButton.backgroundColor = .white
        moveButton.layer.cornerRadius = 20
        addSubview(moveButton)
        moveButton.addSubview(moveImage)
        
        
        brushButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
        brushButton.autoPinEdge(toSuperviewEdge: .right)
        brushButton.autoPinEdge(toSuperviewEdge: .top)
        brushButton.autoPinEdge(.bottom, to: .top, of: scaleButton, withOffset: -15)
        brushImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        
        scaleButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
        scaleButton.autoPinEdge(toSuperviewEdge: .right)
        scaleButton.autoPinEdge(.bottom, to: .top, of: moveButton, withOffset: -15)
        scaleImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        
        moveButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
        moveButton.autoPinEdge(toSuperviewEdge: .right)
        moveButton.autoPinEdge(toSuperviewEdge: .bottom)
        moveImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }
}
