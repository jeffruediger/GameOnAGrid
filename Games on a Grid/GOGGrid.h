//
//  GOGGrid.h
//  Games on a Grid
//
//  Created by Jeff Ruediger on 1/6/14.
//  Copyright (c) 2014 Fuzzycube Software. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GOGGrid : SKNode

@property (nonatomic, strong) NSMutableArray* gridData;

@property (nonatomic, readonly) NSUInteger currentScore;

-(id)initWithSize:(CGSize)boardSize tileData:(NSString*)tileData rowColumnSize:(CGSize)rowColSize gutterSize:(CGFloat)gutterSize;

-(BOOL)tryMoveTile:(SKNode*)tile withDirection:(CGPoint)direction;

-(void)beginInput;
-(void)doUpdate;
@end
