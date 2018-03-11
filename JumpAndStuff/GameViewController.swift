//
//  GameViewController.swift
//  JumpAndStuff
//
//  Created by Matt Corrente on 3/1/18.
//  Copyright © 2018 Matt Corrente. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVKit

class GameViewController: UIViewController {
    
    var bgSoundPlayer:AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.playBackgroundSound(_:)), name: NSNotification.Name(rawValue: "PlayBackgroundSound"), object: nil) //add this to play audio
        
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.stopBackgroundSound), name: NSNotification.Name(rawValue: "StopBackgroundSound"), object: nil) //add this to stop the audio

        let scene = MainMenuScene(size: view.bounds.size)
        let skView = view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        
    }
    
    @objc func playBackgroundSound(_ notification: Notification) {
        
        var playFile = true
        
        //get the name of the file to play from the data passed in with the notification
        let name = (notification as NSNotification).userInfo!["fileToPlay"] as! String
        
        //as long as name has at least some value, proceed...
        if (name != ""){
            
            //create a URL variable using the name variable and tacking on the "mp3" extension
            let fileURL:URL = Bundle.main.url(forResource:name, withExtension: "mp3")!
            
            if(bgSoundPlayer != nil){
                //check if the player is currently playing the file we want to play
                if(bgSoundPlayer!.url == fileURL){
                    playFile = false
                }
                else{
                    bgSoundPlayer!.stop()
                    bgSoundPlayer = nil
                }

            }//end if bgSoundPlayer != nil
            
            if(playFile){
                //basically, try to initialize the bgSoundPlayer with the contents of the URL
                do {
                    bgSoundPlayer = try AVAudioPlayer(contentsOf: fileURL)
                } catch _{
                    bgSoundPlayer = nil
                }
                
                bgSoundPlayer!.volume = 0.75 //set the volume anywhere from 0 to 1
                bgSoundPlayer!.numberOfLoops = -1 // -1 makes the player loop forever
                bgSoundPlayer!.prepareToPlay() //prepare for playback by preloading its buffers.
                bgSoundPlayer!.play() //actually play
            }
            
        }//end if name != nil
    }
    
    @objc func stopBackgroundSound() {
        
        //if the bgSoundPlayer isn't nil, then stop it
        if (bgSoundPlayer != nil){
            bgSoundPlayer!.stop()
            bgSoundPlayer = nil
        }
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
