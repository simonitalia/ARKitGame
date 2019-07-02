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
    
    static let targetsRemainingLabel = SKLabelNode()
    var playerTimeLabel = SKLabelNode()
    var playerScoreLabel = SKLabelNode()
    
    //Time related properties
    var createTargetTimer: Timer?
    var gameTimer: Timer?
    let startTime = Date()
    
    //Player related properties
    var playerScore = 0 {
        
        didSet {
            playerScoreLabel.text = "Score: \(playerScore)"
        }
    }
    
    var playerTime = 0 {
        
        didSet {
            playerTimeLabel.text = "Time: \(playerTime)"
        }
    }

    //Track total targets created
    var targetsCreatedCount = 0
    
    //Track currently visible targets
    static var targetsVisibleCount = 0 {
        
        didSet {
            Scene.targetsRemainingLabel.text = "Targets left: \(Scene.targetsVisibleCount)"
        }
    }
    
    
    override func didMove(to view: SKView) {
        // Setup your scene here
        
        //Set fixed screen position for labels, and add to scene
        Scene.targetsRemainingLabel.fontSize = 36
        Scene.targetsRemainingLabel.fontName = "AmericanTypewriter-Bold"
        Scene.targetsRemainingLabel.fontColor = .white
        Scene.targetsRemainingLabel.position = CGPoint(x: -175, y: 175)
            //view.frame.midY - 50
        
        playerScoreLabel.fontSize = 36
        playerScoreLabel.fontName = "AmericanTypewriter-Bold"
        playerScoreLabel.fontColor = .white
        playerScoreLabel.position = CGPoint(x: 175, y: 175)

        //Register properties so Labels update upon changesupdate of
        Scene.targetsVisibleCount = 0
        playerScore = 0
        
        addChild(Scene.targetsRemainingLabel)
        addChild(playerScoreLabel)
        
        //Create and start a timer that createsTeagrets every 2 seconds
        createTargetTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.createTarget()
            
        }
        
        //Start and track Game Timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            timer in
            
            //Update Player time
            self.playerTime += 1
        }
        
        //Create Player time label, set position in scene and add to scene
        playerTimeLabel.fontSize = 26
        playerTimeLabel.fontName = "AmericanTypewriter-Bold"
        playerTimeLabel.fontColor = .white
        playerTimeLabel.position = CGPoint(x: 0, y: -190)
        addChild(playerTimeLabel)
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
            
            //Update Targest Visible
            Scene.targetsVisibleCount -= 1
            
            //Update Player Score
            playerScore += 1
            
            //Call Game over handler when game ends
            if targetsCreatedCount == 20 && Scene.targetsVisibleCount == 0 {
                gameOver()
            }
        }
    }
    
    func createTarget() {
        
        if targetsCreatedCount == 20 {
            
            //Stop and destroy Timer, exit method so no more targets are created
            createTargetTimer?.invalidate()
            createTargetTimer = nil
            return
        }
        
        //Update target count properties
        targetsCreatedCount += 1
        Scene.targetsVisibleCount += 1
        
        //Following code does all the calcualtion to randomly get positions to place targets in the scene, along x and y axis, and at specific depth from the screen
        
        //Safely get / find the scene view to draw the objects into
        guard let sceneView = self.view as? ARSKView else { return }
        
//       Scene.sceneView = sceneView

        //Create the random X rotation
        let xRotation = simd_float4x4(SCNMatrix4MakeRotation(Float.pi * 2 * Float.random(in: 0...1), 1,0,0))
        
        //Create a random Y rotation
        let yRotation = simd_float4x4(SCNMatrix4MakeRotation(Float.pi * 2 * Float.random(in: 0...1), 0, 1, 0))
        
        //Combine them together
        let rotation = simd_mul(xRotation, yRotation)
        
        //Move them 1.5 meters forward / deep into the screen
        var translation = matrix_identity_float4x4
        
        //Generate random distance of target from screen
        let distance = Float.random(in: -1.5..<1)
        translation.columns.3.z = distance
        
        //Combine translation (screen depth) property with rotation property
        let transform = simd_mul(rotation, translation)
        
        //Create an anchor at the finished position to pass to the scene to display the objet in the scene at
        let anchor = ARAnchor(transform: transform)
        sceneView.session.add(anchor: anchor)
        
    }
    
    class func removeTarget(_ view: ARSKView, _ anchor: ARAnchor, _ node: SKNode) {
        
        DispatchQueue.main.async() {
            
            view.node(for: anchor)?.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: 10),
                    SKAction.removeFromParent()
                ])
            )
        }
    }
    
    //gameOver handler
    func gameOver() {
        
        //Remove Label from view
        Scene.targetsRemainingLabel.removeFromParent()
        
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
