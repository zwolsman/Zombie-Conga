//
//  GameScene.swift
//  ZombieConga
//
//  Created by Marvin on 13/10/2017.
//  Copyright © 2017 Zwolsman. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    //Consts
    let ZOMBIE_ANIMATION_KEY = "zombieAnimation"
    let ENEMY_KEY = "enemy"
    let CAT_KEY = "cat"
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var isInvincible = false
    
    //Sounds
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed(
        "hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed(
        "hitCatLady.wav", waitForCompletion: false)
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    
    let zombieMovePointsPerSec: CGFloat = 480.0
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    
    var velocity = CGPoint.zero
    var lastTouchLocation = CGPoint.zero
    
    let playableRect: CGRect
    
    let zombieAnimation: SKAction
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16/9
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2
        playableRect = CGRect(x: 0,
                              y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        var textures:[SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
   
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        let background = SKSpriteNode(imageNamed: "background1")
        background.anchorPoint = CGPoint.zero
        background.position = CGPoint.zero
        background.zPosition = -1
        
        zombie.position = CGPoint(x: 400, y: 400)
        
        addChild(background)
        addChild(zombie)
        //Spawn enemies
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnEnemy()
                },
                               SKAction.wait(forDuration: 2.0)])))
        
        //Spawn cats
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnCat()
                },
                               SKAction.wait(forDuration: 1)])))
        
        debugDrawPlayableArea()
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        let distance = zombie.position - lastTouchLocation
        if distance.length() <= zombieMovePointsPerSec * CGFloat(dt) {
            zombie.position = lastTouchLocation
            velocity = CGPoint.zero
            stopZombieAnimation()
        } else {
            move(sprite: zombie, velocity: velocity)
            rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        }
        boundsCheckZombie()
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        moveZombieToward(location: touchLocation)
        lastTouchLocation = touchLocation
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    override func touchesMoved(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: CAT_KEY) { (node, _) in
            let cat = node as! SKSpriteNode
            if cat.frame.intersects(self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        for cat in hitCats {
            zombieHit(cat: cat)
        }
        
        if isInvincible {
            return 
        }
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: ENEMY_KEY) { (node, _) in
            let enemy = node as! SKSpriteNode
            if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
                hitEnemies.append(enemy)
            }
        }
        for enemy in hitEnemies {
            zombieHit(enemy: enemy)
        }
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: direction.angle)
        
        var amountToRotate = rotateRadiansPerSec * CGFloat(dt)
        if abs(shortest) < amountToRotate {
            amountToRotate = abs(shortest)
        }
        
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = ENEMY_KEY
        enemy.position = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: playableRect.minY + enemy.size.height/2,
                max: playableRect.maxY - enemy.size.height/2))
        addChild(enemy)
        let actionMove =
            SKAction.moveTo(x: -enemy.size.width/2, duration: 2.0)
         let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = CAT_KEY
        cat.position = CGPoint(
            x: CGFloat.random(min: playableRect.minX,
                              max: playableRect.maxX),
            y: CGFloat.random(min: playableRect.minY,
                              max: playableRect.maxY))
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scale(to: 1, duration: 0.5)
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence(
            [scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.run(SKAction.sequence(actions))
    }
   
    //MARK: Zombie Animations
    func startZombieAnimation() {
        if zombie.action(forKey: ZOMBIE_ANIMATION_KEY) == nil {
            zombie.run(SKAction.repeatForever(zombieAnimation), withKey: ZOMBIE_ANIMATION_KEY)
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeAction(forKey: ZOMBIE_ANIMATION_KEY)
    }
    //END MARK
    
    func zombieHit(cat: SKSpriteNode) {
        run(catCollisionSound)
        cat.removeFromParent()
    }
    func zombieHit(enemy: SKSpriteNode) {
        run(enemyCollisionSound)
        
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(
        withDuration: duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(
                dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        let endAction = SKAction.run { [weak self] in
            self?.isInvincible = false
            self?.zombie.isHidden = false
        }
        isInvincible = true
        zombie.run(SKAction.sequence([blinkAction, endAction]))
    }
}
