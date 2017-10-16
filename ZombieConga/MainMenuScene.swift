//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Marvin on 16/10/2017.
//  Copyright © 2017 Zwolsman. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "MainMenu")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        self.addChild(background)
    }
    
    func sceneTapped() {
        let targetScene = GameScene(size: size)
        targetScene.scaleMode = scaleMode
        
        let transition = SKTransition.doorway(withDuration: 1.5)
        
        view?.presentScene(targetScene, transition: transition)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sceneTapped()
    }
}
