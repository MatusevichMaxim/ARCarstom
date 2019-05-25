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
    @IBOutlet var bottomPanelConstraint: NSLayoutConstraint!
    
    var navigationPanel = UIView()
    var settingsButtonView = UIView()
    var actionButtonView = UIView()
    var cameraMaskView = UIView()
    var dynamicPanel = DynamicPanel()
    
    var actionGesture : UITapGestureRecognizer?
    var cameraMaskGesture : UITapGestureRecognizer?
    
    var panelPosY : NSLayoutConstraint?
    var dynamicPanelSize :[NSLayoutConstraint]?
    var cameraMaskSize : [NSLayoutConstraint]?
    
    let wheelDiameter : CGFloat = 0.3
    let portalDiameter : CGFloat = 0.126
    
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
        setupMaterials()
        
        actionGesture = UITapGestureRecognizer(target: self, action: #selector(onPanelAction))
        cameraMaskGesture = UITapGestureRecognizer(target: self, action: #selector(onCameraMaskPressed))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        sceneView.session.run(configuration)
        
        actionButtonView.addGestureRecognizer(actionGesture!)
        cameraMaskView.addGestureRecognizer(cameraMaskGesture!)
        dynamicPanel.addTargets()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        
        actionButtonView.removeGestureRecognizer(actionGesture!)
        cameraMaskView.removeGestureRecognizer(cameraMaskGesture!)
        dynamicPanel.removeTargets()
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
                
                let wheelScene = SCNScene(named: "scnassets/rim.scn")!
                if let childNode = wheelScene.rootNode.childNode(withName: "rim", recursively: true) {
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

        dynamicPanel.backgroundColor = .white
        dynamicPanel.layer.cornerRadius = 33
        dynamicPanel.isUserInteractionEnabled = false
        dynamicPanel.alpha = 0
        dynamicPanel.viewController = self
        dynamicPanel.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(dynamicPanel)
        
        actionButtonImage.autoCenterInSuperview()
        actionButtonImage.autoSetDimensions(to: CGSize(width: 24, height: 24))
        
        actionButtonView.autoPinEdge(ALEdge.bottom, to: ALEdge.top, of: panelView, withOffset: 37)
        actionButtonView.autoSetDimensions(to: CGSize(width: 65, height: 65))
        actionButtonView.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        
        cameraMaskView.autoCenterInSuperview()
        cameraMaskSize = cameraMaskView.autoSetDimensions(to: CGSize(width: 0, height: 0))
        
        dynamicPanel.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        dynamicPanelSize = dynamicPanel.autoSetDimensions(to: CGSize(width: UIScreen.main.bounds.width / 1.5, height: 66))
        panelPosY = dynamicPanel.autoPinEdge(ALEdge.bottom, to: ALEdge.top, of: actionButtonView, withOffset: -15)
        
        bottomPanelConstraint.constant = UIDevice.isXDevice() ? 0 : -20
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
    
    // MARK: dynamic panel behaviour
    
    @objc func onPanelAction(recognizer: UITapGestureRecognizer) {
        guard !isCameraMode else { return }
        
        actionButtonView.isUserInteractionEnabled = false
        let startWidth = UIScreen.main.bounds.width / 1.5
        
        if isResizeMode {
            isResizeMode = false
            dynamicPanel.hideResizeElements()
            dynamicPanel.showMainElements(withDelay: 0.2)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.dynamicPanelSize?.first?.constant = startWidth + 20
                self.view.layoutIfNeeded()
            }, completion: { finished in
                UIView.animate(withDuration: 0.1, animations: {
                    self.dynamicPanelSize?.first?.constant = startWidth
                    self.view.layoutIfNeeded()
                }, completion: { finished in
                    self.actionButtonView.isUserInteractionEnabled = true
                })
            })
            return
        }
        
        if isTranslateMode {
            isTranslateMode = false
            dynamicPanel.hideTranslateElements()
            dynamicPanel.showMainElements(withDelay: 0.2)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.dynamicPanelSize?.first?.constant = startWidth + 20
                self.dynamicPanelSize?.last?.constant = 66
                self.view.layoutIfNeeded()
            }, completion: { finished in
                UIView.animate(withDuration: 0.1, animations: {
                    self.dynamicPanelSize?.first?.constant = startWidth
                    self.view.layoutIfNeeded()
                }, completion: { finished in
                    self.actionButtonView.isUserInteractionEnabled = true
                })
            })
            return
        }
        
        if isPanelHidden {
            showPanel()
        }
        else {
            hidePanel()
        }
    }
    
    func showPanel() {
        let targetPosY = panelPosY!.constant - 20
        
        UIView.animate(withDuration: 0.3, animations: {
            self.panelPosY!.constant = targetPosY - 5
            self.view.layoutIfNeeded()
            self.dynamicPanel.alpha = 0.8
            self.actionButtonView.transform = CGAffineTransform(rotationAngle: -(225.0 * .pi) / 180.0)
        }, completion: { finished in
            UIView.animate(withDuration: 0.1, animations: {
                self.panelPosY!.constant = targetPosY
                self.view.layoutIfNeeded()
                self.dynamicPanel.alpha = 1
            }, completion: { finished in
                self.isPanelHidden = false
                self.actionButtonView.isUserInteractionEnabled = true
                self.dynamicPanel.isUserInteractionEnabled = true
            })
        })
    }
    
    func hidePanel() {
        let targetPosY = panelPosY!.constant + 20
        
        UIView.animate(withDuration: 0.3, animations: {
            self.panelPosY!.constant = targetPosY
            self.view.layoutIfNeeded()
            self.dynamicPanel.alpha = 0
            self.actionButtonView.transform = CGAffineTransform(rotationAngle: 0)
        }, completion: { finished in
            self.isPanelHidden = true
            self.actionButtonView.isUserInteractionEnabled = true
            self.dynamicPanel.isUserInteractionEnabled = false
        })
    }
    
    // MARK: Translate object
    
    @objc func onLongPressed(recognizer: UILongPressGestureRecognizer) {
        guard let recognizerView = recognizer.view as? ARSCNView else { return }
        let touch = recognizer.location(in: recognizerView)
        
        if recognizer.state == .began {
            let hitTestResult = sceneView.hitTest(touch, options: [SCNHitTestOption.categoryBitMask: CategoryBitMask.categoryToSelect.rawValue])
            guard let hitNode = hitTestResult.first?.node.parent else { return }

            self.selectedNode = hitNode
        } else if recognizer.state == .changed {
            guard let hitNode = selectedNode else { return }
            
            // perform a hitTest to obtain the plane
            let hitTestPlane = sceneView.hitTest(touch, types: .existingPlane)
            guard let hitPlane = hitTestPlane.first else { return }
            
            hitNode.position = SCNVector3(hitPlane.localTransform.columns.3.x,
                                          -hitPlane.localTransform.columns.3.z,
                                          hitNode.position.z)
        } else if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
            guard selectedNode != nil else { return }
            self.selectedNode = nil
        }
    }
    
    // MARK: controls
    
    func cameraAction() {
        isCameraMode = true
        hidePanel()
        cameraMaskView.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 0.3, animations: {
            self.cameraMaskSize?.first?.constant = 53
            self.cameraMaskSize?.last?.constant = 53
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
    
    @objc func onCameraMaskPressed(recognizer: UILongPressGestureRecognizer) {
        cameraMaskView.isUserInteractionEnabled = false
        
        showPanel()
        self.actionButtonView.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.cameraMaskSize?.first?.constant = 0
            self.cameraMaskSize?.last?.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
            self.actionButtonView.isUserInteractionEnabled = true
            self.isCameraMode = false
        })
    }
    
    func pipetteAction() {
        
    }
    
    func resizeAction() {
        actionButtonView.isUserInteractionEnabled = false
        isResizeMode = true
        
        dynamicPanel.hideMainElements()
        let startWidth = dynamicPanelSize?.first?.constant
        
        UIView.animate(withDuration: 0.1, animations: {
            self.dynamicPanelSize?.first?.constant = startWidth! + 20
            self.view.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.2, animations: {
                self.dynamicPanel.showResizeElements()
                self.dynamicPanelSize?.first?.constant = startWidth! / 2
                self.view.layoutIfNeeded()
            }, completion: { finished in
                self.actionButtonView.isUserInteractionEnabled = true
            })
        })
    }
    
    func translateAction() {
        actionButtonView.isUserInteractionEnabled = false
        isTranslateMode = true
        
        dynamicPanel.hideMainElements()
        let startSize = dynamicPanelSize!
        
        UIView.animate(withDuration: 0.1, animations: {
            self.dynamicPanelSize?.first?.constant = startSize.first!.constant + 20
            self.view.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.2, animations: {
                self.dynamicPanel.showTranslateElements()
                self.dynamicPanelSize?.first?.constant = startSize.first!.constant / 2
                self.dynamicPanelSize?.last?.constant = startSize.first!.constant
                self.view.layoutIfNeeded()
            }, completion: { finished in
                self.actionButtonView.isUserInteractionEnabled = true
            })
        })
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
    
    func moveAction(withDirection direction : Directions) {
        guard wheelAdded else { return }
        
        switch direction {
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
}
