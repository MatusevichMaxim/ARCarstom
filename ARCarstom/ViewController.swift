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

enum CategoryBitMask: Int {
    case categoryToSelect = 2
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var settingsPanel: UIView!
    @IBOutlet var radiusSlider: UISlider!
    @IBOutlet var depthSlider: UISlider!
    @IBOutlet var maskSwitch: UISwitch!
    
    var planeNode = SCNNode()
    var wheelNode = SCNNode()
    var wheelMaterial = SCNMaterial()
    
    var selectedNode : SCNNode?
    var maskNode : SCNNode?
    
    var wheelAdded : Bool = false
    
    
    // MARK: Base methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        setupUi()
        setupMaterials()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressed))
        sceneView.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        
        radiusSlider.removeTarget(self, action: #selector(onRadiusChanged), for: UIControl.Event.valueChanged)
        depthSlider.removeTarget(self, action: #selector(onDepthChanged), for: UIControl.Event.valueChanged)
        maskSwitch.removeTarget(self, action: #selector(onMaskVisibilityChanged), for: UIControl.Event.valueChanged)
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
                let wheelScene = SCNScene(named: "scnassets/rim2.scn")!
                if let childNode = wheelScene.rootNode.childNode(withName: "rim2", recursively: true) {
                    wheelNode = SCNNode()
                    wheelNode = childNode
                    wheelNode.position = SCNVector3(0, 0, 0)
                    wheelNode.scale = SCNVector3(0.2, 0.2, 0.2)
                    wheelNode.eulerAngles.y = -.pi / 2
                    wheelNode.geometry?.materials = [wheelMaterial]
                    wheelNode.categoryBitMask = CategoryBitMask.categoryToSelect.rawValue
                    wheelAdded = true
                    hidePlane()
                    
                    maskNode = createMask()
                    wheelNode.addChildNode(maskNode!)
                    maskNode!.position = SCNVector3(-wheelNode.scale.z / 2, 0, 0)
                    maskNode!.eulerAngles.y = .pi / 2
                    maskNode!.geometry?.firstMaterial?.transparency = 0
                    
                    planeNode.addChildNode(wheelNode)
                }
            }
        }
    }
    
    // MARK: Setup
    
    func setupUi() {
        settingsPanel.layer.cornerRadius = 16
        
        radiusSlider.addTarget(self, action: #selector(onRadiusChanged), for: UIControl.Event.valueChanged)
        depthSlider.addTarget(self, action: #selector(onDepthChanged), for: UIControl.Event.valueChanged)
        maskSwitch.addTarget(self, action: #selector(onMaskVisibilityChanged), for: UIControl.Event.valueChanged)
    }
    
    func setupMaterials() {
        wheelMaterial.lightingModel = .physicallyBased
        wheelMaterial.metalness.contents = 1.0
        wheelMaterial.roughness.contents = 0
    }
    
    // MARK: Controlls behaviour
    
    @objc func onRadiusChanged() {
        let startScale = SCNVector3(0.2, 0.2, 0.2)
        wheelNode.scale = SCNVector3(startScale.x + radiusSlider.value / 3,
                                     startScale.y + radiusSlider.value / 3,
                                     startScale.z + radiusSlider.value / 3)
    }
    
    @objc func onDepthChanged() {
        wheelNode.position = SCNVector3(0, 0, 0 + depthSlider.value / 10)
    }
    
    @objc func onMaskVisibilityChanged() {
        if maskSwitch.isOn {
            UIView.animate(withDuration: 1, animations: {
                self.maskNode!.geometry?.firstMaterial?.transparency = 1
            })
        } else {
            UIView.animate(withDuration: 1, animations: {
                self.maskNode!.geometry?.firstMaterial?.transparency = 0
            })
        }
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
        let maskPlane = SCNPlane(width: CGFloat(wheelNode.scale.x * 4.5), height: CGFloat(wheelNode.scale.y * 4.5))
        let maskMaterial = SCNMaterial()
        maskMaterial.diffuse.contents = UIImage(named: "scnassets/mask.png")
        maskPlane.materials = [maskMaterial]
        
        let node = SCNNode()
        node.geometry = maskPlane
        
        return node
    }
    
    // MARK: Translate object
    
    @objc func onLongPressed(recognizer: UILongPressGestureRecognizer) {
        guard let recognizerView = recognizer.view as? ARSCNView else { return }
        let touch = recognizer.location(in: recognizerView)
        
        if recognizer.state == .began {
            let hitTestResult = sceneView.hitTest(touch, options: [SCNHitTestOption.categoryBitMask: CategoryBitMask.categoryToSelect.rawValue])
            guard let hitNode = hitTestResult.first?.node else { return }

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
}
