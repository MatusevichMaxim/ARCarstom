//
//  ViewController.swift
//  ARCarstom
//
//  Created by Максим Матусевич on 5/11/19.
//  Copyright © 2019 Максим Матусевич. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import PortalMask
import PureLayout

enum CategoryBitMask: Int {
    case categoryToSelect = 2
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var panelView: UIView!
    @IBOutlet var staticButton: UIImageView!
    @IBOutlet var autoButton: UIImageView!
    @IBOutlet var shotButton: UIImageView!
    @IBOutlet var shopButton: UIImageView!
    @IBOutlet var bottomPanelConstraint: NSLayoutConstraint!
    
    var moveButton = UIView()
    var moveImage = UIImageView(image: UIImage(named: "ic_translate"))
    var scaleButton = UIView()
    var scaleImage = UIImageView(image: UIImage(named: "ic_increaseSize"))
    var brushButton = UIView()
    var brushImage = UIImageView(image: UIImage(named: "ic_pipette"))
    
    var movePanel = UIView()
    var resizePanel = UIView()
    
    var moveBtnX: NSLayoutConstraint?
    var scaleBtnX: NSLayoutConstraint?
    var brushBtnX: NSLayoutConstraint?
    var movePanelX: NSLayoutConstraint?
    var resizePanelX: NSLayoutConstraint?
    
    var navigationPanel = UIView()
    var settingsButtonView = UIView()
    var actionButtonView = UIView()
    var cameraMaskView = UIView()
    
    var shotGesture : UITapGestureRecognizer?
    var actionGesture : UITapGestureRecognizer?
    var cameraMaskGesture : UITapGestureRecognizer?
    var moveGesture: UITapGestureRecognizer?
    var scaleGesture: UITapGestureRecognizer?
    var brushGesture: UITapGestureRecognizer?
    
    var leftGesture: CustomGestureRecognizer?
    var rightGesture: CustomGestureRecognizer?
    var upGesture: CustomGestureRecognizer?
    var downGesture: CustomGestureRecognizer?
    var increaseGesture: UITapGestureRecognizer?
    var reduceGesture: UITapGestureRecognizer?
    
    var dynamicPanelSize :[NSLayoutConstraint]?
    var cameraMaskSize : [NSLayoutConstraint]?
    
    let wheelDiameter : CGFloat = 0.01
    let portalDiameter : CGFloat = 0.246
    
    var planeNode = SCNNode()
    var container = SCNNode()
    var wheelNode = SCNNode()
    var wheelMaterial = SCNMaterial()
    
    var selectedNode : SCNNode?
    var maskNode : SCNNode?
    
    var wheelAdded : Bool = false
    var isPanelHidden : Bool = true
    var isCameraMode : Bool = false
    var isResizeMode : Bool = false
    var isTranslateMode : Bool = false
    
    
    // MARK: Base methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        setupUi()
        setupSettingsPanel()
        setupMaterials()
        
        shotGesture = UITapGestureRecognizer(target: self, action: #selector(onShotAction))
        actionGesture = UITapGestureRecognizer(target: self, action: #selector(onActionBtnClicked))
        cameraMaskGesture = UITapGestureRecognizer(target: self, action: #selector(onCameraMaskPressed))
        
        moveGesture = UITapGestureRecognizer(target: self, action: #selector(onMoveBtnAction))
        scaleGesture = UITapGestureRecognizer(target: self, action: #selector(onScaleBtnAction))
        brushGesture = UITapGestureRecognizer(target: self, action: #selector(onBrushBtnAction))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        sceneView.session.run(configuration)
        
        shotButton.addGestureRecognizer(shotGesture!)
        actionButtonView.addGestureRecognizer(actionGesture!)
        cameraMaskView.addGestureRecognizer(cameraMaskGesture!)
        moveButton.addGestureRecognizer(moveGesture!)
        scaleButton.addGestureRecognizer(scaleGesture!)
        brushButton.addGestureRecognizer(brushGesture!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        
        shotButton.removeGestureRecognizer(shotGesture!)
        actionButtonView.removeGestureRecognizer(actionGesture!)
        cameraMaskView.removeGestureRecognizer(cameraMaskGesture!)
        moveButton.removeGestureRecognizer(moveGesture!)
        scaleButton.removeGestureRecognizer(scaleGesture!)
        brushButton.removeGestureRecognizer(brushGesture!)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        planeNode = createPlane(withPlaneAnchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !wheelAdded else { return }

        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)

            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if results.first != nil {
                let portal = PortalMask(radius: portalDiameter)
                container.addChildNode(portal)
                
                let wheelScene = SCNScene(named: "scnassets/rim2.scn")!
                if let childNode = wheelScene.rootNode.childNode(withName: "rim2", recursively: true) {
                    wheelNode = SCNNode()
                    wheelNode = childNode
                    wheelNode.position = SCNVector3(0, 0, 0)
                    wheelNode.scale = SCNVector3(wheelDiameter, wheelDiameter, wheelDiameter)
                    wheelNode.eulerAngles.y = -.pi / 2
                    wheelNode.geometry?.materials = [wheelMaterial]
                    wheelNode.categoryBitMask = CategoryBitMask.categoryToSelect.rawValue
                    wheelAdded = true
                    hidePlane()

                    maskNode = createMask()
                    wheelNode.addChildNode(maskNode!)
                    maskNode!.position = SCNVector3(-wheelNode.scale.z * 5, 0, 0)
                    maskNode!.eulerAngles.y = .pi / 2
                    maskNode!.geometry?.firstMaterial?.transparency = 0

                    container.addChildNode(wheelNode)
                }
            
                planeNode.addChildNode(container)
            }
        }
    }
    
    // MARK: Setup
    
    func setupUi() {
        actionButtonView.backgroundColor = UIColor(red: 236, green: 69, blue: 38)
        actionButtonView.layer.cornerRadius = 33
        actionButtonView.isUserInteractionEnabled = true
        view.addSubview(actionButtonView)
        
        let actionButtonImage = UIImageView(image: UIImage(named: "ic_add"))
        actionButtonImage.isUserInteractionEnabled = false
        actionButtonView.addSubview(actionButtonImage)
        
        cameraMaskView.backgroundColor = .white
        cameraMaskView.isUserInteractionEnabled = false
        cameraMaskView.translatesAutoresizingMaskIntoConstraints = true
        cameraMaskView.layer.cornerRadius = 25
        actionButtonView.addSubview(cameraMaskView)

        actionButtonImage.autoCenterInSuperview()
        actionButtonImage.autoSetDimensions(to: CGSize(width: 24, height: 24))
        
        actionButtonView.autoPinEdge(ALEdge.bottom, to: ALEdge.top, of: panelView, withOffset: 39)
        actionButtonView.autoSetDimensions(to: CGSize(width: 64, height: 64))
        actionButtonView.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        
        cameraMaskView.autoCenterInSuperview()
        cameraMaskSize = cameraMaskView.autoSetDimensions(to: CGSize(width: 0, height: 0))
        
        bottomPanelConstraint.constant = UIDevice.isXDevice() ? 0 : -20
    }
    
    func setupSettingsPanel() {
        brushButton.backgroundColor = .white
        brushButton.layer.cornerRadius = 20
        brushButton.isUserInteractionEnabled = true
        view.addSubview(brushButton)
        brushButton.addSubview(brushImage)
        
        scaleButton.backgroundColor = .white
        scaleButton.layer.cornerRadius = 20
        scaleButton.isUserInteractionEnabled = true
        view.addSubview(scaleButton)
        scaleButton.addSubview(scaleImage)
        
        moveButton.backgroundColor = .white
        moveButton.layer.cornerRadius = 20
        moveButton.isUserInteractionEnabled = true
        view.addSubview(moveButton)
        moveButton.addSubview(moveImage)
        
        setupMovePanel()
        setupResizePanel()
        
        brushButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
        brushBtnX = brushButton.autoPinEdge(.left, to: .right, of: view)
        brushButton.autoPinEdge(.bottom, to: .top, of: scaleButton, withOffset: -15)
        brushImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        
        scaleButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
        scaleBtnX = scaleButton.autoPinEdge(.left, to: .right, of: view)
        scaleButton.autoPinEdge(.bottom, to: .top, of: moveButton, withOffset: -15)
        scaleImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        
        moveButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
        moveBtnX = moveButton.autoPinEdge(.left, to: .right, of: view)
        moveButton.autoPinEdge(.bottom, to: .top, of: movePanel, withOffset: -15)
        moveImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        
        movePanel.autoSetDimensions(to: CGSize(width: 95, height: 95))
        movePanelX = movePanel.autoPinEdge(.left, to: .right, of: view)
        movePanel.autoPinEdge(.bottom, to: .top, of: panelView, withOffset: -15)
        
        resizePanel.autoSetDimension(.width, toSize: 40)
        resizePanelX = resizePanel.autoPinEdge(.left, to: .right, of: view)
        resizePanel.autoPinEdge(.top, to: .top, of: movePanel)
        resizePanel.autoPinEdge(.bottom, to: .bottom, of: movePanel)
    }
    
    func setupMovePanel() {
        leftGesture = CustomGestureRecognizer(target: self, action: #selector(moveAction))
        rightGesture = CustomGestureRecognizer(target: self, action: #selector(moveAction))
        upGesture = CustomGestureRecognizer(target: self, action: #selector(moveAction))
        downGesture = CustomGestureRecognizer(target: self, action: #selector(moveAction))
        
        movePanel.backgroundColor = .white
        movePanel.layer.cornerRadius = 20
        movePanel.isUserInteractionEnabled = true
        movePanel.clipsToBounds = true
        view.addSubview(movePanel)
        
        let leftImg = UIImageView(image: UIImage(named: "ic_left"))
        leftImg.contentMode = .scaleAspectFit
        
        let leftZone = UIView()
        leftZone.isUserInteractionEnabled = true
        movePanel.addSubview(leftZone)
        leftZone.addSubview(leftImg)
        leftZone.addGestureRecognizer(leftGesture!)
        leftGesture?.direction = .left
        
        leftImg.autoSetDimensions(to: CGSize(width: 15, height: 15))
        leftImg.autoCenterInSuperview()
        leftZone.autoPinEdge(toSuperviewEdge: .left)
        leftZone.autoAlignAxis(toSuperviewAxis: .horizontal)
        leftZone.autoSetDimensions(to: CGSize(width: 95 / 3, height: 95 / 3))
        
        let rightImg = UIImageView(image: UIImage(named: "ic_right"))
        rightImg.contentMode = .scaleAspectFit
        
        let rightZone = UIView()
        rightZone.isUserInteractionEnabled = true
        movePanel.addSubview(rightZone)
        rightZone.addSubview(rightImg)
        rightZone.addGestureRecognizer(rightGesture!)
        rightGesture?.direction = .right
        
        rightImg.autoSetDimensions(to: CGSize(width: 15, height: 15))
        rightImg.autoCenterInSuperview()
        rightZone.autoPinEdge(toSuperviewEdge: .right)
        rightZone.autoAlignAxis(toSuperviewAxis: .horizontal)
        rightZone.autoSetDimensions(to: CGSize(width: 95 / 3, height: 95 / 3))
        
        let upImg = UIImageView(image: UIImage(named: "ic_up"))
        upImg.contentMode = .scaleAspectFit
        
        let upZone = UIView()
        upZone.isUserInteractionEnabled = true
        movePanel.addSubview(upZone)
        upZone.addSubview(upImg)
        upZone.addGestureRecognizer(upGesture!)
        upGesture?.direction = .up
        
        upImg.autoSetDimensions(to: CGSize(width: 15, height: 15))
        upImg.autoCenterInSuperview()
        upZone.autoPinEdge(toSuperviewEdge: .top)
        upZone.autoAlignAxis(toSuperviewAxis: .vertical)
        upZone.autoSetDimensions(to: CGSize(width: 95 / 3, height: 95 / 3))
        
        let downImg = UIImageView(image: UIImage(named: "ic_down"))
        downImg.contentMode = .scaleAspectFit
        
        let downZone = UIView()
        downZone.isUserInteractionEnabled = true
        movePanel.addSubview(downZone)
        downZone.addSubview(downImg)
        downZone.addGestureRecognizer(downGesture!)
        downGesture?.direction = .down
        
        downImg.autoSetDimensions(to: CGSize(width: 15, height: 15))
        downImg.autoCenterInSuperview()
        downZone.autoPinEdge(toSuperviewEdge: .bottom)
        downZone.autoAlignAxis(toSuperviewAxis: .vertical)
        downZone.autoSetDimensions(to: CGSize(width: 95 / 3, height: 95 / 3))
    }
    
    func setupResizePanel() {
        resizePanel.backgroundColor = .white
        resizePanel.layer.cornerRadius = 20
        resizePanel.isUserInteractionEnabled = true
        resizePanel.clipsToBounds = true
        view.addSubview(resizePanel)
        
        let plusImg = UIImageView(image: UIImage(named: "ic_plus"))
        plusImg.contentMode = .scaleAspectFit
        
        let plusZone = UIView()
        resizePanel.addSubview(plusZone)
        plusZone.addSubview(plusImg)
        
        plusImg.autoSetDimensions(to: CGSize(width: 15, height: 15))
        plusImg.autoCenterInSuperview()
        plusZone.autoPinEdge(toSuperviewEdge: .top)
        plusZone.autoAlignAxis(toSuperviewAxis: .vertical)
        plusZone.autoSetDimensions(to: CGSize(width: 40, height: 95 / 2))
        
        let minusImg = UIImageView(image: UIImage(named: "ic_minus"))
        minusImg.contentMode = .scaleAspectFit
        
        let minusZone = UIView()
        resizePanel.addSubview(minusZone)
        minusZone.addSubview(minusImg)
        
        minusImg.autoSetDimensions(to: CGSize(width: 15, height: 15))
        minusImg.autoCenterInSuperview()
        minusZone.autoPinEdge(toSuperviewEdge: .bottom)
        minusZone.autoAlignAxis(toSuperviewAxis: .vertical)
        minusZone.autoSetDimensions(to: CGSize(width: 40, height: 95 / 2))
    }
    
    func setupMaterials() {
        wheelMaterial.lightingModel = .physicallyBased
        wheelMaterial.metalness.contents = 1.0
        wheelMaterial.roughness.contents = 0
    }
    
    // MARK: Plane behaviour
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "scnassets/wheelgrid.png")
        plane.materials = [gridMaterial]
        
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        planeNode.geometry = plane
        
        return planeNode
    }
    
    func hidePlane() {
        UIView.animate(withDuration: 1, animations: {
            self.planeNode.geometry?.firstMaterial?.transparency = 0
        })
        
        self.sceneView.debugOptions = []
    }
    
    func createMask() -> SCNNode {
        let maskPlane = SCNPlane(width: CGFloat(wheelNode.scale.x * 10), height: CGFloat(wheelNode.scale.y * 10))
        let maskMaterial = SCNMaterial()
        maskMaterial.diffuse.contents = UIImage(named: "scnassets/mask.png")
        maskPlane.materials = [maskMaterial]
        
        let node = SCNNode()
        node.geometry = maskPlane
        
        return node
    }
    
    @objc func onActionBtnClicked(recognizer: UITapGestureRecognizer) {
        guard !isCameraMode else { return }
        actionButtonView.isUserInteractionEnabled = false
        
        if isPanelHidden {
            panelShowsAnimation()
        }
        else {
            panelHidesAnimation()
        }
    }
    
    // MARK: controls
    
    @objc func onShotAction(recognizer: UITapGestureRecognizer) {
        guard !isCameraMode else { return }
        
        if !isPanelHidden {
            panelHidesAnimation()
        }
        
        isCameraMode = true
        
        cameraActivateAnimation()
    }
    
    @objc func onCameraMaskPressed(recognizer: UITapGestureRecognizer) {
        cameraMaskView.isUserInteractionEnabled = false
        self.actionButtonView.isUserInteractionEnabled = false
        
        cameraCloseAnimation()
    }
    
    func increaseAction() {
        guard wheelAdded else { return }
        
        container.scale.x += 0.01
        container.scale.y += 0.01
        container.scale.z += 0.01
    }
    
    func reduceAction() {
        guard wheelAdded else { return }
        
        container.scale.x -= 0.01
        container.scale.y -= 0.01
        container.scale.z -= 0.01
    }
    
    @objc func moveAction(recognizer: CustomGestureRecognizer) {
        guard wheelAdded else { return }
        
        switch recognizer.direction! {
        case .left:
            container.position = SCNVector3(container.position.x - 0.01, container.position.y, container.position.z)
        case .right:
            container.position = SCNVector3(container.position.x + 0.01, container.position.y, container.position.z)
        case .up:
            container.position = SCNVector3(container.position.x, container.position.y + 0.01, container.position.z)
        case .down:
            container.position = SCNVector3(container.position.x, container.position.y - 0.01, container.position.z)
        }
    }
    
    // MARK: animations
    
    func cameraActivateAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            self.cameraMaskSize?.first?.constant = 53
            self.cameraMaskSize?.last?.constant = 53
            self.shotButton.alpha = 0.05
            self.view.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.1, animations: {
                self.cameraMaskSize?.first?.constant = 50
                self.cameraMaskSize?.last?.constant = 50
                self.view.layoutIfNeeded()
            }, completion: { finished in
                self.cameraMaskView.isUserInteractionEnabled = true
            })
        })
    }
    
    func cameraCloseAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            self.cameraMaskSize?.first?.constant = 0
            self.cameraMaskSize?.last?.constant = 0
            self.shotButton.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: { finished in
            self.actionButtonView.isUserInteractionEnabled = true
            self.isCameraMode = false
        })
    }
    
    func panelShowsAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            self.actionButtonView.transform = CGAffineTransform(rotationAngle: -(225.0 * .pi) / 180.0)
            self.showComponents()
        }, completion: { finished in
            self.isPanelHidden = false
            self.actionButtonView.isUserInteractionEnabled = true
        })
    }
    
    func panelHidesAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            self.actionButtonView.transform = CGAffineTransform(rotationAngle: 0)
            self.hideComponents()
        }, completion: { finished in
            self.isPanelHidden = true
            self.actionButtonView.isUserInteractionEnabled = true
        })
    }
    
    func showComponents()
    {
        UIView.animate(withDuration: 0.2, animations: {
            self.moveBtnX?.constant = -70
            self.view.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.1, animations: {
                self.moveBtnX?.constant = -60
                self.view.layoutIfNeeded()
            })
        })
        
        UIView.animate(withDuration: 0.2, delay: 0.1, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.scaleBtnX?.constant = -70
            self.view.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.1, animations: {
                self.scaleBtnX?.constant = -60
                self.view.layoutIfNeeded()
            })
        })
        
        UIView.animate(withDuration: 0.2, delay: 0.2, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.brushBtnX?.constant = -70
            self.view.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.1, animations: {
                self.brushBtnX?.constant = -60
                self.view.layoutIfNeeded()
            })
        })
    }
    
    func hideComponents() {
        UIView.animate(withDuration: 0.2, animations: {
            self.moveBtnX?.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
            
        })
        
        UIView.animate(withDuration: 0.2, delay: 0.1, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.scaleBtnX?.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
            
        })
        
        UIView.animate(withDuration: 0.2, delay: 0.2, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.brushBtnX?.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
            
        })
        
        if isTranslateMode {
            hideMovePanel()
        }
        
        if isResizeMode {
            hideResizePanel()
        }
    }
    
    func showMovePanel() {
        isTranslateMode = true
        UIView.animate(withDuration: 0.2, animations: {
            self.movePanelX?.constant = -125
            self.view.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.1, animations: {
                self.movePanelX?.constant = -115
                self.view.layoutIfNeeded()
            })
        })
    }
    
    func hideMovePanel() {
        isTranslateMode = false
        UIView.animate(withDuration: 0.2, animations: {
            self.movePanelX?.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
        })
    }
    
    func showResizePanel() {
        isResizeMode = true
        UIView.animate(withDuration: 0.2, animations: {
            self.resizePanelX?.constant = -70
            self.view.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.1, animations: {
                self.resizePanelX?.constant = -60
                self.view.layoutIfNeeded()
            })
        })
    }
    
    func hideResizePanel() {
        isResizeMode = false
        UIView.animate(withDuration: 0.2, animations: {
            self.resizePanelX?.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
        })
    }
    
    // MARK: buttons behaviours
    
    @objc func onMoveBtnAction(recognizer: UITapGestureRecognizer) {
        if isTranslateMode {
            hideMovePanel()
        } else {
            if isResizeMode {
                hideResizePanel()
            }
            
            showMovePanel()
        }
    }
    
    @objc func onScaleBtnAction(recognizer: UITapGestureRecognizer) {
        if isResizeMode {
            hideResizePanel()
        } else {
            if isTranslateMode {
                hideMovePanel()
            }
            
            showResizePanel()
        }
    }
    
    @objc func onBrushBtnAction(recognizer: UITapGestureRecognizer) {
        
    }
}
