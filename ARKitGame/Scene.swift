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
    
    let maxTargets = 20
    
    static let targetsRemainingLabel = SKLabelNode()
    var playerTimeLabel = SKLabelNode()
    var playerScoreLabel = SKLabelNode()
    
    //Time related properties
    var createTargetTimer: Timer?
    var gameTimer: Timer?
    
    let startTime = Date()

    var playerTime = 0 {

        didSet {
           playerTimeLabel.text = "Time: \(playerTime)"
        }
    }

    //Player related properties
    var playerScore = 0 {
        didSet {
            playerScoreLabel.text = "Score: \(playerScore)"
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
        playerScoreLabel.name = "score"
        
        //Create and start a timer that createsTeagrets every X seconds
        createTargetTimer = Timer.scheduledTimer(withTimeInterval: 3.3, repeats: true) { timer in
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
        
        //Register properties so Labels show in scene
        Scene.targetsVisibleCount = 0
        playerScore = 0
        playerTime = 0
        
        //Add Nodes to scene
        addChild(playerTimeLabel)
        addChild(Scene.targetsRemainingLabel)
        addChild(playerScoreLabel)

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
        
        //Exit method if node touched isn't a target (eg: A Label node)
        for node in targetHit {
            if node.name == nil {
                return
            
            } else {
//                print("Node Tapped: \(String(targetHit[0].name!))")
                print("Node Tapped: \(String(node.name!))")
            }
        }
        
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
            print("Visible: \(Scene.targetsVisibleCount)")
            
            //Update Player Score
            playerScore += 1
            
            //Call Game over handler when game ends
            if targetsCreatedCount >= maxTargets && Scene.targetsVisibleCount <= 0 {
                gameOver()
            }
        }
    }
    
    func createTarget() {
        
        //Ensure no more targets are created once max targets to cerate is reached
        if targetsCreatedCount == maxTargets {
            
            //Stop and destroy target Timer, exit method so no more targets are created
            createTargetTimer?.invalidate()
            createTargetTimer = nil
            
            return
        }
        
        //Update target count properties
        targetsCreatedCount += 1
        print("Created: \(targetsCreatedCount)")
        
        Scene.targetsVisibleCount += 1
        print("Visible: \(Scene.targetsVisibleCount)")
        
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
        
        let wait = SKAction.wait(forDuration: 12.4)
        let finishedWaiting = SKAction.run {
            
            DispatchQueue.main.async() {
                view.node(for: anchor)?.run(
                    SKAction.removeFromParent()
                )
            }
            
            Scene.targetsVisibleCount -= 1
            print("Visible: \(Scene.targetsVisibleCount)")
        }
        
        let sequence = SKAction.sequence([wait, finishedWaiting])
        node.run(sequence)
        return
        
//        DispatchQueue.main.async() {
//            view.node(for: anchor)?.run(
//                SKAction.sequence([
//                    SKAction.wait(forDuration: 10),
//                    SKAction.removeFromParent(),
//                    ])
//            )
//        }
    }
    
    //gameOver handler
    func gameOver() {
        
        //Invalidate Game timer
        gameTimer?.invalidate()
        gameTimer = nil
        
        //Remove Labels from view
        Scene.targetsRemainingLabel.removeFromParent()
        playerTimeLabel.removeFromParent()
        
        //Show Game Over image
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        addChild(gameOver)
        
        //Get and display Player Time taken
        let playerTimeTaken = Date().timeIntervalSince(startTime)
        let timeTakenLabel = SKLabelNode(text: "Time taken: \(Int(playerTimeTaken)) seconds. You hit \(playerScore) targets.")
        timeTakenLabel.fontSize = 26
        timeTakenLabel.fontName = "AmericanTypewriter"
        timeTakenLabel.color = .white
        timeTakenLabel.position = CGPoint(x: 0, y: -view!.frame.midY + 50)
        addChild(timeTakenLabel)
    }
}
