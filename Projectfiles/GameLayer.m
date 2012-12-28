//
//  GameLayer.m
//  DoodleDrop
//
//  Created by Andrew Helmkamp on 12/27/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"


@implementation GameLayer

+(id)scene {
    CCScene *scene = [CCScene node];
    CCLayer *layer = [GameLayer node];
    [scene addChild:layer];
    return scene;
}

-(id) init {
    if ((self = [super init])) {
        CCLOG(@"%@: %@", NSStringFromSelector(_cmd), self);
        
        self.isAccelerometerEnabled = YES;
        
        player = [CCSprite spriteWithFile:@"alien.png"];
        [self addChild:player z:0 tag:1];
        
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        float imageHeight = player.texture.contentSize.height;
        player.position = CGPointMake(screenSize.width/2, imageHeight/2);
        
        [self scheduleUpdate];
        [self initSpiders];
    }
    
    return self;
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    //controls deceleration-lower = quicker
    float deceleration = 0.4f;
    //determines how sensitive the accelerometer reacts (higher = more sensitive)
    float sensitivity = 6.0f;
    //max velocity
    float maxVelocity = 100;
    
    //adjust velocity based on current accelerometer acceleration
    playerVelocity.x = playerVelocity.x * deceleration + acceleration.x * sensitivity;
    
    //limit max velocity of the player in both directions
    if (playerVelocity.x > maxVelocity) {
        playerVelocity.x = maxVelocity;
    } else if (playerVelocity.x < -maxVelocity) {
        playerVelocity.x = -maxVelocity;
    }
}

-(void)update:(ccTime)delta {
    //keep adding up the playerVelocity to the player's position
    CGPoint pos = player.position;
    pos.x += playerVelocity.x;
    
    //stop the player from going offscreen
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    float imageWidthHalved = player.texture.contentSize.width * 0.5f;
    float leftBorderLimit = imageWidthHalved;    
    float rightBorderLimit = screenSize.width - imageWidthHalved;
    
    if (pos.x < leftBorderLimit) {
        pos.x = leftBorderLimit;
        playerVelocity = CGPointZero;
    } else if (pos.x > rightBorderLimit) {
        pos.x = rightBorderLimit;
        playerVelocity = CGPointZero;
    }
    
    //assign the modified position back
    player.position = pos;
    
    [self checkForCollision];
}

-(void)initSpiders {
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
    //using a temp spider sprite to get image size
    CCSprite *tempSpider = [CCSprite spriteWithFile:@"spider.png"];
    
    float imageWidth = tempSpider.texture.contentSize.width;
    
    //Use as many spiders as can fit next to each other over the whole screen width
    int numSpiders = screenSize.width/imageWidth;
    
    //init the spiders array using alloc
    spiders = [NSMutableArray arrayWithCapacity:numSpiders];
    
    for (int i =0; i < numSpiders; i++) {
        CCSprite *spider = [CCSprite spriteWithFile:@"spider.png"];
        [self addChild:spider z:0 tag:2];
        
        //also add it to the array
        [spiders addObject:spider];
    }
    
    //call the method to reposition all spiders
    [self resetSpiders];
}

-(void)resetSpiders {
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
    //get any spider to get its image width
    CCSprite *tempSpider = [spiders lastObject];
    CGSize size = tempSpider.texture.contentSize;
    
    int numSpiders = [spiders count];
    for (int i = 0; i < numSpiders; i++) {
        //put each spider at it's position outside the screen
        CCSprite *spider = [spiders objectAtIndex:i];
        spider.position = CGPointMake(size.width * i + size.width * 0.5, screenSize.height + size.height);
        
        [spider stopAllActions];
    }
    
    //Schedule the spider update logic
    [self schedule:@selector(spidersUpdate:) interval:0.7f];
    
    //reset the moved spiders counter and spider move duration
    numSpidersMoved = 0;
    spiderMoveDuration = 4.0f;
}

-(void)spidersUpdate:(ccTime)delta {
    //try to find a spider which isn't moving
    for (int i = 0; i < 10; i++) {
        int randomSpiderIndex = CCRANDOM_0_1() * spiders.count;
        CCSprite *spider = [spiders objectAtIndex:randomSpiderIndex];
        
        //if the spider isn't moving there will be no actions on it
        if (spider.numberOfRunningActions ==0) {
            [self runSpiderMoveSequence:spider];
            break; //only one should move at a time
        }
    }
}

-(void)runSpiderMoveSequence:(CCSprite*)spider {
    //slowly increase the spider speed over time
    numSpidersMoved++;
    if (numSpidersMoved % 8 == 0 && spiderMoveDuration > 2.0f) {
        spiderMoveDuration -= 0.1f;
    }
    
    //spider movement sequence
    CGPoint belowScreenPosition = CGPointMake(spider.position.x, -spider.texture.contentSize.height);
    CCMoveTo *move = [CCMoveTo actionWithDuration:spiderMoveDuration position:belowScreenPosition];
    
    CCCallBlock *callDidDrop = [CCCallBlock actionWithBlock:^void(){
       //move the droppedSpider back up outside the top of the screen
        CGPoint pos = spider.position;
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        pos.y = screenSize.height + spider.texture.contentSize.height;
        spider.position = pos;
    }];
    
    CCSequence *sequence = [CCSequence actions:move, callDidDrop, nil];
    [spider runAction:sequence];
}

-(void)checkForCollision {
    // Assume both player and spider are squares
    float playerImageSize = player.texture.contentSize.width;
    CCSprite* spider = [spiders lastObject];
    float spiderImageSize = spider.texture.contentSize.width;
    float playerCollisionRadius = playerImageSize * 0.4f;
    float spiderCollisionRadius = spiderImageSize * 0.4f;
    
    //collision distance will roughly equal the image shapes.
    float maxCollisionDistance = playerCollisionRadius + spiderCollisionRadius;
    int numSpiders = spiders.count;
    for (int i = 0; i < numSpiders; i++) {
        spider = [spiders objectAtIndex:i];
        
        if (spider.numberOfRunningActions == 0) {
            //spider isn't moving so we can skip it
            continue;
        }
        
        //get the distance between player and spider
        float actualDistance = ccpDistance(player.position, spider.position);
        
        //Are the two objects closer than allowed?
        if (actualDistance < maxCollisionDistance) {
            //Game Over (just restart the game for now)
            [self resetGame];
            break;
        }
    }
}

#if DEBUG
-(void) draw {
    [super draw];
    
    for (CCNode *node in [self children]) {
        if ([node isKindOfClass:[CCSprite class]] && (node.tag == 1 || node.tag == 2)) {
            CCSprite *sprite = (CCSprite*)node;
            float radius = sprite.texture.contentSize.width * 0.4f;
            float angle = 0;
            int numSegments = 10;
            bool drawLineToCenter = NO;
            ccDrawCircle(sprite.position, radius, angle, numSegments, drawLineToCenter);
        }
    }
}
#endif

-(void) resetGame {
    [self resetSpiders];
}





-(void) dealloc {
    CCLOG(@"%@: %@", NSStringFromSelector(_cmd), self);
}


@end
