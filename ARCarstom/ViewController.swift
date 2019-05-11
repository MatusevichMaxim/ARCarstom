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

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var settingsPanel: UIView!
    @IBOutlet var radiusSlider: UISlider!
    @IBOutlet var depthSlider: UISlider!
    
    var planeNode = SCNNode()
    var wheelNode = SCNNode()
    
    
    // MARK: Base methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        setupUi()
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
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        planeNode = createPlane(withPlaneAnchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if let hitResult = results.first {
                let wheelScene = SCNScene(named: "art.scnassets/rim2.scn")!
                if let childNode = wheelScene.rootNode.childNode(withName: "rim2", recursively: true) {
                    wheelNode = childNode
                    wheelNode.position = SCNVector3(0, 0, 0)
                    wheelNode.scale = SCNVector3(0.2, 0.2, 0.2)
                    wheelNode.eulerAngles.y = -.pi / 2
                    
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
    }
    
    // MARK: Sliders behaviour
    
    @objc func onRadiusChanged() {
        let startScale = SCNVector3(0.2, 0.2, 0.2)
        wheelNode.scale = SCNVector3(startScale.x + radiusSlider.value / 3,
                                     startScale.y + radiusSlider.value / 3,
                                     startScale.z + radiusSlider.value / 3)
    }
    
    @objc func onDepthChanged() {
        wheelNode.position = SCNVector3(0, 0, 0 + depthSlider.value / 10)
    }
    
    // MARK: Plane creation
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/wheelgrid.png")
        plane.materials = [gridMaterial]
        
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        planeNode.geometry = plane
        
        return planeNode
    }
}
