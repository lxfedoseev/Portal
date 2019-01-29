/**
 * Copyright (c) 2018 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import ARKit

class PortalViewController: UIViewController {

  @IBOutlet var sceneView: ARSCNView?
  @IBOutlet weak var messageLabel: UILabel?
  @IBOutlet weak var sessionStateLabel: UILabel?
  
    @IBOutlet weak var crosshair: UIView!
  var portalNode: SCNNode? = nil
  var isPortalPlaced = false
  
    var debugPlanes: [SCNNode] = []
  var viewCenter: CGPoint {
    let viewBounds = view.bounds
    return CGPoint(x: viewBounds.width / 2.0, y: viewBounds.height / 2.0)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    resetLabels()
    runSession()
  }

  func makePortal() -> SCNNode {
    // 1
    let portal = SCNNode()
    // 2
    let box = SCNBox(width: 1.0,
                     height: 1.0,
                     length: 1.0,
                     chamferRadius: 0)
    let boxNode = SCNNode(geometry: box)
    // 3
    portal.addChildNode(boxNode)
    return portal
  }
  
  // 1
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    // 2
    if let hit = sceneView?.hitTest(viewCenter, types:
      [.existingPlaneUsingExtent]).first {
      // 3
      sceneView?.session.add(anchor: ARAnchor.init(transform:
        hit.worldTransform))
    } }
  
  func runSession() {
    let configuration = ARWorldTrackingConfiguration.init()
    configuration.planeDetection = .horizontal
    configuration.isLightEstimationEnabled = true

    sceneView?.session.run(configuration,
                           options: [.resetTracking, .removeExistingAnchors])

    #if DEBUG
      sceneView?.debugOptions = [SCNDebugOptions.showFeaturePoints]
    #endif

    sceneView?.delegate = self
  }
  
  func resetLabels() {
    messageLabel?.alpha = 1.0
    messageLabel?.text = "Move the phone around and allow the app to find a plane. You will see a yellow horizontal plane."
    sessionStateLabel?.alpha = 0.0
    sessionStateLabel?.text = ""
  }
  
  // 1
  func showMessage(_ message: String, label: UILabel, seconds: Double) {
    label.text = message
    label.alpha = 1
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
      if label.text == message {
        label.text = ""
        label.alpha = 0
      }
    } }
  
  // 2
  func removeAllNodes() {
    // 1
    removeDebugPlanes()
    // 2
    self.portalNode?.removeFromParentNode()
    // 3
    self.isPortalPlaced = false
  }
  
  // 3
  func removeDebugPlanes() {
    for debugPlaneNode in self.debugPlanes {
      debugPlaneNode.removeFromParentNode()
    }
    self.debugPlanes = []
  }
  
}

extension PortalViewController: ARSCNViewDelegate {
  
  // 1
  func session(_ session: ARSession, didFailWithError error: Error) {
    // 2
    guard let label = self.sessionStateLabel else { return }
    showMessage(error.localizedDescription, label: label, seconds: 3)
  }
  // 3
  func sessionWasInterrupted(_ session: ARSession) {
    guard let label = self.sessionStateLabel else { return }
    showMessage("Session interrupted", label: label, seconds: 3)
  }
  // 4
  func sessionInterruptionEnded(_ session: ARSession) {
    // 5
    guard let label = self.sessionStateLabel else { return }
    showMessage("Session resumed", label: label, seconds: 3)
    // 6
    DispatchQueue.main.async {
      self.removeAllNodes()
      self.resetLabels()
    }
    // 7
    runSession()
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for
    anchor: ARAnchor) {
    DispatchQueue.main.async {
      // 1
      if let planeAnchor = anchor as? ARPlaneAnchor,
        !self.isPortalPlaced {
        #if DEBUG
        let debugPlaneNode = createPlaneNode(
          center: planeAnchor.center,
          extent: planeAnchor.extent)
        node.addChildNode(debugPlaneNode)
        self.debugPlanes.append(debugPlaneNode)
        #endif
        self.messageLabel?.alpha = 1.0
        self.messageLabel?.text = """
        Tap on the detected \
        horizontal plane to place the portal
        """
      }
      else if !self.isPortalPlaced {// 2
        // 3
        self.portalNode = self.makePortal()
        if let portal = self.portalNode {
          // 4
          node.addChildNode(portal)
          self.isPortalPlaced = true
          // 5
          self.removeDebugPlanes()
          self.sceneView?.debugOptions = []
          // 6
          DispatchQueue.main.async {
            self.messageLabel?.text = ""
            self.messageLabel?.alpha = 0
          }
        }
      } }
  }
 
  func renderer(_ renderer: SCNSceneRenderer,
                didUpdate node: SCNNode,
                for anchor: ARAnchor) {
    DispatchQueue.main.async {
      // 7
      if let planeAnchor = anchor as? ARPlaneAnchor,
        node.childNodes.count > 0,
        !self.isPortalPlaced {
        updatePlaneNode(node.childNodes[0],
                        center: planeAnchor.center,
                        extent: planeAnchor.extent)
      }
    }
  }
  
  // 1
  func renderer(_ renderer: SCNSceneRenderer,
                // 2
    updateAtTime time: TimeInterval) {
    DispatchQueue.main.async {
      // 3
      if let _ = self.sceneView?.hitTest(self.viewCenter,
                                         types: [.existingPlaneUsingExtent]).first {
        self.crosshair.backgroundColor = UIColor.green
      } else { // 4
        self.crosshair.backgroundColor = UIColor.lightGray
      }
    } }
  
  
}
