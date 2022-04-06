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
class CContactListener : public b2ContactListener {
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold) {
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

@interface CBox2D () {
    b2Vec2 *gravity;
    b2World *world;
    b2BodyDef *groundBodyDef;
    b2Body *groundBody;
    b2PolygonShape *groundBox;
    b2Body *Paddle1, *Paddle2, *theBall; // Paddles and ball
    b2Body *EWall, *WWall;
    CContactListener *contactListener;
    float totalElapsedTime;
    
    float Paddle1_POS_X, Paddle1_POS_Y; // Paddle 1 position
    float Paddle2_POS_X, Paddle2_POS_Y; // Paddle 2 position

    // Logic
    bool ballHitPaddle;
    bool ballLaunched;
    
    //Scores
    int Player1Score, Player2Score;
}
@end

@implementation CBox2D

@synthesize Paddle1_POS_X;
@synthesize Paddle2_POS_X;

- (instancetype) init {
    self = [super init];
    
    if (self) {
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, 0.0f);
        world = new b2World(*gravity);
        
        //Set up initial scores
        Player1Score = 0;
        Player2Score = 0;

        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Paddle 1 setup
        b2BodyDef Paddle1BodyDef;
        Paddle1BodyDef.type = b2_dynamicBody;
        Paddle1_POS_X = 400.0f;
        Paddle1_POS_Y = 500.0f;
        Paddle1BodyDef.position.Set(Paddle1_POS_X, Paddle1_POS_Y);
        Paddle1 = world->CreateBody(&Paddle1BodyDef);
        
        // Paddle 2 setup
        b2BodyDef Paddle2BodyDef;
        Paddle2BodyDef.type = b2_dynamicBody;
        Paddle2_POS_X = 400.0f;
        Paddle2_POS_Y = 100.0f;
        Paddle2BodyDef.position.Set(Paddle2_POS_X, Paddle2_POS_Y);
        Paddle2 = world->CreateBody(&Paddle2BodyDef);
        
        // East wall setup
        b2BodyDef EWallBodyDef;
        EWallBodyDef.type = b2_dynamicBody;
        EWallBodyDef.position.Set(EWALL_POS_X, EWALL_POS_Y);
        EWall = world->CreateBody(&EWallBodyDef);
        
        // West wall setup
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
        ballHitPaddle = false;
        ballLaunched = false;
    }
    return self;
}

- (void)dealloc {
    if (gravity) delete gravity;
    if (world) delete world;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime {
    //Enable all objects
    Paddle1->SetAwake(true);
    Paddle2->SetAwake(true);
    theBall->SetActive(true);
    EWall->SetActive(true);
    WWall->SetActive(true);
    
    // Launch ball in random direction with random impulse
    if(ballLaunched) {
        float r = arc4random_uniform(BALL_VELOCITY);
        float d = arc4random_uniform(2);
        if(d){
            theBall->ApplyLinearImpulse(b2Vec2(r, BALL_VELOCITY), theBall->GetPosition(), true);
        } else {
            theBall->ApplyLinearImpulse(b2Vec2(-r, -100000.0f), theBall->GetPosition(), true);
        }
        theBall->SetActive(true);
        ballLaunched = false;
    }
    
    // Apply random impulse when ball hits paddle or walls
    if(ballHitPaddle){
        float r = arc4random_uniform(BALL_VELOCITY);
        theBall->ApplyLinearImpulse(b2Vec2(r, BALL_VELOCITY), theBall->GetPosition(), true);
        ballHitPaddle = false;
    }

    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
            
            // Set bounds for paddle movement
            if(Paddle2_POS_X < 675 && Paddle2_POS_X > 125) {
                Paddle2->SetTransform(b2Vec2(Paddle2_POS_X, Paddle2_POS_Y), 0);
            }
            if(Paddle1_POS_X < 675 && Paddle1_POS_X > 125) {
                Paddle1->SetTransform(b2Vec2(Paddle1_POS_X, Paddle1_POS_Y), 0);
            }
            
            // Reset the ball when Players score and increase the score
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

-(void)RegisterHit {
    ballHitPaddle = true;
}

-(void)LaunchBall {
    ballLaunched = true;
}

-(void *)GetObjectPositions {
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
    return Player1Score;
}

-(int) GetPlayer2Score {
    return Player2Score;
}

@end
