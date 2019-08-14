import UIKit
import SceneKit
import ARKit
import Firebase
import FirebaseMLCommon
import CoreML
import CoreGraphics
import Foundation

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    let planeName = "plane"
    let modelName = "model_2019_07_21_07_08"
    let modelType = "tflite"
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var frameRect: UIImageView!
    @IBOutlet var detectedMask: UIView!
    
    var rimAdded = false
    
    var model: LocalModel!
    var interpreter: ModelInterpreter!
    var ioOptions: ModelInputOutputOptions!
    
    var lastProcessedFrame: ARFrame?
    var frameCenter: CGPoint = CGPoint.zero
    
    var lifecycleWatchDog = WatchDog(named: "AI Testing")
    
    var rimScene = RimScene()
    var planeNode: SCNNode?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = false
        sceneView.autoenablesDefaultLighting = true
        
        if loadModel() {
            buildInterpreter()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        sceneView.session.run(configuration)
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.global().async() {
            self.updateCoreML(with: frame)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        guard planeNode == nil else { return }
        
        planeNode = createPlane(anchor: anchorPlane)
        planeNode?.position = SCNVector3(anchorPlane.center.x, anchorPlane.center.y, anchorPlane.center.z)
        node.addChildNode(planeNode!)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        planeNode?.position = SCNVector3(anchorPlane.center.x, anchorPlane.center.y, anchorPlane.center.z)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first != nil {
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.0)
            planeNode?.geometry?.materials = [gridMaterial]
            planeNode?.addChildNode(rimScene)
            
            rimAdded = true
        }
    }
    
    func createPlane(anchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
        plane.materials = [gridMaterial]
        
        let planeNode = SCNNode()
        planeNode.name = planeName
        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        planeNode.geometry = plane
        
        return planeNode
    }
    
    func removeNode(named: String) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == named {
                node.removeFromParentNode()
            }
        }
    }
    
    func updateCoreML(with frame: ARFrame) {
        guard shouldProcessFrame(frame) else { return }
        lastProcessedFrame = frame
        
        var croppedImage : UIImage?
        
        DispatchQueue.main.async {
            let image = self.sceneView.snapshot()
            let frameSize = self.frameRect.frame
            let scale = UIScreen.main.scale
            
            croppedImage = UIImage(cgImage: (image.cgImage?.cropping(to: CGRect(x: image.size.width / 2 - frameSize.width / 2 * scale, y: image.size.height / 2 -   frameSize.height / 2 * scale, width: frameSize.width * scale, height: frameSize.height * scale)))!).resizeTo(with: CGSize(width: 512, height: 512))
            
            if croppedImage != nil {
                self.startWork(image: UIImage(named: "wheeltest.png")!.cgImage!) //croppedImage!.cgImage!)
            }
        }
    }
    
    private func startWork(image: CGImage) {
        
        guard let context = CGContext(
            data: nil,
            width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            else { return }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let imageData = context.data else {
            return
        }
        
        let inputs = ModelInputs()
        var inputData = Data()
        
        do {
            for row in 0 ..< 512 {
                for col in 0 ..< 512 {
                    let offset = 4 * (col * context.width + row)
                    let red = imageData.load(fromByteOffset: offset + 1, as: UInt8.self)
                    let green = imageData.load(fromByteOffset: offset + 2, as: UInt8.self)
                    let blue = imageData.load(fromByteOffset: offset + 3, as: UInt8.self)
                    
                    var normalizedRed = (Float32(red) - 127.5) / 127.5
                    var normalizedGreen = (Float32(green) - 127.5) / 127.5
                    var normalizedBlue = (Float32(blue) - 127.5) / 127.5
                    
                    let elementSize = MemoryLayout.size(ofValue: normalizedRed)
                    var bytes = [UInt8](repeating: 0, count: elementSize)
                    memcpy(&bytes, &normalizedRed, elementSize)
                    inputData.append(&bytes, count: elementSize)
                    memcpy(&bytes, &normalizedGreen, elementSize)
                    inputData.append(&bytes, count: elementSize)
                    memcpy(&bytes, &normalizedBlue, elementSize)
                    inputData.append(&bytes, count: elementSize)
                }
            }
            try inputs.addInput(inputData)
        }
        catch let error {
            print("[SetupInput] Failed to add input: \(error)")
        }
        
        interpreter.run(inputs: inputs, options: ioOptions) { (outputs, error) in
            guard error == nil, let outputs = outputs else {
                print("[Interpreter] Interpreter error")
                if (error != nil) {
                    print(error!)
                }
                return
            }
            
            var numberArray : [NSArray]
            
            do {
                let result = try outputs.output(index: 0) as! [NSArray]
                
                numberArray = result.first as! [NSArray]
                
                var minX : Int = 512
                var maxX : Int = 0
                var minY : Int = 512
                var maxY : Int = 0
                
                for x in 0 ..< numberArray.count {
                    for y in 0 ..< numberArray[x].count {
                        let first = (numberArray[x][y] as! NSArray).firstObject as! Float32
                        let second = (numberArray[x][y] as! NSArray).lastObject as! Float32
                        
                        if (first > second) {
                            
                        }
                        else {
                            if minX > x {
                                minX = x
                            }
                            
                            if maxX < x {
                                maxX = x
                            }
                            
                            if minY > y {
                                minY = y
                            }
                            
                            if maxY < y {
                                maxY = y
                            }
                        }
                    }
                }
                
                if (minX != 512 && minY != 512 && maxX != 0 && maxY != 0) {
                    let frameSize = self.frameRect.frame
                    let offset = 512 / frameSize.width
                    
                    self.detectedMask.frame = CGRect(x: frameSize.minX + (CGFloat)(minX) / offset, y: frameSize.minY + (CGFloat)(minY) / offset, width: (CGFloat)(maxX - minX) / offset, height: (CGFloat)(maxY - minY) / offset)
                    
                    if self.rimAdded {
                        self.rimScene.isHidden = false
                        self.updateRimCoords()
                    }
                }
                else {
                    self.detectedMask.frame = CGRect.zero
                    self.frameCenter = CGPoint.zero
                    
                    if self.rimAdded {
                        self.rimScene.isHidden = true
                    }
                }
                
            } catch let error {
                print("[Interpreter] Failed to get result: \(error)")
            }
        }
    }
    
    func updateRimCoords() {
        frameCenter = CGPoint(x: detectedMask.frame.minX + detectedMask.frame.width / 2, y: detectedMask.frame.minY + detectedMask.frame.height / 2)
        
        let hitTestCenter = sceneView.hitTest(CGPoint(x: frameCenter.x, y: frameCenter.y), types: .existingPlane)
        let hitTestRight = sceneView.hitTest(CGPoint(x: detectedMask.frame.maxX, y: detectedMask.frame.midY), types: .existingPlane)
        
        var centerCoord: SCNVector3?
        var rightCoord: SCNVector3?
        
        if let hitTest = hitTestCenter.first {
            centerCoord = SCNVector3(hitTest.worldTransform.columns.3.x, hitTest.worldTransform.columns.3.y, rimScene.position.z)
        }
        
        if let hitTest = hitTestRight.first {
            rightCoord = SCNVector3(hitTest.worldTransform.columns.3.x, hitTest.worldTransform.columns.3.y, rimScene.position.z)
        }
        
        if centerCoord != nil && rightCoord != nil {
            rimScene.position = centerCoord!
            
            let distance = rightCoord! - centerCoord!
            let radius = distance.length()
            
            rimScene.scale = SCNVector3(x: radius * 2, y: radius * 2, z: radius * 2)
        }
    }
    
    private func loadModel() -> Bool {
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: modelType)
            else {
                // Invalid model path
                print("[LoadModel] Invalid model path")
                return false
        }
        model = LocalModel(
            name: modelName,
            path: modelPath
        )
        let registrationSuccessful = ModelManager.modelManager().register(model)
        if (!registrationSuccessful) {
            print("[LoadModel] Registration failed")
            return false
        }
        
        return true
    }
    
    private func buildInterpreter() {
        let options = ModelOptions(remoteModelName: nil, localModelName: modelName)
        let _interpreter = ModelInterpreter.modelInterpreter(options: options)
        let _ioOptions = ModelInputOutputOptions()
        do {
            try _ioOptions.setInputFormat(index: 0, type: .float32, dimensions: [1, 512, 512, 3])
            try _ioOptions.setOutputFormat(index: 0, type: .float32, dimensions: [1, 512, 512, 2])
        } catch let error as NSError {
            print("[BuildInterpreter] Error setting up model io: \(error)")
        }
        // initialize members
        interpreter = _interpreter
        ioOptions = _ioOptions
    }
    
    private func shouldProcessFrame(_ frame: ARFrame) -> Bool {
        guard let lastProcessedFrame = lastProcessedFrame else {
            // Always process the first frame
            return true
        }
        return frame.timestamp - lastProcessedFrame.timestamp >= 0.9 // setup fps (ms)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
    }
}
