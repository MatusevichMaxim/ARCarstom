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
    
    var sessionConfig = ARWorldTrackingConfiguration()
    var lifecycleWatchDog = WatchDog(named: "AI Testing")
    
    var rimAdded = false
    
    var model: LocalModel!
    var interpreter: ModelInterpreter!
    var ioOptions: ModelInputOutputOptions!
    
    var lastProcessedFrame: ARFrame?
    var detectedFrame: CGRect = CGRect.zero
    var screenCenter: CGPoint?
    
    var rimScene = RimScene()
//    var planeNode: SCNNode?
    
    
    // MARK: initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupSwipes()
        
        if loadModel() {
            buildInterpreter()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        restartPlaneDetection()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    func setupScene() {
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = false
        sceneView.autoenablesDefaultLighting = true
        //sceneView.showsStatistics = true
        
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
    }
    
    func restartPlaneDetection() {
        
        // configure session
        sessionConfig.planeDetection = .vertical
        sceneView.session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.global().async() {
            self.updateCoreML(with: frame)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        
//        planeNode?.position = SCNVector3(anchorPlane.center.x, anchorPlane.center.y, anchorPlane.center.z)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first != nil {
            
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.0)
//            planeNode?.geometry?.materials = [gridMaterial]
            sceneView.scene.rootNode.addChildNode(rimScene)
            
            rimAdded = true
        }
    }
    
    // MARK: - Planes
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        
        let pos = SCNVector3.positionFromTransform(anchor.transform)
        print("NEW SURFACE DETECTED AT \(pos.friendlyString())")
        
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
        plane.materials = [gridMaterial]

//        planeNode = SCNNode()
//        planeNode?.name = planeName
//        planeNode?.position = SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z)
//        planeNode?.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
//        planeNode?.geometry = plane
//        node.addChildNode(planeNode!)
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
//        planeNode?.position = SCNVector3Make(anchor.center.x, anchor.center.y, anchor.center.z)
    }
    
    func removeNode(named: String) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == named {
                node.removeFromParentNode()
            }
        }
    }
    
    // MARK: Image processing
    
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
                    
                    self.detectedFrame = CGRect(x: frameSize.minX + (CGFloat)(minX) / offset, y: frameSize.minY + (CGFloat)(minY) / offset, width: (CGFloat)(maxX - minX) / offset, height: (CGFloat)(maxY - minY) / offset)
                    
                    self.detectedMask.frame = self.detectedFrame
                    
                    if self.rimAdded {
                        self.rimScene.isHidden = false
                        self.updateRimCoords()
                    }
                }
                else {
                    self.detectedMask.frame = CGRect.zero
                    
                    if self.rimAdded {
                        self.rimScene.isHidden = true
                    }
                }
                
            } catch let error {
                print("[Interpreter] Failed to get result: \(error)")
            }
        }
    }
    
    // MARK: Model initialization
    
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
    
    // MARK: Updating coords
    
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
    
    func updateRimCoords() {
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
        let hitTestCenter = sceneView.hitTest(CGPoint(x: detectedFrame.midX, y: detectedFrame.midY), types: .featurePoint)
        let hitTestRight = sceneView.hitTest(CGPoint(x: detectedFrame.maxX, y: detectedFrame.midY), types: .featurePoint)
        
        var centerCoord: SCNVector3?
        var rightCoord: SCNVector3?
        
        if let hitResult = hitTestCenter.first {
            centerCoord = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        }
        
        if let hitResult = hitTestRight.first {
            rightCoord = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        }
        
        if centerCoord != nil && rightCoord != nil {
            rimScene.position = centerCoord!
            
            let distance = rightCoord! - centerCoord!
            let radius = distance.length()
            
            rimScene.scale = SCNVector3(x: radius * 2, y: radius * 2, z: radius * 2)
        }
    }
    
    private func shouldProcessFrame(_ frame: ARFrame) -> Bool {
        guard let lastProcessedFrame = lastProcessedFrame else {
            // Always process the first frame
            return true
        }
        return frame.timestamp - lastProcessedFrame.timestamp >= 0.9 // setup fps (ms)
    }
    
    // MARK: Gestures
    
    func setupSwipes() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        guard rimAdded else { return }
        
        if gesture.direction == .right {
            rimScene.switchRim(rimAction: .Next)
        }
        else if gesture.direction == .left {
            rimScene.switchRim(rimAction: .Previous)
        }
        else if gesture.direction == .up {
            print("Swipe Up")
        }
        else if gesture.direction == .down {
            print("Swipe Down")
        }
    }
    
    // MARK: Convertion
    
    var dragOnInfinitePlanesEnabled = false
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
    // MARK: Empty session functions
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
    }
}
