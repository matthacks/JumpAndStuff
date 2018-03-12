//
//  MainMenuScene.swift
//  ParachutePlunge
//
//  Created by Matt Corrente on 3/10/18.
//  Copyright © 2018 Matt Corrente. All rights reserved.
//

import SpriteKit
import GameplayKit


class MainMenuScene: SKScene, SKPhysicsContactDelegate {

    
    let player = spriteNodeWithSound(imageNamed: "player")
    let playerName = "player"
    let blockName = "block"
    let enemyName = "enemy"
    let spikeName = "spike"
    let coinName = "coin"
    var destX: CGFloat = 0.0
    let swipeUp = UISwipeGestureRecognizer()
    let swipeDown = UISwipeGestureRecognizer()
    let swipeLeft = UISwipeGestureRecognizer()
    let swipeRight = UISwipeGestureRecognizer()
    var isGameOver = false
    var backgroundMusic: SKAudioNode!
    
    var worldNode: SKNode?
    var nodeTileHeight: CGFloat = 0.0
    var yOrgPosition: CGFloat?
    
    var cam: SKCameraNode = SKCameraNode()
    
    var button: UIButton!
    
    class spriteNodeWithSound: SKSpriteNode {
        var spriteSound: SKAudioNode!
    }
    
    func initLabels(){
            //todo
            let myLabel = SKLabelNode(fontNamed:"Chalkduster")
            myLabel.text = "Parachute Plunge"
            myLabel.fontColor = SKColor.black
            myLabel.fontSize = 30
            myLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.65)
            myLabel.zPosition = 20
            self.addChild(myLabel)
            
            let label = SKLabelNode(fontNamed:"Chalkduster")
            label.numberOfLines = 0
            label.text = "Avoid Hazards.\nCollect coins.\nSwipe to move."
            label.fontColor = SKColor.black
            label.fontSize = 20
            label.zPosition = 20
            label.position = CGPoint(x: size.width * 0.5, y: size.height * 0.50)
            self.addChild(label)

        }
    
    
    func transitionToPlayScene(){
        button.alpha = 1
        button.removeFromSuperview()
        
        let gameScene:GameScene = GameScene(size: self.view!.bounds.size) // create your new scene
        let transition = SKTransition.fade(withDuration: 1.0) // create type of transition (you can check in documentation for more transtions)
        gameScene.scaleMode = SKSceneScaleMode.fill
        self.view!.presentScene(gameScene, transition: transition)
    }
    
    @objc func buttonAction(sender: UIButton!) {
        let movePlayer  = SKAction.move(to: CGPoint(x: player.position.x, y: size.height/2 ), duration: TimeInterval(1))
        player.run(SKAction.sequence([movePlayer]), completion: {
            self.transitionToPlayScene()
        })
    }
    
    @objc func buttonHeld(sender: UIButton!) {
        button.alpha = 0.3
    }

    func addPlayButton(){
        button = UIButton(frame: CGRect(x: size.width * 0.35, y: size.height * 0.70, width: 100, height: 50))
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        button.backgroundColor = .blue
        button.setTitle("Play", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonHeld), for: .touchDown)

        self.view?.addSubview(button)
    }
    
    override func didMove(to view: SKView) {
        
        if(UserDefaults.standard.object(forKey: "highScore") == nil){
            UserDefaults.standard.setValue(0, forKey:"highScore")
        }
        
        initLabels()
        addPlayButton()
        
        isGameOver = false
        
        let dictToSend: [String: String] = ["fileToPlay": "electroIndie" ]  //would play a file named "MusicOrWhatever.mp3"
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PlayBackgroundSound"), object: self, userInfo:dictToSend) //posts the notification
        
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
        
        player.position = CGPoint(x: size.width*0.5, y: size.height*0.75)
        addChild(player)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self
    }
    
    
    override func update(_ currentTime: CFTimeInterval){
        super.update(currentTime)

        // calculate the new position
        let yNewPosition = worldNode!.position.y + (yOrgPosition! + 5)
        
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
    
}

    


