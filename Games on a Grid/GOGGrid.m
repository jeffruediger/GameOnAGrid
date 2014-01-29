//
//  GOGGrid.m
//  Games on a Grid
//
//  Created by Jeff Ruediger on 1/6/14.
//  Copyright (c) 2014 Fuzzycube Software. All rights reserved.
//

#import "GOGGrid.h"

@interface GOGGrid ()
{
    NSUInteger  currentGridWidth;
    NSUInteger  currentGridHeight;
    NSUInteger  currentGutterSize;
    NSUInteger  currentBoardWidth;
    NSUInteger  currentBoardHeight;
    
    CGFloat     currentTileWidth;
    CGFloat     currentTileHeight;
    BOOL        canComputeEndofTurn;
    NSUInteger  bonusMult;
}

@end

@implementation GOGGrid

-(id)initWithSize:(CGSize)boardSize tileData:(NSString*)tileData rowColumnSize:(CGSize)rowColSize gutterSize:(CGFloat)gutterSize {
    
    self = [super init];
    if(self == nil)
        return nil;
    
    [self setName:@"gridroot"];
    
    _currentScore = 0;
    bonusMult = 1;
    canComputeEndofTurn = false;
    
    //-- Clear out previous grid.
    [self removeAllChildren];
    //self.position = CGPointMake(0, (self.size.height*0.5f)-(boardSize.height*0.5f));
    
    if(tileData.length < (rowColSize.width*rowColSize.height)) {
        NSLog(@"tileData.length needs more data, given the rowColSize");
        return nil;
    }
    
    if(rowColSize.width < 1 || rowColSize.height < 1) {
        NSLog(@"rowColSize needs to be at least 1 in both directions");
        return nil;
    }
    
    currentBoardHeight = boardSize.height;
    currentBoardWidth = boardSize.width;
    currentGridHeight = rowColSize.height;
    currentGridWidth = rowColSize.width;
    currentGutterSize = gutterSize;
    
    currentTileWidth = (currentBoardWidth - ((currentGridWidth+1) * currentGutterSize)) / currentGridWidth;
    currentTileHeight = (currentBoardHeight - ((currentGridHeight+1) * currentGutterSize)) / currentGridHeight;
    
    CGFloat px = currentTileWidth*0.5f + currentGutterSize;
    CGFloat py = (currentTileHeight*0.5f + currentGutterSize) + ((currentTileHeight+currentGutterSize) * (currentGridHeight-1));
    
    self.gridData = [[NSMutableArray alloc] initWithCapacity:currentGridWidth*currentGridHeight];
    
    for (int y=0; y<rowColSize.height; y++) {
        for (int x=0; x<rowColSize.width; x++) {
            unichar data = [tileData characterAtIndex:(y*currentGridWidth) + x];
            SKNode* tile = [self createTileWithKey:data width:currentTileWidth height:currentTileHeight];
            [self addChild:tile];
            
            tile.position = CGPointMake(px, py);
            
            px += (currentTileWidth + currentGutterSize);
            self.gridData[(int)(y*currentGridWidth) + x] = tile;
            
        }
        py -= (currentTileHeight + currentGutterSize);
        px = currentTileWidth*0.5f + currentGutterSize;
    }
    
    
    self.userData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                     tileData, @"tileData",
                     nil];
    
    return self;
}

-(SKNode*)createTileWithKey:(unichar)key width:(CGFloat)width height:(CGFloat)height {
    UIColor* tileColor = [UIColor whiteColor];
    SKTexture* texture = nil;
    CGFloat zPos = 0.0f;
    switch (key) {
        case 'A':
            tileColor = [UIColor yellowColor];
            break;
        case 'B':
            tileColor = [UIColor blueColor];
            break;
        case 'C':
            tileColor = [UIColor cyanColor];
            break;
        case 'D':
            tileColor = [UIColor redColor];
            break;
        case 'E':
            tileColor = [UIColor purpleColor];
            break;
        case 'F':
            tileColor = [UIColor orangeColor];
            break;
        case 'Z':
            texture = [SKTexture textureWithImageNamed:@"Spaceship"];
            zPos = 1.0f;
            break;
        default:
            break;
    }
    
    SKSpriteNode* tile = [SKSpriteNode spriteNodeWithColor:tileColor size:CGSizeMake(width, height)];
    tile.texture = texture;
    tile.zPosition = zPos;
    
    tile.userData = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithUnsignedShort:key]
                                                       forKey:@"data"];
    
    return tile;
}

//controller
-(void)endOfTurn {
    //--match3
    //-- walk the board, bottom to top, removing matches, inserting new objects, until the board
    //-- has no more matches.
    
    //-- remove tiles.
    //-- fill tiles.
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
                bonusMult*=(total-2);
                //-- Found a match, remove those tiles, move tiles down.
                for(int a = leftX; a<=rightX; a++) {
                    _currentScore+=(bonusMult);
                    [self removeTile:CGPointMake(a,y)];
                }
                bonusMult++;
                return;
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
                bonusMult*=(total-2);
                //-- Found a match, remove those tiles, move tiles down.
                for(int a = topY; a<=bottomY; a++) {
                    _currentScore+=(bonusMult);
                    [self removeTile:CGPointMake(x,a)];
                }
                bonusMult++;
                return;
            }
            
        }
    }
    
}
//match3 controller
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


-(void)removeTile:(CGPoint)tileLocation {
    [self.gridData[((NSUInteger)tileLocation.y*currentGridWidth) + (NSUInteger)tileLocation.x] removeFromParent];
    //-- score++
    
    NSInteger y = (NSInteger)tileLocation.y;
    while(y >= 0) {
        SKNode* tileToMove = [self tileFromTileLocation:CGPointMake(tileLocation.x, y-1)];
        CGPoint endLocation = CGPointMake(tileLocation.x, y);
        //NSLog(@"RT: (%d,%d) to (%d,%d)", tileLocation.x, y-1, tileLocation.x, y);
        if(tileToMove == nil) {
            //-- create a new random tile
            tileToMove = [self createTileWithKey:[self randomTileKey] width:currentTileWidth height:currentTileHeight];
            tileToMove.position = [self boardLocationFromTileLocation:CGPointMake(tileLocation.x, -2)];
            [self addChild:tileToMove];
        }
        
        //-- update the visual
        [self moveTile:tileToMove
        toTileLocation:endLocation
          withSnapBack:NO];
        
        //-- update the model
        [self setTile:tileToMove atLocation:endLocation];
        
        y--;
    }
}

//view
-(void)moveTile:(SKNode*)tile toTileLocation:(CGPoint)tileLocation withSnapBack:(BOOL)snapBack {
    if(tile == nil)
        return;
    
    canComputeEndofTurn = NO;
    
    CGPoint boardLocation = [self boardLocationFromTileLocation:tileLocation];
    CGPoint currentTileLocatoin = tile.position;
    //NSLog(@"moveTile from (%.2f, %.2f) to (.%2f, %.2f)", currentTileLocatoin.x, currentTileLocatoin.y, boardLocation.x, boardLocation.y);
    SKAction* moveAction = [SKAction moveTo:boardLocation duration:0.15];
    moveAction.timingMode = SKActionTimingEaseInEaseOut;
    SKAction* reverse = [SKAction moveTo:currentTileLocatoin duration:0.15];
    if(snapBack == YES) {
        [tile runAction:[SKAction sequence:@[moveAction, reverse]] completion:^(void){
            canComputeEndofTurn = YES;
        }];
    }
    else {
        [tile runAction:moveAction completion:^(void){
            canComputeEndofTurn = YES;
        }];
    }
}

//view
-(CGPoint)boardLocationFromTileLocation:(CGPoint)tileLocation {
    CGFloat px = currentTileWidth*0.5f + currentGutterSize;
    CGFloat py = (currentTileHeight*0.5f + currentGutterSize) + ((currentTileHeight+currentGutterSize) * (currentGridHeight-1));
    
    return CGPointMake(px+(tileLocation.x*(currentTileWidth+currentGutterSize)),
                       py-(tileLocation.y*(currentTileHeight+currentGutterSize)));
}

///match3 rules
-(unsigned short)keyForTile:(SKNode*)tile {
    return [[tile.userData objectForKey:@"data"] unsignedShortValue];
}

-(unsigned short)keyForTileLocation:(CGPoint)tileLocation {
    return [[[self tileFromTileLocation:tileLocation].userData objectForKey:@"data"] unsignedShortValue];
}

-(BOOL)doTilesMatch:(SKNode*)tileA tile1:(SKNode*)tile1 tile2:(SKNode*)tile2 {
    if(tileA == nil || tile1 == nil || tile2 == nil)
        return NO;
    
    unsigned short k = [self keyForTile:tileA];
    unsigned short k1 = [self keyForTile:tile1];
    unsigned short k2 = [self keyForTile:tile2];
    if( (k == k1) && (k == k2)) {
        return YES;
    }
    return NO;
}

//match3 rules
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

//model
-(SKNode*)tileFromTileLocation:(CGPoint)tileLocation {
    if(self.gridData == nil || tileLocation.x < 0 || tileLocation.y < 0)
        return nil;
    
    NSUInteger offset = ((NSUInteger)tileLocation.y * currentGridWidth) + (NSUInteger)tileLocation.x;
    if(self.gridData.count <= offset)
        return nil;
    
    return [self.gridData objectAtIndex:offset];
}

//model
-(void)setTile:(SKNode*)tile atLocation:(CGPoint)tileLocation {
    if(self.gridData == nil)
        return;
    
    NSUInteger offset = ((NSUInteger)tileLocation.y * currentGridWidth) + (NSUInteger)tileLocation.x;
    if(self.gridData.count <= offset)
        return;
    
    self.gridData[offset] = tile;
    //NSLog(@"setTile %d at (%d, %d)", [[tile.userData objectForKey:@"data"] integerValue], (int)tileLocation.x, (int)tileLocation.y);
}

//model
-(CGPoint)locationOfTile:(SKNode*)tile {
    if(tile == nil)
        return CGPointMake(-1, -1);
    
    NSUInteger offset = [self.gridData indexOfObject:tile];
    if(offset == NSNotFound) {
        return CGPointMake(-1, -1);
    }
    
    NSUInteger y = offset / currentGridWidth;
    NSUInteger x = offset % currentGridWidth;
    return CGPointMake(x, y);
}

//view from model
-(unichar)randomTileKey {
    NSString* tiles = @"ABCDEFZ";
    int r = 0;
    if((rand() % 100) > 50)
    {
        r = rand() % tiles.length;
    }
    else {
        r = rand() % (tiles.length-1);
    }
    
    
    return [tiles characterAtIndex:r];
}

-(BOOL)doesTile:(SKNode*)tileA equal:(SKNode*)tileB {
    if(tileA == nil || tileB == nil)
        return NO;
    
    unsigned short keyA = [[tileA.userData objectForKey:@"data"] unsignedShortValue];
    unsigned short keyB = [[tileB.userData objectForKey:@"data"] unsignedShortValue];
    if(keyA == keyB)
        return YES;
    
    return NO;
}

-(void)beginInput {
    bonusMult = 1;
}

-(void)doUpdate {
    if(canComputeEndofTurn == YES) {
        [self endOfTurn];
    }
}
@end
