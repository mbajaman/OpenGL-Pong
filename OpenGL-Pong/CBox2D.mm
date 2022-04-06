//
//  Copyright © Borna Noureddin. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <stdio.h>
#include <string>
#include <map>

// Some Box2D engine paremeters
const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;


#pragma mark - Box2D contact listener class

// This C++ class is used to handle collisions
class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState) {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            CBox2D* parentObj = (__bridge CBox2D *)(bodyA->GetUserData());
            // Call RegisterHit (assume CBox2D object is in user data)
            [parentObj RegisterHit]; //asumed its a callback function
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};


#pragma mark - CBox2D

@interface CBox2D ()
{
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    b2BodyDef *groundBodyDef;
    b2Body *groundBody;
    b2PolygonShape *groundBox;
    b2Body *Paddle1, *Paddle2, *theBall;
    b2Body *EWall, *WWall;
    CContactListener *contactListener;
    float totalElapsedTime;
    
    float Paddle1_POS_X, Paddle1_POS_Y;
    float Paddle2_POS_X, Paddle2_POS_Y;

    // You will also need some extra variables here for the logic
    bool ballHitBrick;
    bool ballLaunched;
    
    int Player1Score, Player2Score;
}
@end

@implementation CBox2D

@synthesize Paddle1_POS_X;
@synthesize Paddle2_POS_X;

- (instancetype)init //This is replacement for Hello World
{
    self = [super init];
    if (self) {
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, 0.0f);
        world = new b2World(*gravity);
        
        // For HelloWorld
        groundBodyDef = NULL;
        groundBody = NULL;
        groundBox = NULL;

        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the brick and ball objects for Box2D
        b2BodyDef Paddle1BodyDef; //Brick Definition
        Paddle1BodyDef.type = b2_dynamicBody;
        Paddle1_POS_X = 400.0f;
        Paddle1_POS_Y = 500.0f;
        Paddle1BodyDef.position.Set(Paddle1_POS_X, Paddle1_POS_Y);
        Paddle1 = world->CreateBody(&Paddle1BodyDef);
        
        //Set up initial scores
        Player1Score = 0;
        Player2Score = 0;
        
        
        // Set up the brick and ball objects for Box2D
        b2BodyDef Paddle2BodyDef; //Brick Definition
        Paddle2BodyDef.type = b2_dynamicBody;
        Paddle2_POS_X = 400.0f;
        Paddle2_POS_Y = 100.0f;
        Paddle2BodyDef.position.Set(Paddle2_POS_X, Paddle2_POS_Y);
        Paddle2 = world->CreateBody(&Paddle2BodyDef);
        
        // Set up the east wall
        b2BodyDef EWallBodyDef;
        EWallBodyDef.type = b2_dynamicBody;
        EWallBodyDef.position.Set(EWALL_POS_X, EWALL_POS_Y);
        EWall = world->CreateBody(&EWallBodyDef);
        
        // Set up the west wall
        b2BodyDef WWallBodyDef;
        WWallBodyDef.type = b2_dynamicBody;
        WWallBodyDef.position.Set(WWALL_POS_X, WWALL_POS_Y);
        WWall = world->CreateBody(&WWallBodyDef);
        
        if(Paddle1){
            Paddle1->SetUserData((__bridge void *)self);
            Paddle1->SetAwake(false);
            
            Paddle2->SetUserData((__bridge void *)self);
            Paddle2->SetAwake(false);
            
            EWall->SetUserData((__bridge void *)self);
            EWall->SetAwake(false);
            
            WWall->SetUserData((__bridge void *)self);
            WWall->SetAwake(false);
            
            //Shape
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            
            //East Wall Shape
            b2PolygonShape eWallDynamicBox;
            eWallDynamicBox.SetAsBox(EWALL_WIDTH/2, EWALL_HEIGHT/2);
            
            //East Wall Shape
            b2PolygonShape wWallDynamicBox;
            wWallDynamicBox.SetAsBox(WWALL_WIDTH/2, WWALL_HEIGHT/2);
            
            //Fixtures
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 100.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;
            Paddle1->CreateFixture(&fixtureDef);
            
            b2FixtureDef fixtureDef1;
            fixtureDef1.shape = &dynamicBox;
            fixtureDef1.density = 100.0f;
            fixtureDef1.friction = 0.0f;
            fixtureDef1.restitution = 1.0f;
            Paddle2->CreateFixture(&fixtureDef1);
            
            b2FixtureDef EWallfixture;
            EWallfixture.shape = &eWallDynamicBox;
            EWallfixture.density = 100.0f;
            EWallfixture.friction = 0.0f;
            EWallfixture.restitution = 1.0f;
            EWall->CreateFixture(&EWallfixture);
            
            b2FixtureDef WWallfixture;
            WWallfixture.shape = &wWallDynamicBox;
            WWallfixture.density = 100.0f;
            WWallfixture.friction = 0.0f;
            WWallfixture.restitution = 1.0f;
            WWall->CreateFixture(&WWallfixture);
            
            b2BodyDef ballBodyDef; //ball Defintion
            ballBodyDef.type = b2_dynamicBody;
            ballBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
            theBall = world->CreateBody(&ballBodyDef);
            
            if(theBall){
                theBall->SetUserData((__bridge void *)self);
                theBall->SetAwake(false);
                
                //Shape
                b2CircleShape circle;
                circle.m_p.Set(0, 0);
                circle.m_radius = BALL_RADIUS;
                
                //Fixtures
                b2FixtureDef circleFixtureDef;
                circleFixtureDef.shape = &circle;
                circleFixtureDef.density = 1.0f;
                circleFixtureDef.friction = 0.0f;
                circleFixtureDef.restitution = 1.0f;
                theBall->CreateFixture(&circleFixtureDef);
            }
        }
        
        //Initialize more variables
        totalElapsedTime = 0;
        ballHitBrick = false;
        ballLaunched = false;
    }
    return self;
}

- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (groundBodyDef) delete groundBodyDef;
    if (groundBox) delete groundBox;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    theBall->SetActive(true); //makes it part of the simulation otherwise its just sitting there
    EWall->SetActive(true);
    WWall->SetActive(true);
    
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if(ballLaunched) {
        float r = arc4random_uniform(BALL_VELOCITY);
        float d = arc4random_uniform(2);
        printf("\nDirection: %f\n", d);
        printf("Impulse: %f", r);
        if(d){
            theBall->ApplyLinearImpulse(b2Vec2(r, BALL_VELOCITY), theBall->GetPosition(), true);
        } else {
            theBall->ApplyLinearImpulse(b2Vec2(-r, -100000.0f), theBall->GetPosition(), true);
        }
        
        theBall->SetActive(true);
#ifdef LOG_TO_CONSOLE
        NSLog(@"Applying impulse %f to ball\n", BALL_VELOCITY);
#endif
        ballLaunched = false;
    }
    
    // Check if it is time yet to drop the brick, and if so
    //  call SetAwake()
    totalElapsedTime += elapsedTime;
    if((totalElapsedTime > BRICK_WAIT) && Paddle1 && Paddle2){
        Paddle1->SetAwake(true);
        Paddle2->SetAwake(true);
        
        //theBall->ApplyForce(b2Vec2(10, -10), theBall->GetPosition(), true);
    }
    
    // If the last collision test was positive,
    //  stop the ball and destroy the brick
    if(ballHitBrick){
        //theBall->SetLinearVelocity(b2Vec2(0, 0));
        //theBall->SetAngularVelocity(0);
        //theBall->SetActive(false);
        printf("BALL HIT BRICK");
        float r = arc4random_uniform(BALL_VELOCITY);
        theBall->ApplyLinearImpulse(b2Vec2(r, BALL_VELOCITY), theBall->GetPosition(), true);
        //world->DestroyBody(theBrick);
        //theBrick = NULL;
        ballHitBrick = false;
    }

    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
            
            if(Paddle2_POS_X < 675 && Paddle2_POS_X > 125) {
                Paddle2->SetTransform(b2Vec2(Paddle2_POS_X, Paddle2_POS_Y), 0);
            }
            if(Paddle1_POS_X < 675 && Paddle1_POS_X > 125) {
                Paddle1->SetTransform(b2Vec2(Paddle1_POS_X, Paddle1_POS_Y), 0);
            }
            
            if(theBall->GetPosition().y < 0){
                Player1Score++;
                theBall->SetTransform(b2Vec2(400, 300), 0);
                theBall->SetLinearVelocity(b2Vec2(0, 0));
                std::string Player1Score_Str = std::to_string(Player1Score);
                std::string Player2Score_Str = std::to_string(Player2Score);
                printf("\n\nScore\n Player 1: %d\n Player 2: %d",Player1Score, Player2Score);
            } else if (theBall->GetPosition().y > 600) {
                Player2Score++;
                theBall->SetTransform(b2Vec2(400, 300), 0);
                theBall->SetLinearVelocity(b2Vec2(0, 0));
                std::string Player1Score_Str = std::to_string(Player1Score);
                std::string Player2Score_Str = std::to_string(Player2Score);
                printf("\n\nScore\n Player 1: %d\n Player 2: %d",Player1Score, Player2Score);
            }
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
    }
}

-(void)RegisterHit
{
    // Set some flag here for processing later...
    ballHitBrick = true;
}

-(void)LaunchBall
{
    // Set some flag here for processing later...
    ballLaunched = true;
}

-(void *)GetObjectPositions
{
    auto *objPosList = new std::map<const char *,b2Vec2>;
    if (theBall)
        (*objPosList)["ball"] = theBall->GetPosition();
    if (Paddle1)
        (*objPosList)["paddle1"] = Paddle1->GetPosition();
    if (Paddle2)
        (*objPosList)["paddle2"] = Paddle2->GetPosition();
    if (EWall)
        (*objPosList)["ewall"] = EWall->GetPosition();
    if (WWall)
        (*objPosList)["wwall"] = WWall->GetPosition();
    return reinterpret_cast<void *>(objPosList);
}

-(int) GetPlayer1Score {
    //char player1ScoreChar = Player1Score + '0';
    return Player1Score;
}

-(int) GetPlayer2Score {
    return Player2Score;
}

-(void)HelloWorld //This is a test where you setup the world and generate numbers. A dynamic box is falling down here.
{
    groundBodyDef = new b2BodyDef;
    groundBodyDef->position.Set(0.0f, -10.0f);
    groundBody = world->CreateBody(groundBodyDef);
    groundBox = new b2PolygonShape;
    groundBox->SetAsBox(50.0f, 10.0f);
    
    groundBody->CreateFixture(groundBox, 0.0f);
    
    // Define the dynamic body. We set its position and call the body factory.
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(0.0f, 4.0f);
    b2Body* body = world->CreateBody(&bodyDef);
    
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(1.0f, 1.0f);
    
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    
    // Set the box density to be non-zero, so it will be dynamic.
    fixtureDef.density = 1.0f;
    
    // Override the default friction.
    fixtureDef.friction = 0.3f;
    
    // Add the shape to the body.
    body->CreateFixture(&fixtureDef);
    
    // Prepare for simulation. Typically we use a time step of 1/60 of a
    // second (60Hz) and 10 iterations. This provides a high quality simulation
    // in most game scenarios.
    float32 timeStep = 1.0f / 60.0f;
    int32 velocityIterations = 6;
    int32 positionIterations = 2;
    
    // This is our little game loop.
    for (int32 i = 0; i < 60; ++i)
    {
        // Instruct the world to perform a single step of simulation.
        // It is generally best to keep the time step and iterations fixed.
        world->Step(timeStep, velocityIterations, positionIterations);
        
        // Now print the position and angle of the body.
        b2Vec2 position = body->GetPosition();
        float32 angle = body->GetAngle();
        
        printf("%4.2f %4.2f %4.2f\n", position.x, position.y, angle);
    }
}

@end
