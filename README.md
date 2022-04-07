# OpenGL-Pong

This project shows off features of a game that are implemented in C++, Objective C, OpenGL, Box2D and Swift.

## Instructions
Run on iPhone 12 simulator via XCode.

## Features
- A ball that bounces off paddles and walls in a randomized direction within a specified range of angles
- The score system if the ball gets behind the paddles increases specified side's points by one
- Moving either the paddles left and right

## Controls
- Tap once to start the game (launches ball in a random direction)
- Pan left or right on the bottom half of the screen to move Player 2
- Pan left or right on the top half of the paddle to move Player 1

**Note: When attempting to move the paddle in the opposite direction the player must lift their finger off of the screen.**

## Problem
Implement a 2D iOS game that mimics Pong, using the Box2D library and OpenGL ES. You do not need to worry about a 100% faithful reproduction in terms of content, colours, levels, etc. Only the core game essence is required. Use your own drawing functions instead of the drawing systems or debug drawing of Box2D.

## Solution
1. Paddles are dynamic objects manipulated via touch and drag. Paddles move responsively.
2. Bounding walls were implemented on the sides which showcase the ball bouncing on the sides of the play area
3. Score is kept track of when ball leaves the screen on either end of the display. This is done by keeping track of the ball's position.
4. Score for both players is displayed at the top. OpenGL ES was used to render the text

