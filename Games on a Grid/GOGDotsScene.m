
#import <GLKit/GLKit.h>
#import "GOGDotsScene.h"

@interface GOGDotsScene ()
{
}

@end


@implementation GOGDotsScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        [self addChild:self.scoreLabel];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        SKNode* touchedNode = [self nodeAtPoint:location];
        
        //-- Ignore touches to the background scene.
        if([self isBackgroundNode:touchedNode] == YES) {
            break;
        }
        
        self.currentTouch = touch;
        
        //-- Reset the touched Tile list.
        self.touchedTiles = [[NSMutableArray alloc] initWithObjects:touchedNode, nil];
        
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //-- Ignore any movement if we haven't started a valid touch
    if([self.touchedTiles count] == 0)
        return;
    
    for (UITouch *touch in touches) {
        if(self.currentTouch != touch)
            continue;
        SKNode* gridRoot = [self childNodeWithName:@"gridroot"];
        CGPoint locationInNode = [touch locationInNode:gridRoot];
        SKNode* touchedNode = [gridRoot nodeAtPoint:locationInNode];
        
        //-- bail if we already counted this node.
        if([self.touchedTiles containsObject:touchedNode] == NO) {
            //-- can we add it to our list?
            SKNode* prevTile = self.touchedTiles[self.touchedTiles.count-1];
            
            //-- match yes/no
            if([self keyForTile:touchedNode] != [self keyForTile:prevTile]) {
                canComputeEndofTurn = NO;
                continue;
            }
            
            //-- Also check that our last is the same as the first. N-N-N-X should not remove the N-N-N part.
            if([self keyForTile:touchedNode] != [self keyForTile:self.touchedTiles[0]]) {
                canComputeEndofTurn = NO;
                continue;
            }
            
            //-- check direction
            CGPoint prevTileLocation = [self locationOfTile:prevTile];
            CGPoint tileLocation = [self locationOfTile:touchedNode];
            
            NSInteger pX = (NSInteger)prevTileLocation.x;
            NSInteger pY = (NSInteger)prevTileLocation.y;
            NSInteger tX = (NSInteger)tileLocation.x;
            NSInteger tY = (NSInteger)tileLocation.y;
            
            //-- ignore diagonals. HARD CORE MODE, requires better thought out grid seeding
//            if(pX != tX && pY != tY) {
//                continue;
//            }
            
            if(abs(pX-tX) > 1 || abs(pY-tY) > 1) {
                continue;
            }
            
            //-- cut off after N matches ?
            [self.touchedTiles addObject:touchedNode];
            canComputeEndofTurn = YES;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.currentTouch = nil;
    bonusMult = 1;
    
    if(self.touchedTiles.count >= 2 && canComputeEndofTurn == YES) {
            CGFloat duration = 0.0f;
            for (SKNode* tile in self.touchedTiles) {
                SKAction* seq = [SKAction sequence:@[[SKAction waitForDuration:duration], self.bombAnim]];
                [tile runAction:seq completion:^(){
                    [self removeTile:[self locationOfTile:tile]];
                }];
                duration+=0.1f;
                bonusMult+=1;
                currentScore += (bonusMult*100);
            }
    }
}


@end
