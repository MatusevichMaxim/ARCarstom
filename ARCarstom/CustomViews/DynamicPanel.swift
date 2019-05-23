import Foundation
import UIKit
import PureLayout

class DynamicPanel: UIView {
    
    let panelWidth = UIScreen.main.bounds.width / 1.5
    
    var viewController : ViewController?
    
    var cameraButton = UIImageView(image: UIImage(named: "ic_camera"))
    var pipetteButton = UIImageView(image: UIImage(named: "ic_pipette"))
    var resizeButton = UIImageView(image: UIImage(named: "ic_increaseSize"))
    var translateButton = UIImageView(image: UIImage(named: "ic_translate"))
    
    var cameraGesture : UITapGestureRecognizer?
    var pipetteGesture : UITapGestureRecognizer?
    var resizeGesture : UITapGestureRecognizer?
    var translateGesture : UITapGestureRecognizer?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        cameraGesture = UITapGestureRecognizer(target: self, action: #selector(onCameraAction))
        pipetteGesture = UITapGestureRecognizer(target: self, action: #selector(onPipetteAction))
        resizeGesture = UITapGestureRecognizer(target: self, action: #selector(onResizeAction))
        translateGesture = UITapGestureRecognizer(target: self, action: #selector(onTranslateAction))
        
        let itemsOffset = (panelWidth - (4 * 30)) / 5
        
        cameraButton.contentMode = .scaleAspectFit
        cameraButton.isUserInteractionEnabled = true
        addSubview(cameraButton)
        
        pipetteButton.contentMode = .scaleAspectFit
        pipetteButton.isUserInteractionEnabled = true
        addSubview(pipetteButton)
        
        resizeButton.contentMode = .scaleAspectFit
        resizeButton.isUserInteractionEnabled = true
        addSubview(resizeButton)
       
        translateButton.contentMode = .scaleAspectFit
        translateButton.isUserInteractionEnabled = true
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
        
        bringSubviewToFront(cameraButton)
    }
    
    func addTargets() {
        cameraButton.addGestureRecognizer(cameraGesture!)
        pipetteButton.addGestureRecognizer(pipetteGesture!)
        resizeButton.addGestureRecognizer(resizeGesture!)
        translateButton.addGestureRecognizer(translateGesture!)
    }
    
    func removeTargets() {
        cameraButton.removeGestureRecognizer(cameraGesture!)
        pipetteButton.removeGestureRecognizer(pipetteGesture!)
        resizeButton.removeGestureRecognizer(resizeGesture!)
        translateButton.removeGestureRecognizer(translateGesture!)
    }
    
    // MARK: buttons gestures
    
    @objc func onCameraAction(recognizer: UITapGestureRecognizer) {
        viewController?.cameraAction()
    }
    
    @objc func onPipetteAction(recognizer: UITapGestureRecognizer) {
        viewController?.pipetteAction()
    }
    
    @objc func onResizeAction(recognizer: UITapGestureRecognizer) {
        viewController?.resizeAction()
    }
    
    @objc func onTranslateAction(recognizer: UITapGestureRecognizer) {
        viewController?.translateAction()
    }
}
