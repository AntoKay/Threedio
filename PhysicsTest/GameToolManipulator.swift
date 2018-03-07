//
//  GameToolManipulator.swift
//  PhysicsTest
//
//  Created by Raffaele Tontaro on 07/03/18.
//  Copyright © 2018 Raffaele Tontaro. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class GameToolManipulator: GameTool {
    var sceneView: ARSCNView!
    var heldObject: SCNNode?
    let throwingStrength: Float = 2
    let holdingDistance: Float = 0.8
    let origin: SCNNode!
    
    required init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        origin = sceneView.scene.rootNode.childNode(withName: "Origin", recursively: true)
    }
    
    func onUpdate(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {}
    
    func onTap() {
        if heldObject == nil {
            manipulate()
        } else {
            throwObject()
        }
    }
    
    func onEnter() {}
    
    func onExit() {
        dropObject()
    }
    
    func action(type: String, value: Any? = nil) {
        if type == "throwObject" {
            throwObject()
        } else if type == "dropObject" {
            dropObject()
        }
    }
}

private extension GameToolManipulator {
    func manipulate() {
        if let hit = raycast(filter: .dynamic) {
            dropObject()
            heldObject = hit.node
            sceneView.pointOfView!.addChildNode(hit.node)
            hit.node.position = SCNVector3(0, 0, -holdingDistance)
            hit.node.physicsBody?.clearAllForces()
            hit.node.physicsBody?.velocity = SCNVector3(0,0,0)
            hit.node.physicsBody?.isAffectedByGravity = false
        }
    }
    
    func dropObject() {
        if let object = heldObject {
            let newTransform = sceneView.pointOfView!.convertTransform(object.transform, to: origin)
            object.transform = newTransform
            origin.addChildNode(object)
            object.physicsBody?.isAffectedByGravity = true
            heldObject = nil
        }
    }
    
    func throwObject() {
        if let object = heldObject {
            let newTransform = sceneView.pointOfView!.convertTransform(object.transform, to: origin)
            let localForce = SCNVector3(0,0, -throwingStrength)
            let globalForce = sceneView.pointOfView!.convertVector(localForce, to: origin)
            origin.addChildNode(object)
            object.transform = newTransform
            object.physicsBody?.applyForce(globalForce, asImpulse: true)
            object.physicsBody?.isAffectedByGravity = true
            heldObject = nil
        }
    }
    
    //MARK: - UTILITY
    func raycast(filter mask: GamePieceSetting?) -> SCNHitTestResult? {
        let point = CGPoint(x: sceneView.frame.width / 2, y: sceneView.frame.height / 2)
        var options : [SCNHitTestOption: Any] = [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.firstFoundOnly : true]
        if mask != nil {
            options[SCNHitTestOption.categoryBitMask] = mask!.rawValue
        }
        let hits = sceneView.hitTest(point, options: options)
        if !hits.isEmpty {
            return hits.first
        }
        return nil
    }
    
}
