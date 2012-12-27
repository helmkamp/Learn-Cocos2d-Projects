//
//  GameLayer.h
//  DoodleDrop
//
//  Created by Andrew Helmkamp on 12/27/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameLayer : CCLayer {
    CCSprite *player;
    CGPoint playerVelocity;
}

+(id)scene;

@end
