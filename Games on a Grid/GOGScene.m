#import "GOGScene.h"

@interface GOGScene ()
{
}

@end


@implementation GOGScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:1 green:1 blue:1 alpha:1.0];
        self.backgroundColor = [SKColor grayColor];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        
        canComputeEndofTurn = false;
        bonusMult = 1;
        currentScore = 0;
        myLabel.text = [NSString stringWithFormat:@"Score: %lu", (unsigned long)currentScore];
        myLabel.fontSize = 30;
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMaxY(self.frame)-30);
        myLabel.fontColor = [SKColor blackColor];
        self.scoreLabel = myLabel;
        
        self.gridData = [self createGridWithSize:CGSizeMake(320, 320)
                                        tileData:@"ABABABBCBCBCCDCDCDDADADAABABABBCBCBC"
                                   rowColumnSize:CGSizeMake(6,6)
                                      gutterSize:5];
        
        
        SKTexture* blanketTexture = [self textureNamed:@"blanket_01.png"];
        
        int wide = (1024 / blanketTexture.size.width) + 1;
        int tall = (1024 / blanketTexture.size.height) + 1;
        for(int y = 0; y < tall; y++) {
            for(int x = 0; x < wide; x++) {
                SKSpriteNode* blanket = [SKSpriteNode spriteNodeWithTexture:blanketTexture];
                [self addChild:blanket];
                blanket.zPosition = -10.0f;
                blanket.position = CGPointMake((x*blanketTexture.size.width), (y*blanketTexture.size.height));
                [blanket setUserInteractionEnabled:NO];
                [blanket setName:@"blanket"];
            }
        }
        
        //- Bomb Animation
        self.bombFrames = [[NSMutableArray alloc] init];
        for(int i=1; i<=18; i++) {
            NSString* bombFrameName = [NSString stringWithFormat:@"bomb_%02d.png", i];
            SKTexture* frame = [self textureNamed:bombFrameName];
            [self.bombFrames addObject:frame];
        }
        SKAction* anim  = [SKAction animateWithTextures:self.bombFrames timePerFrame:1.0f/30.0f resize:NO restore:NO];
        self.bombAnim = anim;
    }
    return self;
}

- (void)logGrid {
    for(int y=0; y<currentGridHeight; y++) {
        NSString* line = nil;
        for(int x=0; x<currentGridWidth; x++) {
            unichar key = [[((SKNode*)self.gridData[(y*currentGridWidth)+x]).userData objectForKey:@"data"] unsignedShortValue];
            
            if(line == nil) {
                line = [NSString stringWithFormat:@"%@ ", [NSString stringWithCharacters:&key length:1]];
            }
            else {
                line = [NSString stringWithFormat:@"%@%@ ", line, [NSString stringWithCharacters:&key length:1]];
            }
        }
        NSLog(@"%@", line);
    }
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _currentTouch = nil;
}

-(void)update:(CFTimeInterval)currentTime {
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %lu", (unsigned long)currentScore];
}

-(void)didMoveToView:(SKView *)view {
    SKNode* root = [self childNodeWithName:@"gridroot"];
    CGPoint cur = root.position;
    root.position = CGPointMake(0, -1000);
    SKAction* moveAction = [SKAction moveTo:cur duration:1.00f];
    moveAction.timingMode = SKActionTimingEaseInEaseOut;
    [root runAction:moveAction];
    
    
    cur = self.scoreLabel.position;
    self.scoreLabel.position = CGPointMake(cur.x, 1000);
    SKAction* labelMoveAction = [SKAction moveTo:cur duration:1.00f];
    labelMoveAction.timingMode = SKActionTimingEaseInEaseOut;
    [self.scoreLabel runAction:labelMoveAction];
}


-(void)removeTile:(CGPoint)tileLocation {
    
    canComputeEndofTurn = NO;
    SKNode* tileToRemove = [self tileFromTileLocation:tileLocation];
    if (tileToRemove == nil) {
        NSLog(@"bad tileLocation = (%lu, %lu)", (unsigned long)tileLocation.x, (unsigned long)tileLocation.y);
        return;
    }
    
    tileToRemove.zPosition = 2.0f;
    [tileToRemove removeFromParent];
    
    //-- score++
    NSInteger y = (NSInteger)tileLocation.y;
    while(y >= 0) {
        SKNode* tileToMove = [self tileFromTileLocation:CGPointMake(tileLocation.x, y-1)];
        CGPoint endLocation = CGPointMake(tileLocation.x, y);
        if(tileToMove == nil) {
            //-- create a new random tile
            tileToMove = [self createTileWithKey:[self randomTileKey] width:currentTileWidth height:currentTileHeight];
            tileToMove.position = [self boardLocationFromTileLocation:CGPointMake(tileLocation.x, -2)];
            [[self childNodeWithName:@"gridroot"] addChild:tileToMove];
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

-(SKAction*)createMoveActionWithTile:(SKNode*)tile toTileLocation:(CGPoint)tileLocation withSnapBack:(BOOL)snapBack{
    if(tile == nil)
        return nil;
    
    CGPoint boardLocation = [self boardLocationFromTileLocation:tileLocation];
    CGPoint curTileLocation = tile.position;
    
    SKAction* moveAction = [SKAction moveTo:boardLocation duration:0.15];
    moveAction.timingMode = SKActionTimingEaseInEaseOut;
    
    if(snapBack == YES) {
        SKAction* reverse = [SKAction moveTo:curTileLocation duration:0.15];
        return [SKAction sequence:@[moveAction, reverse]];
    }
    return moveAction;
}

-(void)moveTile:(SKNode*)tile toTileLocation:(CGPoint)tileLocation withSnapBack:(BOOL)snapBack{
    if(tile == nil)
        return;
    
    canComputeEndofTurn = NO;
    SKAction* action = [self createMoveActionWithTile:tile toTileLocation:tileLocation withSnapBack:snapBack];
    [tile runAction:action completion:^(){
        canComputeEndofTurn = YES;
    }];
    
}

-(CGPoint)boardLocationFromTileLocation:(CGPoint)tileLocation {
    CGFloat px = currentTileWidth*0.5f + currentGutterSize;
    CGFloat py = (currentTileHeight*0.5f + currentGutterSize) + ((currentTileHeight+currentGutterSize) * (currentGridHeight-1));
    
    return CGPointMake(px+(tileLocation.x*(currentTileWidth+currentGutterSize)),
                       py-(tileLocation.y*(currentTileHeight+currentGutterSize)));
}

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

-(SKNode*)tileFromTileLocation:(CGPoint)tileLocation {
    if(self.gridData == nil || tileLocation.x < 0 || tileLocation.y < 0)
        return nil;
    
    NSUInteger offset = ((NSUInteger)tileLocation.y * currentGridWidth) + (NSUInteger)tileLocation.x;
    if(self.gridData.count <= offset)
        return nil;
    
    return [self.gridData objectAtIndex:offset];
}

-(void)setTile:(SKNode*)tile atLocation:(CGPoint)tileLocation {
    if(self.gridData == nil)
        return;
    
    NSUInteger offset = ((NSUInteger)tileLocation.y * currentGridWidth) + (NSUInteger)tileLocation.x;
    if(self.gridData.count <= offset)
        return;
    
    self.gridData[offset] = tile;
}

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

-(NSMutableArray*)createGridWithSize:(CGSize)boardSize tileData:(NSString*)tileData rowColumnSize:(CGSize)rowColSize gutterSize:(CGFloat)gutterSize {
    
    //-- Get or Create the root node.
    SKNode* root = [self childNodeWithName:@"gridroot"];
    if(root == nil) {
        root = [SKNode node];
        [root setName:@"gridroot"];
        [self addChild:root];
    }
    
    //-- Clear out previous grid.
    [root removeAllChildren];
    root.position = CGPointMake(0, (self.size.height*0.5f)-(boardSize.height*0.5f));
    
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
    
    NSMutableArray* gridData = [[NSMutableArray alloc] initWithCapacity:currentGridWidth*currentGridHeight];
    
    for (int y=0; y<rowColSize.height; y++) {
        for (int x=0; x<rowColSize.width; x++) {
            unichar data = [tileData characterAtIndex:(y*currentGridWidth) + x];
            SKNode* tile = [self createTileWithKey:data width:currentTileWidth height:currentTileHeight];
            [root addChild:tile];
            
            tile.position = CGPointMake(px, py);
            
            px += (currentTileWidth + currentGutterSize);
            gridData[(int)(y*currentGridWidth) + x] = tile;
            
        }
        py -= (currentTileHeight + currentGutterSize);
        px = currentTileWidth*0.5f + currentGutterSize;
    }
    
    
    root.userData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                     tileData, @"tileData",
                     nil];
    
    return gridData;
}

-(SKNode*)createTileWithKey:(unichar)key width:(CGFloat)width height:(CGFloat)height {
    UIColor* tileColor = [SKColor whiteColor];
    SKTexture* texture = nil;
    CGFloat z = 0.0f;
    
    NSDictionary* table = @{@"A": @[@"apple_80.png", @1.0f, [SKColor redColor]],
                            @"B": @[@"blueberry_80.png", @2.0f, [SKColor blueColor]],
                            @"C": @[@"watermelon_80.png", @3.0f, [SKColor greenColor]],
                            @"D": @[@"kiwi_80.png", @4.0f, [SKColor brownColor]],
                            @"E": @[@"orange_80.png", @5.0f, [SKColor orangeColor]],
                            @"F": @[@"rainbow.png", @6.0f, [SKColor cyanColor]],
                            @"Z": @[@"coin_star_80.png", @7.0f, [SKColor yellowColor]]
                            };
    NSArray* data = [table objectForKey:[NSString stringWithCharacters:&key length:1]];
    if( data != nil) {
        texture = [self textureNamed:data[0]];
        z = [data[1] floatValue];
        tileColor = data[2];
    }
    
    SKSpriteNode* tile = [SKSpriteNode spriteNodeWithColor:tileColor size:CGSizeMake(width, height)];
    tile.texture = texture;
    tile.zPosition = z;
    tile.userData = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithUnsignedShort:key]
                                                       forKey:@"data"];
    
    return tile;
}

-(unichar)randomTileKey {
    NSString* tiles = @"ABCDE";
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


//view, interaction
-(BOOL)isBackgroundNode:(SKNode*)node {
    if(node == self)
        return YES;
    if(node == [self childNodeWithName:@"gridroot"])
        return YES;
    if(node.name == nil)
        return NO;
    
    if([node.name compare:@"blanket"] == NSOrderedSame)
        return YES;
    
    return NO;
}

-(SKTexture*)textureNamed:(NSString*)textureName {
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"art"];
    if(atlas == nil) {
        return [SKTexture textureWithImageNamed:textureName];
    }
    if([atlas.textureNames containsObject:textureName]) {
        return [atlas textureNamed:textureName];
    }
    return nil;
}
@end
