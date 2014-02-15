#import <SpriteKit/SpriteKit.h>

@interface GOGScene : SKScene {
    NSUInteger  currentGridWidth;
    NSUInteger  currentGridHeight;
    NSUInteger  currentGutterSize;
    NSUInteger  currentBoardWidth;
    NSUInteger  currentBoardHeight;
    
    CGFloat     currentTileWidth;
    CGFloat     currentTileHeight;
    BOOL        canComputeEndofTurn;
    NSUInteger  bonusMult;
    NSUInteger  currentScore;

}

@property(strong) NSMutableArray* gridData;

@property (nonatomic, strong) NSMutableArray* touchedTiles;
@property (nonatomic, weak) UITouch* currentTouch;
@property (nonatomic, strong) SKLabelNode* scoreLabel;
@property (nonatomic, strong) NSMutableArray* bombFrames;
@property (nonatomic, strong) SKAction* bombAnim;

- (void)logGrid;
- (BOOL)isBackgroundNode:(SKNode*)node;

- (unsigned short)keyForTileLocation:(CGPoint)tileLocation;
- (unsigned short)keyForTile:(SKNode*)tile;

- (SKNode*)tileFromTileLocation:(CGPoint)tileLocation;
- (void)removeTile:(CGPoint)tileLocation;
- (void)setTile:(SKNode*)tile atLocation:(CGPoint)tileLocation;

- (CGPoint)locationOfTile:(SKNode*)tile;

- (void)moveTile:(SKNode*)tile toTileLocation:(CGPoint)tileLocation withSnapBack:(BOOL)snapBack;

- (SKAction*)createMoveActionWithTile:(SKNode*)tile toTileLocation:(CGPoint)tileLocation withSnapBack:(BOOL)snapBack;
- (BOOL)doTilesMatch:(SKNode*)tileA tile1:(SKNode*)tile1 tile2:(SKNode*)tile2;

@end
