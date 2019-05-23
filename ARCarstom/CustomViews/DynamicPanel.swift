import Foundation
import UIKit
import PureLayout

class DynamicPanel: UIView {
    
    let panelWidth = UIScreen.main.bounds.width / 1.5
    
    var cameraButton = UIImageView(image: UIImage(named: "ic_camera"))
    var pipetteButton = UIImageView(image: UIImage(named: "ic_pipette"))
    var resizeButton = UIImageView(image: UIImage(named: "ic_increaseSize"))
    var translateButton = UIImageView(image: UIImage(named: "ic_translate"))
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        let itemsOffset = (panelWidth - (4 * 30)) / 5
        
        cameraButton.contentMode = .scaleAspectFit
        addSubview(cameraButton)
        
        pipetteButton.contentMode = .scaleAspectFit
        addSubview(pipetteButton)
        
        resizeButton.contentMode = .scaleAspectFit
        addSubview(resizeButton)
       
        translateButton.contentMode = .scaleAspectFit
        addSubview(translateButton)
        
        cameraButton.autoSetDimensions(to: CGSize(width: 30, height: 30))
        cameraButton.autoAlignAxis(toSuperviewAxis: ALAxis.horizontal)
        cameraButton.autoPinEdge(ALEdge.right, to: ALEdge.left, of: pipetteButton, withOffset: -itemsOffset)
        
        pipetteButton.autoSetDimensions(to: CGSize(width: 30, height: 30))
        pipetteButton.autoAlignAxis(toSuperviewAxis: ALAxis.horizontal)
        pipetteButton.autoPinEdge(toSuperviewEdge: ALEdge.right, withInset: panelWidth / 2 + itemsOffset / 2)
        
        resizeButton.autoSetDimensions(to: CGSize(width: 30, height: 30))
        resizeButton.autoAlignAxis(toSuperviewAxis: ALAxis.horizontal)
        resizeButton.autoPinEdge(toSuperviewEdge: ALEdge.left, withInset: panelWidth / 2 + itemsOffset / 2)
        
        translateButton.autoSetDimensions(to: CGSize(width: 30, height: 30))
        translateButton.autoAlignAxis(toSuperviewAxis: ALAxis.horizontal)
        translateButton.autoPinEdge(ALEdge.left, to: ALEdge.right, of: resizeButton, withOffset: itemsOffset)
    }
}
