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
    
    var plusButton = UIImageView(image: UIImage(named: "ic_plus"))
    var minusButton = UIImageView(image: UIImage(named: "ic_minus"))
    
    var leftButton = UIImageView(image: UIImage(named: "ic_left"))
    var rightButton = UIImageView(image: UIImage(named: "ic_right"))
    var upButton = UIImageView(image: UIImage(named: "ic_up"))
    var downButton = UIImageView(image: UIImage(named: "ic_down"))
    
    var cameraGesture : UITapGestureRecognizer?
    var pipetteGesture : UITapGestureRecognizer?
    var resizeGesture : UITapGestureRecognizer?
    var translateGesture : UITapGestureRecognizer?
    var plusGesture : UITapGestureRecognizer?
    var minusGesture : UITapGestureRecognizer?
    var leftGesture : UITapGestureRecognizer?
    var rightGesture : UITapGestureRecognizer?
    var upGesture : UITapGestureRecognizer?
    var downGesture : UITapGestureRecognizer?
    
    
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
        plusGesture = UITapGestureRecognizer(target: self, action: #selector(onPlusAction))
        minusGesture = UITapGestureRecognizer(target: self, action: #selector(onMinusAction))
        leftGesture = UITapGestureRecognizer(target: self, action: #selector(onLeftAction))
        rightGesture = UITapGestureRecognizer(target: self, action: #selector(onRightAction))
        upGesture = UITapGestureRecognizer(target: self, action: #selector(onUpAction))
        downGesture = UITapGestureRecognizer(target: self, action: #selector(onDownAction))
        
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
        
        plusButton.contentMode = .scaleAspectFit
        plusButton.alpha = 0
        plusButton.isUserInteractionEnabled = false
        addSubview(plusButton)
        
        minusButton.contentMode = .scaleAspectFit
        minusButton.alpha = 0
        minusButton.isUserInteractionEnabled = false
        addSubview(minusButton)
        
        leftButton.contentMode = .scaleAspectFit
        leftButton.alpha = 0
        leftButton.isUserInteractionEnabled = false
        addSubview(leftButton)
        
        rightButton.contentMode = .scaleAspectFit
        rightButton.alpha = 0
        rightButton.isUserInteractionEnabled = false
        addSubview(rightButton)
        
        upButton.contentMode = .scaleAspectFit
        upButton.alpha = 0
        upButton.isUserInteractionEnabled = false
        addSubview(upButton)
        
        downButton.contentMode = .scaleAspectFit
        downButton.alpha = 0
        downButton.isUserInteractionEnabled = false
        addSubview(downButton)
        
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
        
        plusButton.autoSetDimensions(to: CGSize(width: 20, height: 20))
        plusButton.autoAlignAxis(toSuperviewAxis: ALAxis.horizontal)
        plusButton.autoPinEdge(toSuperviewEdge: ALEdge.right, withInset: itemsOffset / 2 + 10)
        
        minusButton.autoSetDimensions(to: CGSize(width: 20, height: 20))
        minusButton.autoAlignAxis(toSuperviewAxis: ALAxis.horizontal)
        minusButton.autoPinEdge(toSuperviewEdge: ALEdge.left, withInset: itemsOffset / 2 + 10)
        
        leftButton.autoSetDimensions(to: CGSize(width: 20, height: 20))
        leftButton.autoAlignAxis(toSuperviewAxis: ALAxis.horizontal)
        leftButton.autoPinEdge(toSuperviewEdge: ALEdge.left, withInset: 15)
        
        rightButton.autoSetDimensions(to: CGSize(width: 20, height: 20))
        rightButton.autoAlignAxis(toSuperviewAxis: ALAxis.horizontal)
        rightButton.autoPinEdge(toSuperviewEdge: ALEdge.right, withInset: 15)
        
        upButton.autoSetDimensions(to: CGSize(width: 20, height: 20))
        upButton.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        upButton.autoPinEdge(toSuperviewEdge: ALEdge.top, withInset: 15)
        
        downButton.autoSetDimensions(to: CGSize(width: 20, height: 20))
        downButton.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        downButton.autoPinEdge(toSuperviewEdge: ALEdge.bottom, withInset: 15)
    }
    
    func addTargets() {
        cameraButton.addGestureRecognizer(cameraGesture!)
        pipetteButton.addGestureRecognizer(pipetteGesture!)
        resizeButton.addGestureRecognizer(resizeGesture!)
        translateButton.addGestureRecognizer(translateGesture!)
        plusButton.addGestureRecognizer(plusGesture!)
        minusButton.addGestureRecognizer(minusGesture!)
        leftButton.addGestureRecognizer(leftGesture!)
        rightButton.addGestureRecognizer(rightGesture!)
        upButton.addGestureRecognizer(upGesture!)
        downButton.addGestureRecognizer(downGesture!)
    }
    
    func removeTargets() {
        cameraButton.removeGestureRecognizer(cameraGesture!)
        pipetteButton.removeGestureRecognizer(pipetteGesture!)
        resizeButton.removeGestureRecognizer(resizeGesture!)
        translateButton.removeGestureRecognizer(translateGesture!)
        plusButton.removeGestureRecognizer(plusGesture!)
        minusButton.removeGestureRecognizer(minusGesture!)
        leftButton.removeGestureRecognizer(leftGesture!)
        rightButton.removeGestureRecognizer(rightGesture!)
        upButton.removeGestureRecognizer(upGesture!)
        downButton.removeGestureRecognizer(downGesture!)
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
    
    @objc func onPlusAction(recognizer: UITapGestureRecognizer) {
        viewController?.increaseAction()
    }
    
    @objc func onMinusAction(recognizer: UITapGestureRecognizer) {
        viewController?.reduceAction()
    }
    
    @objc func onLeftAction(recognizer: UITapGestureRecognizer) {
        viewController?.moveAction(withDirection: .left)
    }
    
    @objc func onRightAction(recognizer: UITapGestureRecognizer) {
        viewController?.moveAction(withDirection: .right)
    }
    
    @objc func onUpAction(recognizer: UITapGestureRecognizer) {
        viewController?.moveAction(withDirection: .up)
    }
    
    @objc func onDownAction(recognizer: UITapGestureRecognizer) {
        viewController?.moveAction(withDirection: .down)
    }
    
    // MARK: actions
    
    func showMainElements(withDelay delay : Double) {
        UIView.animate(withDuration: 0.1, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.cameraButton.alpha = 1
            self.pipetteButton.alpha = 1
            self.resizeButton.alpha = 1
            self.translateButton.alpha = 1
        }, completion: { finished in
            self.switchElementsInteraction(isEnabled: true)
        })
    }
    
    func hideMainElements() {
        switchElementsInteraction(isEnabled: false)
        
        UIView.animate(withDuration: 0.1, animations: {
            self.cameraButton.alpha = 0
            self.pipetteButton.alpha = 0
            self.resizeButton.alpha = 0
            self.translateButton.alpha = 0
        })
    }
    
    func showResizeElements() {
        UIView.animate(withDuration: 0.1, animations: {
            self.plusButton.alpha = 1
            self.minusButton.alpha = 1
        }, completion: { finished in
            self.switchResizeElementsInteraction(isEnabled: true)
        })
    }
    
    func hideResizeElements() {
        switchResizeElementsInteraction(isEnabled: false)
        
        UIView.animate(withDuration: 0.1, animations: {
            self.plusButton.alpha = 0
            self.minusButton.alpha = 0
        })
    }
    
    func showTranslateElements() {
        UIView.animate(withDuration: 0.1, animations: {
            self.leftButton.alpha = 1
            self.rightButton.alpha = 1
            self.upButton.alpha = 1
            self.downButton.alpha = 1
        }, completion: { finished in
            self.switchTranslateElementsInteraction(isEnabled: true)
        })
    }
    
    func hideTranslateElements() {
        switchTranslateElementsInteraction(isEnabled: false)
        
        UIView.animate(withDuration: 0.1, animations: {
            self.leftButton.alpha = 0
            self.rightButton.alpha = 0
            self.upButton.alpha = 0
            self.downButton.alpha = 0
        })
    }
    
    func switchElementsInteraction(isEnabled : Bool) {
        cameraButton.isUserInteractionEnabled = isEnabled
        pipetteButton.isUserInteractionEnabled = isEnabled
        resizeButton.isUserInteractionEnabled = isEnabled
        translateButton.isUserInteractionEnabled = isEnabled
    }
    
    func switchResizeElementsInteraction(isEnabled : Bool) {
        plusButton.isUserInteractionEnabled = isEnabled
        minusButton.isUserInteractionEnabled = isEnabled
    }
    
    func switchTranslateElementsInteraction(isEnabled : Bool) {
        leftButton.isUserInteractionEnabled = isEnabled
        rightButton.isUserInteractionEnabled = isEnabled
        upButton.isUserInteractionEnabled = isEnabled
        downButton.isUserInteractionEnabled = isEnabled
    }
}
