import UIKit
import SceneKit
import ARKit
import PortalMask
import PureLayout

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
    var shopPanel = ShopView()
    
    var moveBtnX: NSLayoutConstraint?
    var scaleBtnX: NSLayoutConstraint?
    var brushBtnX: NSLayoutConstraint?
    var movePanelX: NSLayoutConstraint?
    var resizePanelX: NSLayoutConstraint?
    var palettePanelX: NSLayoutConstraint?
    
    var navigationPanel = UIView()
    var settingsButtonView = UIView()
    var actionButtonView = UIView()
    var cameraMaskView = UIView()
    var palettePanel = UIView()
    
    var shotGesture : UITapGestureRecognizer?
    var actionGesture : UITapGestureRecognizer?
    var cameraMaskGesture : UITapGestureRecognizer?
    var moveGesture: UITapGestureRecognizer?
    var scaleGesture: UITapGestureRecognizer?
    var brushGesture: UITapGestureRecognizer?
    var shopGesture: UITapGestureRecognizer?
    
    var leftGesture: CustomGestureRecognizer?
    var rightGesture: CustomGestureRecognizer?
    var upGesture: CustomGestureRecognizer?
    var downGesture: CustomGestureRecognizer?
    var increaseGesture: UITapGestureRecognizer?
    var reduceGesture: UITapGestureRecognizer?
    
    var dynamicPanelSize : [NSLayoutConstraint]?
    var cameraMaskSize : [NSLayoutConstraint]?
    
    let wheelDiameter : CGFloat = 0.01
    let portalDiameter : CGFloat = 0.245
    
    var firstPlaneNode = SCNNode()
    var firstContainer = SCNNode()
    var firstRimNodes = [SCNNode]()
    var secondPlaneNode = SCNNode()
    var secondContainer = SCNNode()
    var secondRimNodes = [SCNNode]()
    var rimMaterial = SCNMaterial()
    
    var selectedNode : SCNNode?
    var maskNode : SCNNode?
    
    var firstWheelAdded : Bool = false
    var secondWheelAdded : Bool = false
    var isPanelHidden : Bool = true
    var isCameraMode : Bool = false
    var isResizeMode : Bool = false
    var isTranslateMode : Bool = false
    var isPaletteMode : Bool = false
    
    var currentRimId : Int = 0
    
    
    // MARK: Base methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        setupView()
        setupSettingsPanel()
        setupMaterials()
        
        shotGesture = UITapGestureRecognizer(target: self, action: #selector(onShotAction))
        actionGesture = UITapGestureRecognizer(target: self, action: #selector(onActionBtnClicked))
        cameraMaskGesture = UITapGestureRecognizer(target: self, action: #selector(onCameraMaskPressed))
        shopGesture = UITapGestureRecognizer(target: self, action: #selector(onShopAction))
        
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
        shopButton.addGestureRecognizer(shopGesture!)
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
        shopButton.removeGestureRecognizer(shopGesture!)
        actionButtonView.removeGestureRecognizer(actionGesture!)
        cameraMaskView.removeGestureRecognizer(cameraMaskGesture!)
        moveButton.removeGestureRecognizer(moveGesture!)
        scaleButton.removeGestureRecognizer(scaleGesture!)
        brushButton.removeGestureRecognizer(brushGesture!)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        if !firstWheelAdded {
            firstPlaneNode = createPlane(withPlaneAnchor: planeAnchor)
            node.addChildNode(firstPlaneNode)
        } else if firstWheelAdded && !secondWheelAdded {
            secondPlaneNode = createPlane(withPlaneAnchor: planeAnchor)
            node.addChildNode(secondPlaneNode)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !firstWheelAdded || !secondWheelAdded else { return }

        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)

            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if results.first != nil {
                if !firstWheelAdded {
                    createRimSceleton(rimsCollection: &firstRimNodes, container: firstContainer)
                    
                    firstPlaneNode.addChildNode(firstContainer)
                    firstWheelAdded = true
                    
                    UIView.animate(withDuration: 1, animations: {
                        self.firstPlaneNode.geometry?.firstMaterial?.transparency = 0
                    })
                } else
                {
                    if !secondWheelAdded {
                        createRimSceleton(rimsCollection: &secondRimNodes, container: secondContainer)
                        
                        secondPlaneNode.addChildNode(secondContainer)
                        secondWheelAdded = true
                        
                        UIView.animate(withDuration: 1, animations: {
                            self.secondPlaneNode.geometry?.firstMaterial?.transparency = 0
                        })
                        
                        self.sceneView.debugOptions = []
                    }
                }
            }
        }
    }
    
    func createRimSceleton(rimsCollection : inout [SCNNode], container : SCNNode) {
        let portal = PortalMask(radius: portalDiameter)
        container.addChildNode(portal)
        
        let rimScene = SCNScene(named: "scnassets/rim_1.scn")!
        if let rimChildNode = rimScene.rootNode.childNode(withName: "rim_1", recursively: true) {
            let rimNode1 = createRim(fromNode: rimChildNode)
            rimsCollection.append(rimNode1)
            container.addChildNode(rimNode1)
        }
        
        let rimScene2 = SCNScene(named: "scnassets/rim_2.scn")!
        if let rimChildNode = rimScene2.rootNode.childNode(withName: "rim_2", recursively: true) {
            let rimNode2 = createRim(fromNode: rimChildNode)
            rimsCollection.append(rimNode2)
            container.addChildNode(rimNode2)
        }
        
        let rimScene3 = SCNScene(named: "scnassets/rim_3.scn")!
        if let rimChildNode = rimScene3.rootNode.childNode(withName: "rim_3", recursively: true) {
            let rimNode3 = createRim(fromNode: rimChildNode)
            rimsCollection.append(rimNode3)
            container.addChildNode(rimNode3)
        }
        
        let brakeScene = SCNScene(named: "scnassets/brake.scn")!
        if let brakeChildNode = brakeScene.rootNode.childNode(withName: "brake", recursively: true) {
            var brakeNode = SCNNode()
            brakeNode = brakeChildNode
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
            
            container.addChildNode(brakeNode)
        }
        
        maskNode = createMask()
        container.addChildNode(maskNode!)
        maskNode!.position = SCNVector3(0, 0, -0.5)
        
        for node in rimsCollection {
            node.isHidden = true
        }
        rimsCollection.first?.isHidden = false
    }
    
    func createRim(fromNode node : SCNNode) -> SCNNode {
        var rim = SCNNode()
        rim = node
        rim.position = SCNVector3(0, 0, -0.115)
        rim.scale = SCNVector3(wheelDiameter, wheelDiameter, wheelDiameter)
        rim.eulerAngles.y = -.pi / 2
        rim.geometry?.materials = [rimMaterial]
        
        return rim
    }

    func createMaterial(light isLight: Bool) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.metalness.contents = 1.0
        material.roughness.contents = 0
        material.diffuse.contents = isLight ? UIColor.white : UIColor.darkGray
        
        return material
    }
    
    // MARK: Setup
    
    func setupView() {
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
        
        shopPanel.isUserInteractionEnabled = false
        shopPanel.controller = self
        view.addSubview(shopPanel)

        actionButtonImage.autoCenterInSuperview()
        actionButtonImage.autoSetDimensions(to: CGSize(width: 24, height: 24))
        
        actionButtonView.autoPinEdge(ALEdge.bottom, to: ALEdge.top, of: panelView, withOffset: 39)
        actionButtonView.autoSetDimensions(to: CGSize(width: 64, height: 64))
        actionButtonView.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        
        cameraMaskView.autoCenterInSuperview()
        cameraMaskSize = cameraMaskView.autoSetDimensions(to: CGSize(width: 0, height: 0))
        
        bottomPanelConstraint.constant = UIDevice.isXDevice() ? 0 : 20
        
        shopPanel.autoPinEdgesToSuperviewEdges()
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
        setupPalette()
        
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
        
        palettePanel.autoSetDimension(.width, toSize: 40)
        palettePanelX = palettePanel.autoPinEdge(.left, to: .right, of: view)
        palettePanel.autoPinEdge(.bottom, to: .top, of: brushButton, withOffset: -15)
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
        increaseGesture = UITapGestureRecognizer(target: self, action: #selector(increaseAction))
        reduceGesture = UITapGestureRecognizer(target: self, action: #selector(reduceAction))
        
        resizePanel.backgroundColor = .white
        resizePanel.layer.cornerRadius = 20
        resizePanel.isUserInteractionEnabled = true
        resizePanel.clipsToBounds = true
        view.addSubview(resizePanel)
        
        let plusImg = UIImageView(image: UIImage(named: "ic_plus"))
        plusImg.contentMode = .scaleAspectFit
        
        let plusZone = UIView()
        plusZone.isUserInteractionEnabled = true
        resizePanel.addSubview(plusZone)
        plusZone.addSubview(plusImg)
        plusZone.addGestureRecognizer(increaseGesture!)
        
        plusImg.autoSetDimensions(to: CGSize(width: 15, height: 15))
        plusImg.autoCenterInSuperview()
        plusZone.autoPinEdge(toSuperviewEdge: .top)
        plusZone.autoAlignAxis(toSuperviewAxis: .vertical)
        plusZone.autoSetDimensions(to: CGSize(width: 40, height: 95 / 2))
        
        let minusImg = UIImageView(image: UIImage(named: "ic_minus"))
        minusImg.contentMode = .scaleAspectFit
        
        let minusZone = UIView()
        minusZone.isUserInteractionEnabled = true
        resizePanel.addSubview(minusZone)
        minusZone.addSubview(minusImg)
        minusZone.addGestureRecognizer(reduceGesture!)
        
        minusImg.autoSetDimensions(to: CGSize(width: 15, height: 15))
        minusImg.autoCenterInSuperview()
        minusZone.autoPinEdge(toSuperviewEdge: .bottom)
        minusZone.autoAlignAxis(toSuperviewAxis: .vertical)
        minusZone.autoSetDimensions(to: CGSize(width: 40, height: 95 / 2))
    }
    
    func setupPalette() {
        let silverGesture = ColorGestureRecognizer(target: self, action: #selector(colorAction))
        let darkGesture = ColorGestureRecognizer(target: self, action: #selector(colorAction))
        let goldGesture = ColorGestureRecognizer(target: self, action: #selector(colorAction))
        
        palettePanel.backgroundColor = .clear
        palettePanel.layer.cornerRadius = 20
        palettePanel.isUserInteractionEnabled = true
        palettePanel.clipsToBounds = true
        view.addSubview(palettePanel)
        
        let silverColor = UIView()
        silverColor.layer.cornerRadius = 13
        silverColor.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        silverColor.layer.borderWidth = 2
        silverColor.backgroundColor = .lightGray
        palettePanel.addSubview(silverColor)
        silverColor.addGestureRecognizer(silverGesture)
        silverGesture.rimColor = .silver
        
        silverColor.autoAlignAxis(toSuperviewAxis: .vertical)
        silverColor.autoSetDimensions(to: CGSize(width: 24, height: 24))
        silverColor.autoPinEdge(toSuperviewEdge: .top, withInset: 15)
        
        let darkColor = UIView()
        darkColor.layer.cornerRadius = 13
        darkColor.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        darkColor.layer.borderWidth = 2
        darkColor.backgroundColor = .darkGray
        palettePanel.addSubview(darkColor)
        darkColor.addGestureRecognizer(darkGesture)
        darkGesture.rimColor = .dark
        
        darkColor.autoAlignAxis(toSuperviewAxis: .vertical)
        darkColor.autoSetDimensions(to: CGSize(width: 24, height: 24))
        darkColor.autoPinEdge(.top, to: .bottom, of: silverColor, withOffset: 10)
        
        let goldColor = UIView()
        goldColor.layer.cornerRadius = 13
        goldColor.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        goldColor.layer.borderWidth = 2
        goldColor.backgroundColor = UIColor(red: 191, green: 155, blue: 48)
        palettePanel.addSubview(goldColor)
        goldColor.addGestureRecognizer(goldGesture)
        goldGesture.rimColor = .gold
        
        goldColor.autoAlignAxis(toSuperviewAxis: .vertical)
        goldColor.autoSetDimensions(to: CGSize(width: 24, height: 24))
        goldColor.autoPinEdge(.top, to: .bottom, of: darkColor, withOffset: 10)
        goldColor.autoPinEdge(toSuperviewEdge: .bottom, withInset: 15)
    }
    
    func setupMaterials() {
        rimMaterial.lightingModel = .physicallyBased
        rimMaterial.metalness.contents = 1.0
        rimMaterial.roughness.contents = 0
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
    
    func createMask() -> SCNNode {
        let maskPlane = SCNPlane(width: CGFloat(1), height: CGFloat(1))
        let maskMaterial = SCNMaterial()
        maskMaterial.diffuse.contents = UIImage(named: "scnassets/mask.png")
        maskPlane.materials = [maskMaterial]
        
        let node = SCNNode()
        node.geometry = maskPlane
        
        return node
    }
    
    func switchRim(atId : Int) {
        firstRimNodes[currentRimId].isHidden = true
        firstRimNodes[atId].isHidden = false
        currentRimId = atId
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
    
    @objc func onShopAction(recognizer: UITapGestureRecognizer) {
        guard firstWheelAdded else { return }
        
        if isCameraMode {
            cameraCloseAnimation()
        }
        
        if !isPanelHidden {
            panelHidesAnimation()
        }
        
        shopPanel.isUserInteractionEnabled = true
        shopPanel.showPanel()
    }
    
    @objc func onCameraMaskPressed(recognizer: UITapGestureRecognizer) {
        cameraMaskView.isUserInteractionEnabled = false
        self.actionButtonView.isUserInteractionEnabled = false
        
        cameraCloseAnimation()
    }
    
    @objc func increaseAction(recognizer: UITapGestureRecognizer) {
        guard firstWheelAdded else { return }
        
        firstContainer.scale.x += 0.01
        firstContainer.scale.y += 0.01
        firstContainer.scale.z += 0.01
    }
    
    @objc func reduceAction(recognizer: UITapGestureRecognizer) {
        guard firstWheelAdded else { return }
        
        firstContainer.scale.x -= 0.01
        firstContainer.scale.y -= 0.01
        firstContainer.scale.z -= 0.01
    }
    
    @objc func moveAction(recognizer: CustomGestureRecognizer) {
        guard firstWheelAdded else { return }
        
        switch recognizer.direction! {
        case .left:
            firstContainer.position = SCNVector3(firstContainer.position.x - 0.005, firstContainer.position.y, firstContainer.position.z)
        case .right:
            firstContainer.position = SCNVector3(firstContainer.position.x + 0.005, firstContainer.position.y, firstContainer.position.z)
        case .up:
            firstContainer.position = SCNVector3(firstContainer.position.x, firstContainer.position.y + 0.005, firstContainer.position.z)
        case .down:
            firstContainer.position = SCNVector3(firstContainer.position.x, firstContainer.position.y - 0.005, firstContainer.position.z)
        }
    }
    
    @objc func colorAction(recognizer: ColorGestureRecognizer) {
        switch recognizer.rimColor! {
        case .silver:
            rimMaterial.diffuse.contents = UIColor.white
        case .dark:
            rimMaterial.diffuse.contents = UIColor.darkGray
        case .gold:
            rimMaterial.diffuse.contents = UIColor(red: 191, green: 155, blue: 48)
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
        
        if isPaletteMode {
            hidePalettePanel()
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
    
    func showPalettePanel() {
        isPaletteMode = true
        UIView.animate(withDuration: 0.2, animations: {
            self.palettePanelX?.constant = -70
            self.view.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.1, animations: {
                self.palettePanelX?.constant = -60
                self.view.layoutIfNeeded()
            })
        })
    }
    
    func hidePalettePanel() {
        isPaletteMode = false
        UIView.animate(withDuration: 0.2, animations: {
            self.palettePanelX?.constant = 0
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
            
            if isPaletteMode {
                hidePalettePanel()
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
            
            if isPaletteMode {
                hidePalettePanel()
            }
            
            showResizePanel()
        }
    }
    
    @objc func onBrushBtnAction(recognizer: UITapGestureRecognizer) {
        if isPaletteMode {
            hidePalettePanel()
        } else {
            if isTranslateMode {
                hideMovePanel()
            }
            
            if isResizeMode {
                hideResizePanel()
            }
            
            showPalettePanel()
        }
    }
}
