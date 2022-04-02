//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick

#define BRICK_POS_X            400
#define BRICK_POS_Y            500
#define BRICK_WIDTH            150.0f
#define BRICK_HEIGHT        10.0f
#define BRICK_WAIT            1.5f
#define BALL_POS_X            400
#define BALL_POS_Y            300
#define BALL_RADIUS            10.0f
#define BALL_VELOCITY        100000.0f
#define BALL_SPHERE_SEGS    128
#define BRICK1_POS_X            400
#define BRICK1_POS_Y            100

@interface CBox2D : NSObject 

-(void) HelloWorld; // Basic Hello World! example from Box2D

-(void) LaunchBall;                 // launch the ball
-(void) Update:(float)elapsedTime;  // update the Box2D engine
-(void) RegisterHit;                // Register when the ball hits the brick
-(void *)GetObjectPositions;        // Get the positions of the ball and brick

@end

#endif
