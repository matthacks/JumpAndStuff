//
//  GameScene.swift
//  JumpAndStuff
//
//  Created by Matt Corrente on 3/1/18.
//  Copyright © 2018 Matt Corrente. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene {
    
    let player = SKSpriteNode(imageNamed: "player")
    let playerName = "player"
    let blockName = "block"
    let enemyName = "enemy"
    var motionManager = CMMotionManager()
    var destX: CGFloat = 0.0
    let swipeUp = UISwipeGestureRecognizer()
    let swipeDown = UISwipeGestureRecognizer()
    
    var worldNode: SKNode?
    var nodeTileHeight: CGFloat = 0.0
    var yOrgPosition: CGFloat?
    
    var cam: SKCameraNode = SKCameraNode()
    
    @objc func swipeUpPlayerJump(){
        if let player = childNode(withName: playerName) as? SKSpriteNode {
            player.physicsBody!.applyForce(CGVector(dx:0, dy:1000))
        }
    }
    
    @objc func swipeDownPlayerRushDown(){
        if let player = childNode(withName: playerName) as? SKSpriteNode {
            player.physicsBody!.applyForce(CGVector(dx:0, dy:-1000))
        }
    }
    
    override func didMove(to view: SKView) {
        
        let backgroundNode = SKSpriteNode(imageNamed: "background1")
        backgroundNode.size = CGSize(width: self.frame.width, height: self.frame.height)
        backgroundNode.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundNode.zPosition = -20
        self.addChild(backgroundNode)
        // Setup dynamic background tiles
        // Image of left and right node must be identical
        let backgroundImage1 = SKSpriteNode(imageNamed: "background1")
        let backgroundImage2 = SKSpriteNode(imageNamed: "background2")
        let backgroundImage3 = SKSpriteNode(imageNamed: "background3")
        let backgroundImage4 = SKSpriteNode(imageNamed: "background1")
        
        
        worldNode = SKNode()
        self.addChild(worldNode!)
        
        //used for animating
        nodeTileHeight = backgroundImage1.frame.size.height
        yOrgPosition = 0
        backgroundImage1.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundImage1.position = CGPoint(x: 0, y: 0)
        backgroundImage1.zPosition = -10
        backgroundImage2.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundImage2.position = CGPoint(x: 0, y: nodeTileHeight)
        backgroundImage2.zPosition = -10
        backgroundImage3.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundImage3.position = CGPoint(x:0, y: nodeTileHeight * 2)
        backgroundImage3.zPosition = -10
        backgroundImage4.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundImage4.position = CGPoint(x:0, y: nodeTileHeight * 3)
        backgroundImage4.zPosition = -10
        
        
        // Add tiles to worldNode. worldNode is used to realize the scrolling
        worldNode!.addChild(backgroundImage1)
        worldNode!.addChild(backgroundImage2)
        worldNode!.addChild(backgroundImage3)
        worldNode!.addChild(backgroundImage4)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        motionManager.startAccelerometerUpdates()
        
        player.position = CGPoint(x: size.width/2, y: size.height*0.1)
        player.name = playerName
        player.physicsBody = SKPhysicsBody(rectangleOf: player.frame.size)
        player.physicsBody!.isDynamic = true
        player.physicsBody!.mass = 0.02
        player.physicsBody!.allowsRotation = false
        
        swipeUp.addTarget(self, action: #selector(GameScene.swipeUpPlayerJump))
        swipeUp.direction = .up
        self.view!.addGestureRecognizer(swipeUp)
        
        swipeDown.addTarget(self, action: #selector(GameScene.swipeDownPlayerRushDown))
        swipeDown.direction = .down
        self.view!.addGestureRecognizer(swipeDown)
        
        addChild(player)
        
        cam.position = CGPoint(x: scene!.size.width / 2,
                               y: scene!.size.height / 2)
        addChild(cam)
        scene!.camera = cam
    
        // instantiates blocks
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addBlock),
                SKAction.wait(forDuration: 2.0)
                ])
        ))
        
        // instantiate enemies
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(dropEnemy),
                SKAction.wait(forDuration: 3.0)
                ])
        ))
    }
    
    func processUserMotion(forUpdate currentTime: CFTimeInterval) {
        if let player = childNode(withName: playerName) as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                if fabs(data.acceleration.x) > 0.2 {
                    player.physicsBody!.applyForce(CGVector(dx: 30 * CGFloat(data.acceleration.x), dy:0))
                }
            }
        }
    }
    
    override func update(_ currentTime: CFTimeInterval){
        super.update(currentTime)
        
        // enables tilt controls
        processUserMotion(forUpdate: currentTime)
        
        self.enumerateChildNodes(withName: "enemy") {
            node, stop in
            if (node is SKSpriteNode) {
                let sprite = node as! SKSpriteNode
                // Check if the node is not in the scene
                if (sprite.position.x < -sprite.size.width/2.0 || sprite.position.x > self.size.width+sprite.size.width/2.0
                    || sprite.position.y < sprite.size.height*1.5 || sprite.position.y > self.size.height+sprite.size.height/2.0) {
                    sprite.removeFromParent()
                }
            }
        }
        
        //move background
        
        // calculate the new position
        let yNewPosition = worldNode!.position.y + (yOrgPosition! - 5)
        
        // Check if right end is reached
        if yNewPosition <= -(3 * nodeTileHeight) {
            worldNode!.position = CGPoint(x: 0, y: 0)
            // Check if left end is reached
        } else if yNewPosition >= 0 {
            worldNode!.position = CGPoint(x:0, y:  -(3 * nodeTileHeight))
        } else {
            worldNode!.position = CGPoint(x:0, y: yNewPosition)
        }
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func dropEnemy(){
        let enemy = SKSpriteNode(imageNamed: "enemy")
        
        enemy.name = enemyName
        let actualX = random(min: enemy.size.width/2, max: scene!.size.width - enemy.size.height/2)
        enemy.position.x = actualX
        enemy.position.y = scene!.size.height - enemy.size.height/2
        addChild(enemy)
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.frame.size)
        enemy.physicsBody!.isDynamic = true
        enemy.physicsBody?.affectedByGravity = true
        enemy.physicsBody?.mass = 0.03
    }
    
    func addBlock() {
        let block = SKSpriteNode(imageNamed: "block")
    
        var actionMove: SKAction
    
        //come in from right
        if(Bool(truncating: arc4random_uniform(2) as NSNumber)){
            //let actualY = random(min: block.size.height/2, max: size.height - block.size.height/2)
            block.position = CGPoint(x: size.width + block.size.width/2, y: scene!.size.height)
            addChild(block)
            let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
            actionMove = SKAction.move(to: CGPoint(x: -block.size.width, y: 0), duration: TimeInterval(actualDuration))
        }
        //come in from left
        else{
            //let actualY = random(min: block.size.height/2, max: size.height - block.size.height/2)
            block.position = CGPoint(x: block.size.width/2 - size.width, y: scene!.size.height)
            addChild(block)
            
    //todo shorten the duration as time increases
            //let actualDuration = random(min: CGFloat(3.0), max: CGFloat(5.0))
            actionMove = SKAction.move(to: CGPoint(x: block.size.width*4, y: 0), duration: TimeInterval(CGFloat(5.0)))
        }
        
        block.name = blockName
        block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
        block.physicsBody!.isDynamic = false
        block.physicsBody?.affectedByGravity = true
        block.physicsBody?.mass = 0.1
   
        let actionMoveDone = SKAction.removeFromParent()
        
        block.run(SKAction.sequence([actionMove, actionMoveDone]))

    }

}
