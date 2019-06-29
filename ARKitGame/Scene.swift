//
//  Scene.swift
//  ARKitGame
//
//  Created by Simon Italia on 6/17/19.
//  Copyright © 2019 Magical Tomato. All rights reserved.
//

import SpriteKit
import ARKit

class Scene: SKScene {
    
    let targetsRemainingLabel = SKLabelNode()
    
    //Time related properties
    var timer: Timer?
    let startTime = Date()
    
    //Track total targets created
    var targetsCreatedCount = 0
    
    //Track currently visible targets
    var targetsVisibleCount = 0 {
        
        didSet {
            targetsRemainingLabel.text = "Targets left: \(targetsVisibleCount)"
        }
    }
    
    override func didMove(to view: SKView) {
        // Setup your scene here
        
        //Set fixed screen position for targetsRemainingLabel
        targetsRemainingLabel.fontSize = 36
        targetsRemainingLabel.fontName = "AmericanTypewriter-Bold"
        targetsRemainingLabel.fontColor = .white
        targetsRemainingLabel.position = CGPoint(x: 0, y: 175)
            //view.frame.midY - 50
        addChild(targetsRemainingLabel)
        
        targetsVisibleCount = 0
        
        //Create and start timer
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.createTarget()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    
    //Method for tracking user screen taps
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //Detect user touch
        guard let touch = touches.first else { return }
        
        //Detect positon of touch
        let location = touch.location(in: self)
        
        //Detect if a target is at touched location
        let targetHit = nodes(at: location)
        
        //If a target is at touched location, perfrom remove of  target from scene with some animations
        if let sprite = targetHit.first {
            
            //Actions
            let scaleOut = SKAction.scale(to: 2, duration: 0.2)
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let group = SKAction.group([scaleOut, fadeOut])
            let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
            sprite.run(sequence)
            
            //Remove target from targets visible count
            targetsVisibleCount -= 1
            
            //Call Game over handler when game ends
            if targetsCreatedCount == 20 && targetsVisibleCount == 0 {
                gameOver()
                
            }
        }
        
        //Old Apple Template Code
//        guard let sceneView = self.view as? ARSKView else {
//            return
//        }
//
//        // Create anchor using the camera's current position
//        if let currentFrame = sceneView.session.currentFrame {
//
//            // Create a transform with a translation of 0.2 meters in front of the camera
//            var translation = matrix_identity_float4x4
//            translation.columns.3.z = -0.2
//            let transform = simd_mul(currentFrame.camera.transform, translation)
//
//            // Add a new anchor to the session
//            let anchor = ARAnchor(transform: transform)
//            sceneView.session.add(anchor: anchor)
//        }
    }
    
    func createTarget() {
        
        if targetsCreatedCount == 20 {
            
            //Stop and destroy Timer, exit method so no more targets are created
            timer?.invalidate()
            timer = nil
            return
        }
        
        //Update target count properties
        targetsCreatedCount += 1
        targetsVisibleCount += 1
        
        //Following code does all the calcualtion to randomly get positions to place targets in the scene, along x and y axis, and at specific depth from the screen
        
        //Safely get / find the scene view to draw the objects into
        guard let sceneView = self.view as? ARSKView else { return }

        //Create the random X rotation
        let xRotation = simd_float4x4(SCNMatrix4MakeRotation(Float.pi * 2 * Float.random(in: 0...1), 1,0,0))
        
        //Create a random Y rotation
        let yRotation = simd_float4x4(SCNMatrix4MakeRotation(Float.pi * 2 * Float.random(in: 0...1), 0, 1, 0))
        
        //Combine them together
        let rotation = simd_mul(xRotation, yRotation)
        
        //Move them 1.5 meters forward / deep into the screen
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1.5
        
        //Combine translation (screen depth) property with rotation property
        let transform = simd_mul(rotation, translation)
        
        //Creat an anchor at the finished position to pass to the scene to display the objet in the scene at
        let anchor = ARAnchor(transform: transform)
        sceneView.session.add(anchor: anchor)
    }
    
    //gameOver hanlder
    func gameOver() {
        
        //Remove Label from view
        targetsRemainingLabel.removeFromParent()
        
        //Show Game Over image
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        addChild(gameOver)
        
        //Get and display Player Time taken
        let playerTimeTaken = Date().timeIntervalSince(startTime)
        let timeTakenLabel = SKLabelNode(text: "Time taken: \(Int(playerTimeTaken)) seconds.")
        timeTakenLabel.fontSize = 36
        timeTakenLabel.fontName = "AmericanTypewriter"
        timeTakenLabel.color = .white
        timeTakenLabel.position = CGPoint(x: 0, y: -view!.frame.midY + 50)
        addChild(timeTakenLabel)
    }
}
