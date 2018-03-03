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

struct PhysicsCategory {
    static let None:   UInt32 = 0
    static let All:    UInt32 = UInt32.max
    static let Coin:   UInt32 = 0b1        // 1
    static let Spike:  UInt32 = 0b10       // 2
    static let Enemy:  UInt32 = 0b11       // 3
    static let Player: UInt32 = 0b100      // 4
    static let Block:  UInt32 = 0b101      // 5
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    let player = SKSpriteNode(imageNamed: "player")
    let playerName = "player"
    let blockName = "block"
    let enemyName = "enemy"
    let spikeName = "spike"
    let coinName = "coin"
    var motionManager = CMMotionManager()
    var destX: CGFloat = 0.0
    let swipeUp = UISwipeGestureRecognizer()
    let swipeDown = UISwipeGestureRecognizer()
    var isGameOver = false
    
    var worldNode: SKNode?
    var nodeTileHeight: CGFloat = 0.0
    var yOrgPosition: CGFloat?
    
    var cam: SKCameraNode = SKCameraNode()
    
    @objc func swipeUpPlayerJump(){
        if let player = childNode(withName: playerName) as? SKSpriteNode {
            player.physicsBody!.applyForce(CGVector(dx:0, dy:1000))
        }
        else{
            let gameScene:GameScene = GameScene(size: self.view!.bounds.size) // create your new scene
            let transition = SKTransition.fade(withDuration: 1.0) // create type of transition (you can check in documentation for more transtions)
            gameScene.scaleMode = SKSceneScaleMode.fill
            self.view!.presentScene(gameScene, transition: transition)
        }
    }
    
    @objc func swipeDownPlayerRushDown(){
        if let player = childNode(withName: playerName) as? SKSpriteNode {
            player.physicsBody!.applyForce(CGVector(dx:0, dy:-1000))
        }
    }
    
    override func didMove(to view: SKView) {
        
        isGameOver = false
        
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
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.fontColor = SKColor.black
        scoreLabel.text = "Score: 0"
        scoreLabel.zPosition = 15
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - 30)

        addChild(scoreLabel)
        
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
        
        player.position = CGPoint(x: size.width/2, y: size.height*0.5)
        player.name = playerName
        player.physicsBody = SKPhysicsBody(rectangleOf: player.frame.size)
        player.physicsBody!.isDynamic = true
        player.physicsBody!.mass = 0.02
        player.physicsBody!.affectedByGravity = true
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.categoryBitMask = PhysicsCategory.Player
        player.physicsBody!.collisionBitMask = PhysicsCategory.All
        addChild(player)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.8)
        physicsWorld.contactDelegate = self
        
        swipeUp.addTarget(self, action: #selector(GameScene.swipeUpPlayerJump))
        swipeUp.direction = .up
        self.view!.addGestureRecognizer(swipeUp)
        
        swipeDown.addTarget(self, action: #selector(GameScene.swipeDownPlayerRushDown))
        swipeDown.direction = .down
        self.view!.addGestureRecognizer(swipeDown)
        
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
                    
                    if(data.acceleration.x > 0){
                        player.texture = SKTexture(imageNamed: "playerRight")
                    }
                    else{
                        player.texture = SKTexture(imageNamed: "playerLeft")
                    }
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
        if (player.position.y < 40) {
            gameOver()
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
        enemy.physicsBody!.categoryBitMask = PhysicsCategory.Enemy
        enemy.physicsBody!.collisionBitMask = PhysicsCategory.All
        enemy.physicsBody!.isDynamic = true
        enemy.physicsBody?.affectedByGravity = true
        enemy.physicsBody?.mass = 0.03
    }
    
    func addCoinToBlock(centerXDestination: CGFloat, actionMoveDone: SKAction, block: SKSpriteNode, duration: CGFloat){
        
        let coin = SKSpriteNode(imageNamed: "coin")
        var coinMove = SKAction.move(to: CGPoint(x:  centerXDestination, y:  coin.size.height*1.5), duration: TimeInterval(duration))
    
        coin.position = CGPoint(x: block.position.x, y: scene!.size.height + coin.size.height*1.5)
        addChild(coin)
        coin.zPosition = 10
        coin.name = coinName
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.frame.size)
        coin.physicsBody!.isDynamic = false
        coin.physicsBody?.affectedByGravity = true
        coin.physicsBody?.mass = 0.1
        coin.physicsBody?.categoryBitMask = PhysicsCategory.Coin
        coin.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        coin.run(SKAction.sequence([coinMove, actionMoveDone]))
        
        let coin2 = coin.copy() as! SKSpriteNode
        coinMove = SKAction.move(to: CGPoint(x:  centerXDestination - coin.size.width*1.5 , y:  coin.size.height*1.5), duration: TimeInterval(duration))
        coin2.position = CGPoint(x: coin.position.x - coin.size.width*1.5, y: coin.position.y)
        coin2.run(SKAction.sequence([coinMove, actionMoveDone]))
        addChild(coin2)
        
        let coin3 = coin.copy() as! SKSpriteNode
        coinMove = SKAction.move(to: CGPoint(x:  centerXDestination + coin.size.width*1.5 , y:  coin.size.height*1.5), duration: TimeInterval(duration))
        coin3.position = CGPoint(x: coin.position.x + coin.size.width*1.5, y: coin.position.y)
        coin3.run(SKAction.sequence([coinMove, actionMoveDone]))
        addChild(coin3)
    }
    
    func addSpikeToBlock(centerXDestination: CGFloat, actionMoveDone: SKAction, block: SKSpriteNode, duration: CGFloat){
        let spike = SKSpriteNode(imageNamed: "spike")
        var spikeMove = SKAction.move(to: CGPoint(x: centerXDestination, y:  -spike.size.height*1.25), duration: TimeInterval(duration))
        spike.position = CGPoint(x: block.position.x, y: block.position.y - spike.size.height*1.25)
        addChild(spike)
        spike.zPosition = 10
        spike.name = spikeName
        spike.physicsBody = SKPhysicsBody(rectangleOf: spike.frame.size)
        spike.physicsBody?.categoryBitMask = PhysicsCategory.Spike
        spike.physicsBody?.contactTestBitMask = PhysicsCategory.All
        spike.physicsBody!.isDynamic = false
        spike.physicsBody?.affectedByGravity = true
        spike.physicsBody?.mass = 0.1
        spike.run(SKAction.sequence([spikeMove, actionMoveDone]))
        
        let spike2 = spike.copy() as! SKSpriteNode
        spikeMove = SKAction.move(to: CGPoint(x:  centerXDestination - spike.size.width*1.25 , y:  -spike.size.height*1.25), duration: TimeInterval(duration))
        spike2.position = CGPoint(x: spike.position.x - spike.size.width*1.25, y: spike.position.y)
        spike2.run(SKAction.sequence([spikeMove, actionMoveDone]))
        addChild(spike2)
        
        let spike3 = spike.copy() as! SKSpriteNode
        spikeMove = SKAction.move(to: CGPoint(x:  centerXDestination + spike.size.width*1.25 , y:  -spike.size.height*1.25), duration: TimeInterval(duration))
        spike3.position = CGPoint(x: spike.position.x + spike.size.width*1.25, y: spike.position.y)
        spike3.run(SKAction.sequence([spikeMove, actionMoveDone]))
        addChild(spike3)
    }
    
    func addBlock() {
        let block = SKSpriteNode(imageNamed: "block")
    
        var actionMove: SKAction
        var centerXDestination: CGFloat
        let duration = CGFloat(5.0)
    
        //come in from right
        if(Bool(truncating: arc4random_uniform(2) as NSNumber)){
            //let actualY = random(min: block.size.height/2, max: size.height - block.size.height/2)
            block.position = CGPoint(x: size.width + block.size.width/2, y: scene!.size.height)
            addChild(block)
            //let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
            actionMove = SKAction.move(to: CGPoint(x: -block.size.width, y: 0), duration: TimeInterval(duration))
            centerXDestination = -block.size.width


        }
        //come in from left
        else{
            //let actualY = random(min: block.size.height/2, max: size.height - block.size.height/2)
            block.position = CGPoint(x: block.size.width/2 - size.width, y: scene!.size.height)
            addChild(block)
            
    //todo shorten the duration as time increases
            //let actualDuration = random(min: CGFloat(3.0), max: CGFloat(5.0))
            actionMove = SKAction.move(to: CGPoint(x: block.size.width*4, y: 0), duration: TimeInterval(duration))
            centerXDestination = block.size.width*4

        }
        
        block.name = blockName
        block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
        block.physicsBody!.isDynamic = false
        block.physicsBody?.affectedByGravity = true
        block.physicsBody?.mass = 0.1
        let actionMoveDone = SKAction.removeFromParent()
        block.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        // add spike to block block 1/3 of the time
        if(Int(arc4random_uniform(75)) < 25){
            addSpikeToBlock(centerXDestination: centerXDestination, actionMoveDone: actionMoveDone, block: block, duration: duration)
        }
        
        //add coins to block 50% of the time
        if(Bool(truncating: arc4random_uniform(2) as NSNumber)){
            addCoinToBlock(centerXDestination: centerXDestination, actionMoveDone: actionMoveDone, block: block, duration: duration)
        }
    }
    
    func coinCollidedWithPlayer(coin: SKSpriteNode) {
        coin.removeFromParent()
        score = score+1;
        print("player and coin")
        print(score)
    }
    
    func spikeCollidedWithEnemy(enemy: SKSpriteNode) {
        enemy.removeFromParent()
        score = score+3;
        print("enemy and spike")
        print(score)
    }
    
    func gameOver() {
       //todo
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "GameOver!"
        myLabel.fontColor = SKColor.black
        myLabel.fontSize = 55
        myLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.65)
        myLabel.zPosition = 20
        self.addChild(myLabel)
        
        let label = SKLabelNode(fontNamed:"Chalkduster")
        label.text = "(swipe up to play again)!"
        label.fontColor = SKColor.black
        label.fontSize = 25
        label.zPosition = 20
        label.position = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
        self.addChild(label)
        
        isGameOver = true
        player.removeFromParent()
    }

    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // switch the firstBody to be the lowerValue
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if(!isGameOver){
            if ((firstBody.categoryBitMask == PhysicsCategory.Coin) &&
                (secondBody.categoryBitMask == PhysicsCategory.Player)) {
                if let coin = firstBody.node as? SKSpriteNode {
                    coinCollidedWithPlayer(coin: coin)
                }
            }
            else if ((firstBody.categoryBitMask == PhysicsCategory.Spike) &&
                (secondBody.categoryBitMask == PhysicsCategory.Enemy)) {
                if let enemy = secondBody.node as? SKSpriteNode {
                    spikeCollidedWithEnemy(enemy: enemy)
                }
            }
            else if ((firstBody.categoryBitMask == PhysicsCategory.Spike) &&
                (secondBody.categoryBitMask == PhysicsCategory.Player)) {
                gameOver()
            }
        }
        
    }

}
