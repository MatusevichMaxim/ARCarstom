//
//  RimScene.swift
//  ARCarstom
//
//  Created by Максим Матусевич on 8/14/19.
//  Copyright © 2019 Максим Матусевич. All rights reserved.
//

import UIKit
import SceneKit
import PortalMask

enum RimAction {
    case Next
    case Previous
}

class RimScene: SCNNode {
    
    let wheelDiameter: CGFloat = 0.01
    var portalDiameter: CGFloat = 0.245
    var currentRimId: Int = 0 {
        willSet {
            rimNodes[currentRimId].isHidden = true
        }
        didSet {
            if currentRimId < 0 {
                currentRimId = rimNodes.count - 1
            }
            
            if currentRimId > rimNodes.count - 1 {
                currentRimId = 0
            }
            
            rimNodes[currentRimId].isHidden = false
        }
    }
    
    
    var portal: PortalMask?
    var rimNodes = [SCNNode]()
    var brakeScene: SCNScene?
    var maskNode: SCNNode?
    
    var rimMaterial = SCNMaterial()
    
    
    override init() {
        super.init()
        setupSceneNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSceneNode()
    }
    
    func setupSceneNode() {
        setupMaterials()
        
        portal = PortalMask(radius: portalDiameter)
        addChildNode(portal!)
        
        let rim_1 = SCNScene(named: "scnassets/rim_1.scn")
        if let rimChildNode = rim_1?.rootNode.childNode(withName: "rim_1", recursively: true) {
            createRim(fromNode: rimChildNode)
        }
        
        let rim_2 = SCNScene(named: "scnassets/rim_2.scn")
        if let rimChildNode = rim_2?.rootNode.childNode(withName: "rim_2", recursively: true) {
            createRim(fromNode: rimChildNode)
        }
        
        let rim_3 = SCNScene(named: "scnassets/rim_3.scn")
        if let rimChildNode = rim_3?.rootNode.childNode(withName: "rim_3", recursively: true) {
            createRim(fromNode: rimChildNode)
        }
        
        brakeScene = SCNScene(named: "scnassets/brake.scn")
        if let brakeChildNode = brakeScene?.rootNode.childNode(withName: "brake", recursively: true) {
            let brakeNode = createBrakeNode(childNode: brakeChildNode)
            addChildNode(brakeNode)
        }
        
        maskNode = createMask()
        addChildNode(maskNode!)
        maskNode!.position = SCNVector3(0, 0, -0.5)
        
        for node in rimNodes {
            node.isHidden = true
        }
        rimNodes[currentRimId].isHidden = false
    }
    
    func createRim(fromNode node : SCNNode) {
        var rim = SCNNode()
        rim = node
        rim.position = SCNVector3(0, 0, -0.115)
        rim.scale = SCNVector3(wheelDiameter, wheelDiameter, wheelDiameter)
        rim.eulerAngles.y = -.pi / 2
        rim.geometry?.materials = [rimMaterial]
        
        rimNodes.append(rim)
        addChildNode(rim)
    }
    
    func createMaterial(light isLight: Bool) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.metalness.contents = 1.0
        material.roughness.contents = 0
        material.diffuse.contents = isLight ? UIColor.white : UIColor.darkGray
        
        return material
    }
    
    func createBrakeNode(childNode: SCNNode) -> SCNNode {
        var brakeNode = SCNNode()
        brakeNode = childNode
        brakeNode.position = SCNVector3(0, 0, -0.115)
        brakeNode.scale = SCNVector3(wheelDiameter, wheelDiameter, wheelDiameter)
        brakeNode.eulerAngles.y = -.pi / 2
        
        let geom = brakeNode.childNode(withName: "Geom", recursively: true)
        
        let disk = geom?.childNode(withName: "Disk", recursively: true)
        disk?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "scnassets/brakeDisk.png")
        let caliper = geom?.childNode(withName: "Caliper_Brembo_8P", recursively: true)
        caliper?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "scnassets/caliper.png")
        let massNuts = geom?.childNode(withName: "Wheel_mass_nuts", recursively: true)
        massNuts?.geometry?.firstMaterial = createMaterial(light: false)
        let brakeRotor = geom?.childNode(withName: "Brake_rotor", recursively: true)
        brakeRotor?.geometry?.firstMaterial = createMaterial(light: false)
        let bolts = geom?.childNode(withName: "Object020", recursively: true)
        bolts?.geometry?.firstMaterial = createMaterial(light: false)
        
        return brakeNode
    }
    
    func createMask() -> SCNNode {
        let maskPlane = SCNPlane(width: CGFloat(1), height: CGFloat(1))
        let maskMaterial = SCNMaterial()
        maskMaterial.diffuse.contents = UIImage(named: "scnassets/mask.png")
        maskPlane.materials = [maskMaterial]
        
        let node = SCNNode()
        node.geometry = maskPlane
        
        return node
    }
    
    func setupMaterials() {
        rimMaterial.lightingModel = .physicallyBased
        rimMaterial.metalness.contents = 1.0
        rimMaterial.roughness.contents = 0
    }
    
    public func switchRim(rimAction: RimAction) {
        if rimAction == .Next {
            currentRimId += 1
        } else {
            currentRimId -= 1
        }
    }
}
