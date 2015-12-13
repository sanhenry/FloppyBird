//
//  GameScene.swift
//  FloppyBird
//
//  Created by Shao-Han Tang on 11/22/15.
//  Copyright (c) 2015 Shao-Han Tang. All rights reserved.
//

import SpriteKit
    let scaleFactor:Float = 3.0

class GameScene: SKScene, SKPhysicsContactDelegate {
    let skyColor    = SKColor(red: 0, green: 191, blue: 255, alpha: 1)
    let scaleFactorCG = CGFloat(scaleFactor)
    let pipeGap = CGFloat(55)
    let birdCat:UInt32  = 1 << 0
    let pipeCat:UInt32  = 1 << 1
    let levelCat:UInt32 = 1 << 2
    let scoreCat:UInt32 = 1 << 3
    
    var bird:SKSpriteNode!
    var scrollNode  = SKNode()
    var groundNode  = SKNode()
    var pipeNode = SKNode()
    var canRestart = Bool(false)
    var score = NSInteger(0)
    var scoreLableNode:SKLabelNode!
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        canRestart = false
        
        //setup score and score label
        score = 0
        scoreLableNode = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        scoreLableNode.position = CGPointMake(CGRectGetMidX(self.frame), 3 * self.frame.size.height/4)
        scoreLableNode.zPosition = 100
        scoreLableNode.text = String(format: "%d", self.score)
        self.addChild(scoreLableNode)
        
        // Set the background color
        self.backgroundColor    = skyColor
        
        // Set the world physics
        self.physicsWorld.gravity   = CGVectorMake(0.0, -7.0)
        self.physicsWorld.contactDelegate = self
        //Setup all sprite
        self.addChild(scrollNode)
        self.addChild(groundNode)
        scrollNode.addChild(pipeNode)
        self.bird = setupBird()
        self.setupGround()
        self.setupSkyline()
        // set pipe sprite and movement
        let spwanPipe = SKAction.performSelector("setupPipe", onTarget: self)
        let delaySpawnPipe = SKAction.waitForDuration(1.8)
        let spwanThenDelay = SKAction.sequence([spwanPipe, delaySpawnPipe])
        let spwanThenDelayForever = SKAction.repeatActionForever(spwanThenDelay)
        self.runAction(spwanThenDelayForever)
        
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        if(self.scrollNode.speed > 0){
            self.bird.physicsBody?.velocity = CGVectorMake(0, 0)
            self.bird.physicsBody?.applyImpulse(CGVectorMake(0, 30))
        }else if(self.canRestart){
            self.resetScene()
        }
        
    }
    
    func resetScene(){
        // Move bird to original position and reset velocity
        self.bird.position = CGPoint(x: self.frame.size.width * 0.4,
            y: self.frame.size.height * 0.6)
        self.bird.physicsBody?.velocity = CGVectorMake(0,0)
        
        pipeNode.removeAllChildren()
        canRestart = false
        scrollNode.speed = 1
    }
    
    func setupBird() -> SKSpriteNode{
        
        // Fetch the image from bird1.png and bird2.png texture
        let birdTexture1 = SKTexture(imageNamed: "Bird1")
        birdTexture1.filteringMode   = .Nearest
        let birdTexture2 = SKTexture(imageNamed: "Bird2")
        birdTexture2.filteringMode   = .Nearest
        
        let flapAction = SKAction.repeatActionForever(SKAction.animateWithTextures([birdTexture1, birdTexture2], timePerFrame: 0.2))
        
        //Create our sprite node from texture
        let bird = SKSpriteNode(texture: birdTexture1)
        bird.runAction(flapAction)
        // Put the bird in the middle
        bird.setScale(scaleFactorCG)
        bird.position   = CGPoint(x: self.frame.size.width * 0.4,
            y: self.frame.size.height * 0.6)
        bird.physicsBody    = SKPhysicsBody(rectangleOfSize: bird.size)
        bird.physicsBody?.dynamic    = true
        bird.physicsBody?.allowsRotation    = false
        bird.physicsBody?.categoryBitMask = birdCat
        bird.physicsBody?.collisionBitMask = levelCat | pipeCat
        bird.physicsBody?.contactTestBitMask = levelCat | pipeCat
        
        // Add the bird node to SKScene
        self.addChild(bird)
        return bird
    }
    
    func setupGround(){
        
        //Set Texture
        let groundTexture = SKTexture(imageNamed: "Ground")
        //Add helper variables
        let groundTextureSize   = groundTexture.size();
        let groundTextureWidth  = groundTextureSize.width
        let groundTextureHeight = groundTextureSize.height
        
        //Add the SKActions that will allow the ground to move and reset
        //so it will appear to scorll indefinitely
        let moveGroundSprite    = SKAction.moveByX(-groundTextureWidth * scaleFactorCG, y: 0,  duration: NSTimeInterval(0.005 * groundTextureWidth * scaleFactorCG))
        let resetGroundSprite   = SKAction.moveByX(groundTextureWidth * scaleFactorCG, y: 0, duration: 0)
        let moveGroundSpriteForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]))
        groundTexture.filteringMode = .Nearest
        
        //Here we add some code to add enough ground sprites to
        //the scolling node depending on the width of the device
        for (var i:CGFloat = 0; i < 2.0 + self.frame.size.width / (groundTextureWidth * scaleFactorCG); ++i){
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(scaleFactorCG)
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2.0)
            sprite.runAction(moveGroundSpriteForever)
            self.scrollNode.addChild(sprite)
        }
        
        self.groundNode.position    = CGPointMake(0, groundTextureHeight * scaleFactorCG / 2.0)
        self.groundNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTextureHeight * scaleFactorCG))
        self.groundNode.physicsBody?.dynamic    = false
        self.groundNode.physicsBody?.categoryBitMask    = levelCat
        self.groundNode.physicsBody?.contactTestBitMask = birdCat
    }
    
    func setupSkyline(){
        //Set Texture
        let skyTexture  = SKTexture(imageNamed: "Skyline")
        let groundTexture   = SKTexture(imageNamed: "Ground")
        //Add helper variale
        let skyTextureWidth = skyTexture.size().width
        //let skyTextureHeight    = skyTexture.size().height
        let groundTextureHeight = groundTexture.size().height
        //skyline action
        let moveSkySprite   = SKAction.moveByX(-skyTextureWidth * scaleFactorCG, y: 0, duration: NSTimeInterval(0.025 * skyTextureWidth * scaleFactorCG))
        let resetSkySprite  = SKAction.moveByX(skyTextureWidth * scaleFactorCG, y: 0, duration: NSTimeInterval(0.0))
        let moveSkySpriteForever    = SKAction.repeatActionForever(SKAction.sequence([moveSkySprite, resetSkySprite]))
        skyTexture.filteringMode    = .Nearest
        
        for(var i:CGFloat = 0; i < 2.0 + self.frame.size.width / (skyTextureWidth * scaleFactorCG); ++i){
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(scaleFactorCG)
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2.0 + groundTextureHeight * scaleFactorCG)
            sprite.zPosition    = -20
            sprite.runAction(moveSkySpriteForever)
            self.scrollNode.addChild(sprite)
        }
        
    }
    
    func setupPipe(){
        let pipePairNode = SKNode()
        //setup pipe texture
        let pipeTexture1 = SKTexture(imageNamed: "Pipe1")
        pipeTexture1.filteringMode = .Nearest
        let pipeTexture2 = SKTexture(imageNamed: "Pipe2")
        pipeTexture2.filteringMode = .Nearest
        let pipeTextureWidth = pipeTexture1.size().width
        
        let randomHeight = CGFloat(Int(arc4random()) % Int(self.frame.size.height / 3))
        //setup pipe sprite
        let pipeSprite1 = SKSpriteNode(texture: pipeTexture1)
        pipeSprite1.setScale(scaleFactorCG)
        pipeSprite1.position = CGPointMake( 0, randomHeight)
        pipeSprite1.physicsBody = SKPhysicsBody(rectangleOfSize: pipeSprite1.size)
        pipeSprite1.physicsBody?.dynamic = false
        pipeSprite1.physicsBody?.categoryBitMask = pipeCat
        pipeSprite1.physicsBody?.contactTestBitMask = birdCat

        pipePairNode.addChild(pipeSprite1)
        
        let pipeSprite2 = SKSpriteNode(texture: pipeTexture2)
        pipeSprite2.setScale(scaleFactorCG)
        pipeSprite2.position = CGPointMake( 0, randomHeight + pipeSprite1.size.height + pipeGap * scaleFactorCG)
        pipeSprite2.physicsBody = SKPhysicsBody(rectangleOfSize: pipeSprite2.size)
        pipeSprite2.physicsBody?.dynamic = false
        pipeSprite2.physicsBody?.categoryBitMask = pipeCat
        pipeSprite2.physicsBody?.contactTestBitMask = birdCat
        pipePairNode.addChild(pipeSprite2)
        

        
        //setup action
        let distanceToMove = self.frame.size.width + pipeTextureWidth * scaleFactorCG
        let movePipe = SKAction.moveByX(-distanceToMove, y: 0, duration: NSTimeInterval(0.005 * distanceToMove))
        let removePipe = SKAction.removeFromParent()
        let moveAndRemovePipe = SKAction.sequence([movePipe, removePipe])
        
        pipePairNode.position = CGPointMake(self.frame.size.width + pipeTextureWidth * scaleFactorCG, 0)
        pipePairNode.zPosition = -10;
        pipePairNode.runAction(moveAndRemovePipe)
        
        pipeNode.addChild(pipePairNode)
        
    }
    
    func clamp(min: CGFloat, max: CGFloat, value: CGFloat) ->CGFloat{
        if(value < min){
            return min
        }else if(value > max){
            return max
        }else{
            return value
        }
    }
    
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        bird.zRotation = clamp(-1, max: 0.5, value: (self.bird.physicsBody?.velocity.dy)! * (self.bird.physicsBody?.velocity.dy < 0 ? 0.003 : 0.001))
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        // Flash background when contact is detected
        /*self.removeActionForKey("flash")
        let redColorAction = SKAction.runBlock{self.backgroundColor = SKColor.redColor()}
        let skyColorAction = SKAction.runBlock{self.backgroundColor = self.skyColor}
        self.runAction(SKAction.sequence([SKAction.repeatAction(SKAction.sequence([redColorAction, SKAction.waitForDuration(0.05), skyColorAction, SKAction.waitForDuration(0.05)]), count: 4)]) ,withKey: "flash")*/
        
        // Flash background if contact is detected
        if(self.scrollNode.speed > 0){
            self.scrollNode.speed = 0
            self.removeActionForKey("flash")
            self.runAction(SKAction.sequence([SKAction.repeatAction(SKAction.sequence([SKAction.runBlock({
                self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
            }),SKAction.waitForDuration(NSTimeInterval(0.05)), SKAction.runBlock({
                self.backgroundColor = self.skyColor
            }), SKAction.waitForDuration(NSTimeInterval(0.05))]), count:4), SKAction.runBlock({self.canRestart = true})]), withKey: "flash")
        }
        
    }
}
