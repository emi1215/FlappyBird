//
//  GameSceneViewController.swift
//  FlappyBird
//
//  Created by 横田瑛美 on 2022/02/22.
//

import SpriteKit

class GameScene: SKScene,SKPhysicsContactDelegate{

        // Do any additional setup after loading the view.
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var berryNode:SKNode!
    
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3

    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard

    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        scrollNode = SKNode()
        addChild(scrollNode)
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        berryNode = SKNode()
        scrollNode.addChild(berryNode)
       
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupBerry()
    }
    
    func setupScoreLabel() {
                
                score = 0
                scoreLabelNode = SKLabelNode()
                scoreLabelNode.fontColor = UIColor.black
                scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
                scoreLabelNode.zPosition = 100
                scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
                scoreLabelNode.text = "Score:\(score)"
                self.addChild(scoreLabelNode)

                let bestScore = userDefaults.integer(forKey: "BEST")
                bestScoreLabelNode = SKLabelNode()
                bestScoreLabelNode.fontColor = UIColor.black
                bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
                bestScoreLabelNode.zPosition = 100
                bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                self.addChild(bestScoreLabelNode)
            }
        
    func setupBird() {
            
            let birdTextureA = SKTexture(imageNamed: "bird_a")
            birdTextureA.filteringMode = .linear
            let birdTextureB = SKTexture(imageNamed: "bird_b")
            birdTextureB.filteringMode = .linear

            let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
            let flap = SKAction.repeatForever(texturesAnimation)

            bird = SKSpriteNode(texture: birdTextureA)
            bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
            bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
            bird.physicsBody?.categoryBitMask = birdCategory
            bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
            bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory

            bird.physicsBody?.allowsRotation = false


            bird.run(flap)

            addChild(bird)
        }
    
    func setupWall(){
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        let movingDistance = self.frame.size.width + wallTexture.size().width
        
        let moveWall = SKAction.moveBy(x: -movingDistance,y: 0,duration: 4)
        
        let removeWall = SKAction.removeFromParent()
        
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        let slit_length = birdSize.height * 4

        let random_y_range: CGFloat = 60

        let groundSize = SKTexture(imageNamed: "ground").size()
        
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2

        let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2

        let createWallAnimation = SKAction.run({
                   
        let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50

        let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            
        let under_wall_y = under_wall_center_y + random_y

        let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.isDynamic = false

            wall.addChild(under)

        let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false

            wall.addChild(upper)
            
        let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            wall.addChild(scoreNode)

            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
            
        let waitAnimation = SKAction.wait(forDuration: 2)

        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))

            wallNode.run(repeatForeverAnimation)
           

       }
      
      func setupGround() {
        
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
          
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)

        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)

            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )

            sprite.run(repeatScrollGround)
            
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            sprite.physicsBody?.categoryBitMask = groundCategory

            sprite.physicsBody?.isDynamic = false

            scrollNode.addChild(sprite)
        }
    }

    func setupCloud() {
        
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest

        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2

        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)

        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)

        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100

            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )

            sprite.run(repeatScrollCloud)

            scrollNode.addChild(sprite)
        }
    }
    
    func setupBerry() {
        
            let berryTexture = SKTexture(imageNamed: "berry")
            berryTexture.filteringMode = .linear
        
            let movingDistance = self.frame.size.width + berryTexture.size().width
        
            let moveBerry = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
            let removeBerry = SKAction.removeFromParent()
        
            let berryAnimation = SKAction.sequence([moveBerry, removeBerry])
        
            let createBerryAnimation = SKAction.run({
                
                let random_y = CGFloat.random(in: -random_y_range...random_y_range)
                let berry_y = random_y
                
                let berry = SKSpriteNode(texture: berryTexture)
                berry.position = CGPoint(x: 0, y: berry_y)
                
                berry.run(berryAnimation)
                
                self.berryNode.addChild(berry)
            })
        
            let waitAnimation = SKAction.wait(forDuration: 2)
        
            let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createBerryAnimation, waitAnimation]))
        
            berryNode.run(repeatForeverAnimation)
        }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            bird.physicsBody?.velocity = CGVector.zero

            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else if bird.speed == 0 {
            restart()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
            
            if scrollNode.speed <= 0 {
                return
            }

            if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
                
                print("ScoreUp")
                score += 1
                scoreLabelNode.text = "Score:\(score)"
                var bestScore = userDefaults.integer(forKey: "BEST")
                            if score > bestScore {
                                bestScore = score
                                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                                userDefaults.set(bestScore, forKey: "BEST")
                                userDefaults.synchronize()
                            }
            } else {
                
                print("GameOver")

                scrollNode.speed = 0
                
                bird.physicsBody?.collisionBitMask = groundCategory

                let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
                bird.run(roll, completion:{
                    self.bird.speed = 0
                })
            }
        }
    func restart() {
            score = 0
            scoreLabelNode.text = "Score:\(score)"

            bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
            bird.physicsBody?.velocity = CGVector.zero
            bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
            bird.zRotation = 0

            wallNode.removeAllChildren()

            bird.speed = 1

            scrollNode.speed = 1
        }
}
    
        
    

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */



