//
//  GameSceneViewController.swift
//  FlappyBird
//
//  Created by 横田瑛美 on 2022/02/22.
//

import SpriteKit
import AVFoundation

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
    let berryCategory: UInt32 = 1 << 4
    
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    var berryScore = 0
    var berryScoreLabelNode:SKLabelNode!
    var berryBestScoreLabelNode:SKLabelNode!
    
    var player: AVAudioPlayer?
    let sound = SKAction.playSoundFileNamed("効果音.mp3", waitForCompletion: false)
    
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
            bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | berryCategory

            bird.physicsBody?.allowsRotation = false


            bird.run(flap)

            addChild(bird)
        }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear

        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)

        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)

        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()

        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])

        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()

        // 鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
        let slit_length = birdSize.height * 3

        // 隙間位置の上下の振れ幅を鳥のサイズの3倍とする
        let random_y_range = birdSize.height * 3

        // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2

        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
          // 壁関連のノードを乗せるノードを作成
          let wall = SKNode()
          wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
          wall.zPosition = -50 // 雲より手前、地面より奥

          // 0〜random_y_rangeまでのランダム値を生成
          let random_y = CGFloat.random(in: 0..<random_y_range)
          // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
          let under_wall_y = under_wall_lowest_y + random_y

          // 下側の壁を作成
          let under = SKSpriteNode(texture: wallTexture)
          under.position = CGPoint(x: 0, y: under_wall_y)

          // スプライトに物理演算を設定する
          under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
          under.physicsBody?.categoryBitMask = self.wallCategory

          // 衝突の時に動かないように設定する
          under.physicsBody?.isDynamic = false

          wall.addChild(under)

          // 上側の壁を作成
          let upper = SKSpriteNode(texture: wallTexture)
          upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)

          // スプライトに物理演算を設定する
          upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
          upper.physicsBody?.categoryBitMask = self.wallCategory

          // 衝突の時に動かないように設定する
          upper.physicsBody?.isDynamic = false

          wall.addChild(upper)

          // スコアアップ用のノード
          let scoreNode = SKNode()
          scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
          scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
          scoreNode.physicsBody?.isDynamic = false
          scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
          scoreNode.physicsBody?.contactTestBitMask = self.birdCategory

          wall.addChild(scoreNode)

          wall.run(wallAnimation)

          self.wallNode.addChild(wall)
        })

        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)

        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
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
        
            let birdSize = SKTexture(imageNamed: "bird_a").size()
            let random_y_range = birdSize.height * 3
            let groundSize = SKTexture(imageNamed: "ground").size()
            let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
            let item_lowest_y = center_y - berryTexture.size().height / 2 - random_y_range / 2
        
            let createBerryAnimation = SKAction.run({
                
                let random_y = CGFloat.random(in: 0...random_y_range)
                let berry_y = random_y+item_lowest_y
                
                let berry = SKSpriteNode(texture: berryTexture)
                berry.position = CGPoint(x: self.frame.size.width, y: berry_y)
                berry.zPosition = -50
                berry.physicsBody = SKPhysicsBody(rectangleOf: berryTexture.size())
                berry.physicsBody?.categoryBitMask = self.berryCategory
                berry.physicsBody?.isDynamic = false
                berry.run(berryAnimation)
                
                self.berryNode.addChild(berry)
                
            })
        
            let waitAnimation = SKAction.wait(forDuration: 1)
        
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
    
    func restart() {
            score = 0
            scoreLabelNode.text = "Score:\(score)"
            
            berryScore = 0
            berryScoreLabelNode.text = "Item Score:\(berryScore)"

            bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
            bird.physicsBody?.velocity = CGVector.zero
            bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
            bird.zRotation = 0

            wallNode.removeAllChildren()

            bird.speed = 1

            scrollNode.speed = 1
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
                
                berryScore = 0
                berryScoreLabelNode = SKLabelNode()
                berryScoreLabelNode.fontColor = UIColor.black
                berryScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 130)
                berryScoreLabelNode.zPosition = 100
                berryScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
                berryScoreLabelNode.text = "ItemScore:\(berryScore)"
                self.addChild(berryScoreLabelNode)
        
                let berryBestScore = userDefaults.integer(forKey: "BERRY_BEST")
                berryBestScoreLabelNode = SKLabelNode()
                berryBestScoreLabelNode.fontColor = UIColor.black
                berryBestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 160)
                berryBestScoreLabelNode.zPosition = 100
                berryBestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
                berryBestScoreLabelNode.text = "Item Best Score:\(berryBestScore)"
                self.addChild(berryBestScoreLabelNode)
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
                }else if (contact.bodyA.categoryBitMask & berryCategory) == berryCategory || (contact.bodyB.categoryBitMask & berryCategory) == berryCategory{
                    
                    print("ItemScoreUp")
                    berryScore += 1
                    berryScoreLabelNode.text = "ItemScore:\(berryScore)"
                    var berryBestScore = userDefaults.integer(forKey: "BERRY_BEST")
                    if (contact.bodyA.categoryBitMask & berryCategory) == berryCategory {
                            contact.bodyA.node?.removeFromParent()
                          }
                    if (contact.bodyB.categoryBitMask & berryCategory) == berryCategory {
                            contact.bodyB.node?.removeFromParent()
                          }
                    run(sound)
                    
                    if berryScore > berryBestScore {
                        berryBestScore = berryScore
                        berryBestScoreLabelNode.text = "Item Best Score:\(berryBestScore)"
                        userDefaults.set(berryBestScore, forKey: "BERRY_BEST")
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
}


    

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */



