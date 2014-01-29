
#import "GOGMatchThreeScene.h"

@interface GOGMatchThreeScene ()
{
}

@end


@implementation GOGMatchThreeScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        [self addChild:self.scoreLabel];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    bonusMult = 1;
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        //NSLog(@"touchID=%@", touch);
        SKNode* touchedNode = [self nodeAtPoint:location];
        
        //-- Ignore touches to the background scene.
        if([self isBackgroundNode:touchedNode] == YES) {
            //-- log grid
            //[self logGrid];
            break;
        }
        //NSLog(@"touchedNode=%@", touchedNode);
 
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
        
        //-- Determine direction of movement
        CGPoint viewLocation = [touch locationInView:self.view];
        CGPoint previousViewLocation = [touch previousLocationInView:self.view];
        CGPoint delta = CGPointMake(viewLocation.x-previousViewLocation.x, viewLocation.y-previousViewLocation.y);
        
        //-- Match3, tell tile to move, nil out the tracking touch to force user to release touch.
        [self tryMoveTile:self.touchedTiles[0] withDirection:delta];
        self.currentTouch = nil;
        canComputeEndofTurn = YES;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.currentTouch = nil;
 
    if(canComputeEndofTurn == YES) {
        [self endOfTurn];
    }
    
}

- (NSMutableArray*)findFirstMatch {
    for (int y=(int)(currentGridHeight-1); y>=0; y--) {
        for(int x=0; x<currentGridWidth; x++) {
            SKNode* currentTile = self.gridData[(y*currentGridWidth)+x];
            unsigned short key = [[currentTile.userData objectForKey:@"data"] unsignedShortValue];
            int leftX = x;
            while(leftX>=0) {
                unsigned short thisKey = [self keyForTileLocation:CGPointMake(leftX, y)];
                if(thisKey != key){
                    leftX++;
                    break;
                }
                
                leftX--;
            }
            if(leftX < 0)
                leftX = 0;
            
            int rightX = x;
            while(rightX < currentGridWidth) {
                unsigned short thisKey = [self keyForTileLocation:CGPointMake(rightX, y)];
                if(thisKey != key) {
                    rightX--;
                    break;
                }
                
                rightX++;
            }
            if(rightX >= currentGridWidth)
                rightX = (int)(currentGridWidth - 1);
            
            int total = (rightX-leftX);
            total+=1;
            if(total >= 3) {
                //-- Found a match, remove those tiles, move tiles down.
                NSMutableArray* foundMatch = [[NSMutableArray alloc] init];
                for(int a = leftX; a<=rightX; a++) {
                    [foundMatch addObject:[NSValue valueWithCGPoint:CGPointMake(a,y)]];
                }
                return foundMatch;
            }
            
            //--Vertical
            int topY = y;
            while (topY >= 0) {
                unsigned short thisKey = [self keyForTileLocation:CGPointMake(x, topY)];
                if(thisKey != key){
                    topY++;
                    break;
                }
                
                topY--;
            }
            if(topY < 0)
                topY = 0;
            
            int bottomY = y;
            while(bottomY < currentGridHeight) {
                unsigned short thisKey = [self keyForTileLocation:CGPointMake(x, bottomY)];
                if(thisKey != key) {
                    bottomY--;
                    break;
                }
                
                bottomY++;
            }
            if(bottomY >= currentGridHeight)
                bottomY = (int)(currentGridHeight - 1);
            total = bottomY - topY;
            total += 1;
            if(total >= 3) {
                NSMutableArray* foundMatch = [[NSMutableArray alloc] init];
                //-- Found a match, remove those tiles, move tiles down.
                for(int a = topY; a<=bottomY; a++) {
                    [foundMatch addObject:[NSValue valueWithCGPoint:CGPointMake(x,a)]];
                }
                return foundMatch;
            }
        }
    }
    return nil;
}

-(void)endOfTurn {
    bonusMult = 1;
    //-- remove tiles.
    NSMutableArray* foundMatch = [self findFirstMatch];
    while(foundMatch != nil && foundMatch.count > 0) {
        
        for (NSValue* ptValue in foundMatch) {
            [self removeTile:[ptValue CGPointValue]];
            currentScore += (bonusMult*100);
        }
        foundMatch = [self findFirstMatch];
        bonusMult+=1;
    }
}



-(BOOL)tryMoveTile:(SKNode*)tile withDirection:(CGPoint)direction {
    //-- User wants to move tile in a direction.
    //-- Is it a valid move?

    //-- figure out the x,y tile location of tile.
    CGPoint tileLocation = [self locationOfTile:tile];
    
    //-- Match 3.
    //-- Can only move in one direction, so zero out the lower of the 2 directions.
    if(fabs(direction.x) < fabs(direction.y)) {
        direction.x = 0;
        direction.y /= fabs(direction.y);
    }
    else {
        direction.y = 0;
        direction.x /= fabs(direction.x);
    }
    
    if(((NSUInteger)tileLocation.x == 0) && (direction.x < 0)) {
        return NO;
    }
    if(((NSUInteger)tileLocation.y == 0) && (direction.y < 0)) {
        return NO;
    }
    if(((NSUInteger)tileLocation.y == (currentGridHeight-1)) && (direction.y > 0)) {
        return NO;
    }
    if(((NSUInteger)tileLocation.x == (currentGridWidth-1)) && (direction.x > 0)) {
        return NO;
    }
    
    CGPoint newTileLocation = CGPointMake(tileLocation.x+direction.x, tileLocation.y+direction.y);
    //-- Can we swap these 2 tiles, according to the rules?
    SKNode* tileB = [self tileFromTileLocation:newTileLocation];
    
    if([self trySwapTilesWithLocation:tileLocation and:newTileLocation] == NO)
    {
        [self moveTile:tile toTileLocation:newTileLocation withSnapBack:YES];
        [self moveTile:tileB toTileLocation:tileLocation withSnapBack:YES];
        return NO;
    }
    
    //-- Animate the movement of the 2 tiles.
    [self moveTile:tile toTileLocation:newTileLocation withSnapBack:NO];
    [self moveTile:tileB toTileLocation:tileLocation withSnapBack:NO];
    
    return YES;
}

-(BOOL)trySwapTilesWithLocation:(CGPoint)tileALocation and:(CGPoint)tileBLocation {
    //-- Swapping A into B's location.
    
    SKNode* tileA = [self tileFromTileLocation:tileALocation];
    SKNode* tileB = [self tileFromTileLocation:tileBLocation];
    
    if(tileA == nil || tileB == nil)
        return NO;
    
    //-- Do the swap, then check for validity
    [self setTile:tileA atLocation:tileBLocation];
    [self setTile:tileB atLocation:tileALocation];
    
    
    SKNode* checkTile = nil, *tile1 = nil, *tile2 = nil;
    CGPoint location = tileBLocation;
    for(int i=0; i<2; i++) {
        if(i == 0) {
            checkTile = tileA;
            location = tileBLocation;
        }
        else {
            checkTile = tileB;
            location = tileALocation;
        }
        
        //-- Check vertical
        if((NSUInteger)(location.y+2) < currentGridHeight) {
            tile1 = [self tileFromTileLocation:CGPointMake(location.x, location.y+2)];
            tile2 = [self tileFromTileLocation:CGPointMake(location.x, location.y+1)];
            if([self doTilesMatch:checkTile tile1:tile1 tile2:tile2] == YES)
                return YES;
        }
        
        if((NSUInteger)location.y > 0 && (NSUInteger)location.y < (currentGridHeight-1)) {
            tile1 = [self tileFromTileLocation:CGPointMake(location.x, location.y+1)];
            tile2 = [self tileFromTileLocation:CGPointMake(location.x, location.y-1)];
            if([self doTilesMatch:checkTile tile1:tile1 tile2:tile2] == YES)
                return YES;
        }
        
        if((NSUInteger)location.y > 1) {
            tile1 = [self tileFromTileLocation:CGPointMake(location.x, location.y-1)];
            tile2 = [self tileFromTileLocation:CGPointMake(location.x, location.y-2)];
            if([self doTilesMatch:checkTile tile1:tile1 tile2:tile2] == YES)
                return YES;
        }
        
        //-- Check Horizontal
        if(((NSUInteger)location.x+2) < currentGridWidth) {
            tile1 = [self tileFromTileLocation:CGPointMake(location.x+2, location.y)];
            tile2 = [self tileFromTileLocation:CGPointMake(location.x+1, location.y)];
            if ([self doTilesMatch:checkTile tile1:tile1 tile2:tile2] == YES) {
                return YES;
            }
        }
        
        if((NSUInteger)location.x > 1) {
            tile1 = [self tileFromTileLocation:CGPointMake(location.x-2, location.y)];
            tile2 = [self tileFromTileLocation:CGPointMake(location.x-1, location.y)];
            if ([self doTilesMatch:checkTile tile1:tile1 tile2:tile2] == YES) {
                return YES;
            }
        }
        if((NSUInteger)location.x > 0 && (NSUInteger)location.x < (currentGridWidth-1)) {
            tile1 = [self tileFromTileLocation:CGPointMake(location.x+1, location.y)];
            tile2 = [self tileFromTileLocation:CGPointMake(location.x-1, location.y)];
            if ([self doTilesMatch:checkTile tile1:tile1 tile2:tile2] == YES) {
                return YES;
            }
        }
        
    }
    
    //-- Undo the swap, we failed.
    [self setTile:tileA atLocation:tileALocation];
    [self setTile:tileB atLocation:tileBLocation];
    return NO;
}

@end
