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
    let TRAIN_KEY = "train"
    let BACKGROUND_KEY = "background"
    
    //Sounds
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed(
        "hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed(
        "hitCatLady.wav", waitForCompletion: false)
    
    //Zombie
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    let zombieMovePointsPerSec: CGFloat = 480
    let zombieRotateRadiansPerSec:CGFloat = 4 * π
    let zombieAnimation: SKAction
    var velocity = CGPoint.zero

    //Cat
    let catMovePointsPerSec: CGFloat = 480
    let catRotateRadiansPerSec: CGFloat = 4 * π
    
    //Game
    let playableRect: CGRect
    var cameraRect : CGRect {
        let x = cameraNode.position.x - size.width/2
            + (size.width - playableRect.width)/2
        let y = cameraNode.position.y - size.height/2
            + (size.height - playableRect.height)/2
        return CGRect(
            x: x,
            y: y,
            width: playableRect.width,
            height: playableRect.height)
    }
    var lastTouchLocation = CGPoint.zero
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    var isInvincible = false
    var lives = 5
    var isGameOver = false
    
    //Background
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec:CGFloat = 200
    
    //Labels
    let livesLabel = SKLabelNode(fontNamed: "Glimstick")
    let catsLabel = SKLabelNode(fontNamed: "Glimstick")

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
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        playBackgroundMusic(filename: "backgroundMusic.mp3")
        
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position =
                CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = BACKGROUND_KEY
            addChild(background)
        }
        
        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition = 100
        
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
        
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        livesLabel.text = "Lives: X"
        livesLabel.fontColor = SKColor.black
        livesLabel.fontSize = 100
        livesLabel.zPosition = 150
        cameraNode.addChild(livesLabel)
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.position = CGPoint(
            x: -playableRect.size.width/2 + CGFloat(20),
            y: -playableRect.size.height/2 + CGFloat(20))
        
        catsLabel.text = "Cats: X"
        catsLabel.fontColor = SKColor.black
        catsLabel.fontSize = 100
        catsLabel.zPosition = 150
        cameraNode.addChild(catsLabel)
        catsLabel.horizontalAlignmentMode = .right
        catsLabel.verticalAlignmentMode = .bottom
        catsLabel.position = CGPoint(
            x: playableRect.size.width/2 - CGFloat(20),
            y: -playableRect.size.height/2 + CGFloat(20))
        
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
    
        move(sprite: zombie, velocity: velocity)
        rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        boundsCheckZombie()
        moveTrain()
        moveCamera()
        livesLabel.text = "Lives: \(lives)"
        if lives <= 0 && !isGameOver {
            isGameOver = true
            gameOver(won: false)
        }
    }
    
    func gameOver(won:Bool) {
        backgroundMusicPlayer.stop()
        let gameOverScene = GameOverScene(size: size, won: won)
        gameOverScene.scaleMode = scaleMode
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        view?.presentScene(gameOverScene, transition: reveal)
    }
    
    func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint.zero
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position =
            CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
        return backgroundNode
    }
    
    func moveCamera() {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        enumerateChildNodes(withName: BACKGROUND_KEY) { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width <
                self.cameraRect.origin.x {
                background.position = CGPoint(
                    x: background.position.x + background.size.width*2,
                    y: background.position.y)
            }
        }
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
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = abs(velocity.x)
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
            x: cameraRect.maxX + enemy.size.width/2,
            y: CGFloat.random(
                min: cameraRect.minY + enemy.size.height/2,
                max: cameraRect.maxY - enemy.size.height/2))
        enemy.zPosition = 50
        addChild(enemy)
        let actionMove = SKAction.moveTo(x: cameraRect.minX + -enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = CAT_KEY
        cat.position = CGPoint(
            x: CGFloat.random(min: cameraRect.minX,
                              max: cameraRect.maxX),
            y: CGFloat.random(min: cameraRect.minY,
                              max: cameraRect.maxY))
        cat.zPosition = 50
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
    
    func moveTrain() {
        var targetPosition = zombie.position
        var cats = 0
        enumerateChildNodes(withName: "train") { node, stop in
            let offset = targetPosition - node.position// a
            let direction = offset.normalized() // b
            cats += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let amountToMovePerSec = direction * self.catMovePointsPerSec // c
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration) // d
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)// e
                node.run(moveAction)
            }
            self.rotate(sprite: node as! SKSpriteNode, direction: direction, rotateRadiansPerSec: self.catRotateRadiansPerSec)
            targetPosition = node.position
        }
        catsLabel.text = "Cats: \(cats)"

        if cats >= 15 && !isGameOver{
            isGameOver = true
            gameOver(won: true)
        }
    }
    
    func loseCats() {
        var loseCount = 0
        enumerateChildNodes(withName: TRAIN_KEY) { (node, stop) in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            node.name = ""
            node.run(
                    SKAction.sequence([
                        SKAction.group([
                            SKAction.rotate(byAngle: 4, duration: 1),
                            SKAction.move(to: randomSpot, duration: 1),
                            SKAction.scale(to: 0, duration: 1)]),
                        SKAction.removeFromParent()]))
            loseCount += 1
            if loseCount >= 2 {
                stop[0] = true
            }
        }
    }
    
    func zombieHit(cat: SKSpriteNode) {
        run(catCollisionSound)
        cat.name = TRAIN_KEY
        cat.removeAllActions()
        cat.setScale(1)
        cat.zRotation = 0
        let colorAction = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1, duration: 0.2)
        cat.run(colorAction)
    }
    
    func zombieHit(enemy: SKSpriteNode) {
        run(enemyCollisionSound)
        loseCats()
        lives -= 1
        
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
