//
//  ViewController.swift
//  MNEWA
//
//  Created by Jaydeep on 24/10/17.
//  Copyright © 2017 Jaydeep. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var sceneView: ARSCNView!
    var player: AVAudioPlayer?
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var lastSpawn = CFAbsoluteTimeGetCurrent()
    var phoneNode: SCNNode!
    //var arrowNode: SCNNode!
    var textNode: SCNNode!
    @IBOutlet weak var timerLabel: UILabel!
    var boxNode: SCNNode!
    @IBOutlet weak var scoreLabel: UILabel!
    var score = 0
    @IBOutlet weak var playAgainButton: UIButton!
    
    //variable
    var dragOnInfinitePlanesEnabled = false
    var screenCenter: CGPoint?
    let session = ARSession()
    var sessionConfig: ARConfiguration = ARWorldTrackingConfiguration()
    
    var secondTimer: Timer?
    var mainMessageTimer: Timer?
    var second = 20
    
    // MARK: - Focus Square
    var focusSquare: FocusSquare?
    
    func setupFocusSquare() {
        focusSquare?.isHidden = true
        focusSquare?.removeFromParentNode()
        focusSquare = FocusSquare()
        sceneView.scene.rootNode.addChildNode(focusSquare!)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        messageLabel.layer.cornerRadius = 8
        messageLabel.layer.masksToBounds = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTapScreen(_:)))
        self.sceneView.addGestureRecognizer(tapGesture)
        showScore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let worldSessionConfig = sessionConfig as? ARWorldTrackingConfiguration {
            worldSessionConfig.planeDetection = .horizontal
            session.run(worldSessionConfig)
            self.setupFocusSquare()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let pointer = getPointerPosition()
        
        self.present(self.SimpleAlertview(title: "", body: "Find the cubes to collect MNE. Cubes will spawn around your location, make sure you get them before the time runs out!", completion: {
            self.spawnShape(point: pointer.pos,size: 0.25)
            self.drawArrow()
            self.second = 20
            self.secondTimerMethod()
            
            self.showMessage(text: "Move around your device to Cube", second: 5)
        }), animated: true, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        session.pause()
    }
    
    @IBAction func didTapOnHintButton(_ sender: Any) {
        //self.arrowNode.position = self.boxNode.position
        //self.arrowNode.position.x = self.boxNode.position.x - 0.2
    }
    
    
    @IBAction func didTapOnPlayAgain(_ sender: Any) {
        self.score = 0
        self.showScore()
        playAgainButton.alpha = 1
        UIView.animate(withDuration: 0.8, animations: {
            self.playAgainButton.alpha = 0
        }) { (complete) in
            self.playAgainButton.isHidden = true
        }
        let pointer = getPointerPosition()
        self.spawnShape(point: pointer.pos,size: 0.25)
        self.drawArrow()
        self.second = 20
        self.secondTimerMethod()
        self.showMessage(text: "Move around your device to Cube", second: 5)
    }
    
    func secondTimerMethod() {
        if secondTimer != nil {
            secondTimer?.invalidate()
            secondTimer = nil
        }
        secondTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.second = self.second - 1
            self.timerLabel.text = "\(self.second)"
            if self.second == 0 {
                if self.secondTimer != nil {
                    self.secondTimer?.invalidate()
                    self.secondTimer = nil
                    self.present(self.SimpleAlertview(title: "Game Over", body: "MNE Collected: \(self.score) MNE", completion: {
                        self.textNode.removeFromParentNode()
                        self.boxNode.removeFromParentNode()
                        self.playAgainButton.isHidden = false
                        self.playAgainButton.alpha = 0
                        UIView.animate(withDuration: 0.8, animations: {
                            self.playAgainButton.alpha = 1
                        }) { (complete) in
                            
                        }
                    }), animated: true, completion: nil)
                }
            }
        })
    }
    
    func showMessage(text: String, second: Int) {
        if mainMessageTimer != nil {
            mainMessageTimer?.invalidate()
            mainMessageTimer = nil
        }
        messageLabel.alpha = 0
        messageLabel.isHidden = false
        messageLabel.text = text
        UIView.animate(withDuration: 0.4, animations: {
            self.messageLabel.alpha = 1
        }) { (timer) in}
        mainMessageTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(second), repeats: false, block: { (timer) in
            UIView.animate(withDuration: 0.4, animations: {
                self.messageLabel.alpha = 0
            }, completion: { (timer) in
                self.messageLabel.isHidden = true
            })
        })
        
    }
    
    
    func showScore() {
        scoreLabel.text = "Score: \(score) MNE"
    }
    func setupPhoneNode() {
        let shape = SCNPhysicsShape(geometry: SCNBox(width: 0.0485, height: 0.1, length: 0.0049, chamferRadius: 0), options: nil)
        let cubeBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        cubeBody.restitution = 0
        
        let cubeGeometry = SCNBox(width: 0.04, height: 0.1, length: 0.01, chamferRadius: 0)
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIColor.clear
        boxMaterial.locksAmbientWithDiffuse = true;
        cubeGeometry.materials = [boxMaterial]
        phoneNode = SCNNode(geometry: cubeGeometry)
        
        //Move in front of screen
        phoneNode.position = SCNVector3Make(0, 0, -1)
        sceneView.scene.rootNode.addChildNode(phoneNode)
    }
    
    
    
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func setupScene() {
        sceneView.setUp(viewController: self, session: session)
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.center
        }
    }
    
    func spawnShape(point: SCNVector3, size: CGFloat) {
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        if  currentTime - lastSpawn > 0.0 {
            
            
            //Initialize cube shape and appearance
            let cubeGeometry = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
            let boxMaterial = SCNMaterial()
            boxMaterial.diffuse.contents = UIImage(named: "new")
            boxMaterial.locksAmbientWithDiffuse = true;
            cubeGeometry.materials = [boxMaterial]
            
            
            //Create Node and add to parent node
            boxNode = SCNNode(geometry: cubeGeometry)
            boxNode.name = "boxnode"
            boxNode.position = SCNVector3Make(Float(randomBetweenNumbers(firstNum: -2, secondNum: 2)), Float(randomBetweenNumbers(firstNum: -1, secondNum: 1)), Float(randomBetweenNumbers(firstNum: -3, secondNum: -0.5)))//getPositionRelativeToCameraView(distance: 1).position
            sceneView.scene.rootNode.addChildNode(boxNode)
            
            //Adding physics to shape, in this case, the cube will have the exact same shape as the node
            let shape = SCNPhysicsShape(geometry: SCNBox(width: size, height: size, length: size, chamferRadius: 0), options: nil)
            let cubeBody = SCNPhysicsBody(type: .dynamic, shape: shape)
            cubeBody.restitution = 0
            lastSpawn = currentTime //using this timer to throttle the amount of cubes created
        }
    }
    
    
    func drawArrow() {
        let indices: [Int32] = [3, 0, 1, 2]
        let vectorMiddle = SCNVector3()
        
        var vertice1 = vectorMiddle
        vertice1.x -= Float(0.5)
        var vertice2 = vectorMiddle
        vertice2.x += Float(0.5)
        var vertice3 = vectorMiddle
        vertice3.y += Float(0.5)
        let vertices = [vertice1, vertice2, vertice3]
        
        let indexData = Data(bytes: indices,
                             count: indices.count * MemoryLayout<Int32>.size)
        
        
        
        /*let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .polygon,
                                         primitiveCount: 1,
                                         bytesPerIndex: MemoryLayout<Int32>.size)*/
        let geometry = SCNShape(path:  UIBezierPath.arrow(from: CGPoint(x: 1, y: 0), to: CGPoint(x: 3, y: 0),
                                                       tailWidth: 0.3, headWidth: 0.8, headLength: 0.5), extrusionDepth: 0)
        geometry.firstMaterial?.diffuse.contents = UIColor.white
        geometry.firstMaterial?.lightingModel = .constant
        geometry.firstMaterial?.isDoubleSided = true
       
        
        let txtgeomentry = SCNText(string: "1 MNE", extrusionDepth: 0)
        txtgeomentry.font = UIFont.boldSystemFont(ofSize: 10)
        txtgeomentry.alignmentMode = kCAAlignmentCenter
        txtgeomentry.firstMaterial?.diffuse.contents = UIColor.black
        txtgeomentry.firstMaterial?.isDoubleSided = true
        textNode = SCNNode(geometry: txtgeomentry)
        textNode.name = "textnode"
    }
    
    @IBAction func didTapScreen(_ sender: UITapGestureRecognizer) {
        let p = sender.location(in: self.sceneView)
        let hitResults = self.sceneView.hitTest(p, options: [:])
        debugPrint(hitResults)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            let result = hitResults[0]
            if let name = result.node.name {
                if name == "boxnode" {
                    if let txtNode = self.sceneView.scene.rootNode.childNode(withName: "textnode", recursively: true) {
                        debugPrint("text node found")
                        
                    } else {
                         debugPrint("text node not found")
                        textNode.scale = SCNVector3Make(0.008, 0.008, 0.008)
                        textNode.position = boxNode.position
                        center(node: textNode)
                        textNode.position.y = boxNode.position.y + 0.2
                        sceneView.scene.rootNode.addChildNode(textNode)
                        self.score = self.score + 1
                        self.showScore()
                        let _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (timer) in
                            self.textNode.removeFromParentNode()
                            self.boxNode.removeFromParentNode()
                            let pointer = self.getPointerPosition()
                        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                            self.playSound()
                            self.spawnShape(point: pointer.pos,size: 0.25)
                            self.drawArrow()
                            self.second = 20
                            self.secondTimerMethod()
                            self.showMessage(text: "Move around your device to find another Cube", second: 3)
                            
                        })
                    }
                    return
                }
            }
        }
    }
    
    func center(node: SCNNode) {
        let (min, max) = node.boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    // MARK: stuff
    
    func getPointerPosition() -> (pos : SCNVector3, valid: Bool, camPos : SCNVector4 ) {
        
        guard let pointOfView = sceneView.pointOfView else { return (SCNVector3Zero, false, SCNVector4Zero) }
        guard let currentFrame = sceneView.session.currentFrame else { return (SCNVector3Zero, false, SCNVector4Zero) }
        
        
        let mat = SCNMatrix4.init(currentFrame.camera.transform)
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        
        let currentPosition = pointOfView.position
        
        return (currentPosition, true, pointOfView.rotation)
        
    }
    
    func getUserVector() -> (SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            
            let vMult = 0.01
            let dir = SCNVector3(-Float(vMult) * mat.m31, -Float(vMult) * mat.m32, -Float(vMult) * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir)
        }
        return (SCNVector3(0, 0, -1))
    }
    
    
    func getPositionRelativeToCameraView(distance: Float) -> (position: SCNVector3, rotation: SCNVector4) {
        var x = Float()
        var y = Float()
        var z = Float()
        
        let cameraLocation = self.sceneView.pointOfView!.position //else { return (SCNVector3Zero) }
        let rotation = self.sceneView.pointOfView!.rotation //else { return (SCNVector3Zero) }
        let direction = calculateCameraDirection(cameraNode: rotation)
        
        x = cameraLocation.x + distance * direction.x
        y = cameraLocation.y + distance * direction.y
        z = cameraLocation.z + distance * direction.z
        
        let position = SCNVector3Make(x, y, z)
        return (position, rotation)
    }
    
    func calculateCameraDirection(cameraNode: SCNVector4) -> SCNVector3 {
        let x = -cameraNode.x
        let y = -cameraNode.y
        let z = -cameraNode.z
        let w = cameraNode.w
        let cameraRotationMatrix = GLKMatrix3Make(cos(w) + pow(x, 2) * (1 - cos(w)),
                                                  x * y * (1 - cos(w)) - z * sin(w),
                                                  x * z * (1 - cos(w)) + y*sin(w),
                                                  
                                                  y*x*(1-cos(w)) + z*sin(w),
                                                  cos(w) + pow(y, 2) * (1 - cos(w)),
                                                  y*z*(1-cos(w)) - x*sin(w),
                                                  
                                                  z*x*(1 - cos(w)) - y*sin(w),
                                                  z*y*(1 - cos(w)) + x*sin(w),
                                                  cos(w) + pow(z, 2) * ( 1 - cos(w)))
        
        let cameraDirection = GLKMatrix3MultiplyVector3(cameraRotationMatrix, GLKVector3Make(0.0, 0.0, -1.0))
        return SCNVector3FromGLKVector3(cameraDirection)
    }
    
    func updateResultLabel(_ value: Float) {
        let cm = value //* 100.0
        DispatchQueue.main.async {
            self.distanceLabel.text = String(format: "%.2f m", cm)
        }
    }
    
    func sceneSpacePosition(inFrontOf node: SCNNode, atDistance distance: Float) -> SCNVector3 {
        let localPosition = SCNVector3(x: 0, y: 0, z: -distance)
        let scenePosition = node.convertPosition(localPosition, to: nil)
        // to: nil is automatically scene space
        return scenePosition
    }
    
    func SimpleAlertview(title: String, body: String, completion:@escaping () -> Void) -> UIAlertController
    {
        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        
        // Create the actions
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {
            UIAlertAction in
            completion()
        }
        // Add the actions
        alertController.addAction(okAction)
        return alertController
    }
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?,
        planeAnchor: ARPlaneAnchor?,
        hitAPlane: Bool) {
            
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
            
            let highQualityfeatureHitTestResults =
                sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
            
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
    
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
       // arrowNode.position = (renderer.pointOfView?.position)!//getPositionRelativeToCameraView(distance: 0.3).position
       // arrowNode.position.y = arrowNode.position.y
       // arrowNode.position.z = arrowNode.position.z - 0.15
        
       /* DispatchQueue.main.async {
            self.updateFocusSquare()
        }*/
       
        if boxNode != nil {
            //self.arrowNode.position = self.getPositionRelativeToCameraView(distance: 1).position
            //arrowNode.pivot = self.boxNode.pivot
            /*self.arrowNode.eulerAngles.x = 0//self.boxNode.eulerAngles.x
            self.arrowNode.eulerAngles.y = self.boxNode.eulerAngles.y
            self.arrowNode.eulerAngles.z = 0//-self.boxNode.eulerAngles.z
            arrowNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: self.boxNode.rotation.w)//SCNVector4Make(0, 1, 0, M_PI/2);
            arrowNode.look(at: boxNode.position)
            updateResultLabel((renderer.pointOfView?.worldPosition.distance(vector: boxNode.worldPosition))!)*/
        }
    }
    
    func updatePhoneNode() {
        
        //Move in front of screen
        phoneNode.position = getPositionRelativeToCameraView(distance: 0.1).position
        
        phoneNode.rotation = getPositionRelativeToCameraView(distance: 0.1).rotation
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        
        /*if let planeNode = createPlaneNode(anchor: planeAnchor) {
            // ARKit owns the node corresponding to the anchor, so make the plane a child node.
            
            node.addChildNode(planeNode)
            planeArray.append(planeNode)
        }*/
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
       /* guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        // Remove existing plane nodes
        for plane in planeArray {
            plane.removeFromParentNode()
        }
        
        if let planeNode = createPlaneNode(anchor: planeAnchor) {
            
            node.addChildNode(planeNode)
            planeArray.append(planeNode)
        }*/
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        guard anchor is ARPlaneAnchor else { return }
        
        // Remove existing plane nodes
       /* for plane in planeArray {
            plane.removeFromParentNode()
        }*/
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        /*
         if let commandQueue = self.sceneView?.commandQueue {
         if let encoder = self.sceneView.currentRenderCommandEncoder {
         
         let projMat = float4x4.init((self.sceneView.pointOfView?.camera?.projectionTransform)!)
         let modelViewMat = float4x4.init((self.sceneView.pointOfView?.worldTransform)!).inverse
         
         //vertBrush.render(commandQueue, encoder, parentModelViewMatrix: modelViewMat, projectionMatrix: projMat)
         
         }
         }*/
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for examee, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

