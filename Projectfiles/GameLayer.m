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
    }
    
    return self;
}

-(void) dealloc {
    CCLOG(@"%@: %@", NSStringFromSelector(_cmd), self);
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
    
    CGPoint pos = player.position;
    pos.x = acceleration.x*10;
    player.position = pos;
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
}

@end
