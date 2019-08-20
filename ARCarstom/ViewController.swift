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
    @IBOutlet var lockButton: UIButton!
    @IBOutlet var trashButton: UIButton!
    @IBOutlet var detectedMessage: UILabel!
    
    var sessionConfig = ARWorldTrackingConfiguration()
    var lifecycleWatchDog = WatchDog(named: "AI Testing")
    
    var detectionMode = DetectionMode.unlocked
    var rimAdded = false
    
    var model: LocalModel!
    var interpreter: ModelInterpreter!
    var ioOptions: ModelInputOutputOptions!
    
    var lastProcessedFrame: ARFrame?
    var detectedFrame: CGRect = CGRect.zero
    var screenCenter: CGPoint?
    
    var rimScene = RimScene()
    
    
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
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard detectionMode == .unlocked else { return }
        DispatchQueue.global().async() {
            self.updateCoreML(with: frame)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !rimAdded else { return }
        if touches.first != nil {
            sceneView.scene.rootNode.addChildNode(rimScene)
            
            rimAdded = true
            trashButton.isHidden = false
        }
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
        guard let imageData = context.data else { return }
        
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
        
        UIGraphicsEndImageContext();
        
        interpreter.run(inputs: inputs, options: ioOptions) { (outputs, error) in
            guard error == nil, let outputs = outputs else {
                print("[Interpreter] Interpreter error")
                if (error != nil) {
                    print(error!)
                }
                
                self.detectedMessage.isHidden = true
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
                
                UIGraphicsBeginImageContextWithOptions(CGSize(width: 512, height: 512), true, 1);
                let imageContext = UIGraphicsGetCurrentContext();
                
                for x in 0 ..< numberArray.count {
                    for y in 0 ..< numberArray[x].count {
                        let first = (numberArray[x][y] as! NSArray).firstObject as! NSNumber
                        let second = (numberArray[x][y] as! NSArray).lastObject as! NSNumber
                        
                        var pixelColor: UIColor = .black
                        if (first.floatValue > second.floatValue) {
                            pixelColor = UIColor.black
                        }
                        else {
                            pixelColor = UIColor.green
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
                        
                        imageContext?.setFillColor(pixelColor.cgColor)
                        imageContext?.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    }
                }
                
                let outputImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                if (minX != 512 && minY != 512 && maxX != 0 && maxY != 0) {
                    self.detectedMessage.isHidden = false
                    
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
                    self.detectedMessage.isHidden = true
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
        lifecycleWatchDog.logDuration(withDescription: "Interpreter ready!")
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
            
            croppedImage = UIImage(cgImage: (image.cgImage?.cropping(to: CGRect(x: image.size.width / 2 - frameSize.width / 2 * scale, y: image.size.height / 2 - frameSize.height / 2 * scale, width: frameSize.width * scale, height: frameSize.height * scale)))!).resizeTo(with: CGSize(width: 512, height: 512))
            
            if croppedImage != nil {
                self.startWork(image: UIImage(named: "wheeltest.png")!.cgImage!)//croppedImage!.cgImage!)//UIImage(named: "wheeltest.png")!.cgImage!)
            }
        }
    }
    
    func updateRimCoords() {
        guard detectionMode == .unlocked else { return }
        
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
            let radius = distance.length() * 2
            
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
    
    // MARK: Gestures & actions
    
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
            rimScene.switchColor(rimAction: .Next)
        }
        else if gesture.direction == .down {
            rimScene.switchColor(rimAction: .Previous)
        }
    }
    
    @IBAction func onLockClicked(_ sender: Any) {
        guard rimAdded else { return }
        
        switch detectionMode {
        case .locked:
            UIView.animate(withDuration: 0.2, animations: {
                self.frameRect.alpha = 0.7
                self.lockButton.alpha = 0.7
            }, completion: { finished in
                self.detectionMode = .unlocked
                self.detectedMask.isHidden = false
                self.lockButton.setImage(UIImage(named: "unlocked"), for: .normal)
            })
            break
        case .unlocked:
            UIView.animate(withDuration: 0.2, animations: {
                self.frameRect.alpha = 0
                self.lockButton.alpha = 0.3
            }, completion: { finished in
                self.detectionMode = .locked
                self.detectedMask.isHidden = true
                self.lockButton.setImage(UIImage(named: "locked"), for: .normal)
            })
            break
        }
    }
    
    @IBAction func onTrashClicked(_ sender: Any) {
        guard rimAdded else { return }
        
        rimScene.removeFromParentNode()
        
        rimAdded = false
        trashButton.isHidden = true
        detectionMode = .unlocked
        frameRect.alpha = 0.7
        lockButton.alpha = 0.7
        lockButton.setImage(UIImage(named: "unlocked"), for: .normal)
        detectedMask.isHidden = false
    }
    
    // MARK: Empty session functions
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
    }
}
