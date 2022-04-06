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

#define BRICK_POS_X         400
#define BRICK_POS_Y         500
#define BRICK_WIDTH         150.0f
#define BRICK_HEIGHT        10.0f
#define BRICK_WAIT          1.5f

#define BALL_POS_X          400
#define BALL_POS_Y          300
#define BALL_RADIUS         10.0f
#define BALL_VELOCITY       100000.0f
#define BALL_SPHERE_SEGS    128

#define EWALL_POS_X         775
#define EWALL_POS_Y         400
#define EWALL_WIDTH         40.0f
#define EWALL_HEIGHT        800.0f

#define WWALL_POS_X         25
#define WWALL_POS_Y         400
#define WWALL_WIDTH         40.0f
#define WWALL_HEIGHT        800.0f


@interface CBox2D : NSObject

@property float Paddle1_POS_X;
@property float Paddle2_POS_X;

-(void) HelloWorld; // Basic Hello World! example from Box2D

-(void) LaunchBall;                 // launch the ball
-(void) Update:(float)elapsedTime;  // update the Box2D engine
-(void) RegisterHit;                // Register when the ball hits the brick
-(void *)GetObjectPositions;        // Get the positions of the ball and brick
-(int) GetPlayer1Score;
-(int) GetPlayer2Score;

@end

#endif
