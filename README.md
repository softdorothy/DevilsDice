# DevilsDice
An iOS game from 2011.

![Screenshot](https://github.com/softdorothy/DevilsDice/blob/main/Screenshots/DevilsDice0.png)

## Pig ##

I first became interested in the dice game *Pig* when I read about two computer professors that had determined the optimal strategy to win the game. Their web site has an online version of the game as well as links to their paper. The paper goes deep into statistics and probability to arrive at their rather complex solution.

Pig itself however is a simple game for two players that requires only a single die and a piece of paper for keeping track of scores. 

A player begins their turn by rolling the die. If they roll a 1 their turn is over and the die is handed to their opponent. Any roll other than a 1 allows the player to continue their turn and add the points of the roll to a sort of temporary point total. The player may choose to roll again or stop at any time and allow their opponent to take their turn. It is only when a player relinquishes their turn that the temporary points become a part of their permanent score. The first player to 100 points wins.

The longer you go on rolling the die the larger your pool of points becomes, but you also increase the risk of rolling the dreaded 1 ... and then you lose all the  points accumulated for that turn. This is the risk element of the game. This is where probability and statistics matter.

I was not happy with either of the two versions of Pig that I found for the iPhone/iOS. For starters, when playing the game I wanted something visual that would show both player’s scores climbing closer and closer to the goal of 100 points.

The Devil’s Dice is my attempt to present the game of Pig in a manner that I hope captures the tension of the risk-taking element of the game.

## The Twilight Zone ##

Something about the creepy "devil" fortune telling machine in the original *Twilight Zone* episode "The Nick of Time" caught my fancy. (Google it if you are not familiar with it — an excellent episode featuring William Shatner.)

And then there are the infamous, mechanical, one-armed bandits...

Some hybrid of those two ideas explains the visuals for the game.

## Project ##

The application uses simple UIView’s for “sprites” and CocosDenshion for the sound. All animation is done either implicitly by using CoreAnimation or through explicitly changing the bounds or alpha of individual UIViews. For an arcade game with dozens of sprites and a quick frame-rate, using UIViews wouldn’t suffice. But for a simpler “parlor game” like The Devil’s Dice, using UIViews or CALayers makes a lot of sense.

Nonetheless I have found that, even with CALayers, the moment you start trying to use transforms (scaling, rotating) the performance can suffer considerably. If you can stick to translation and alpha animation, UIView/CALayers work well.

Without a sprite engine the code remains easy to learn and easy to find your way around the project quickly.

I tried to use more of a vanilla approach to sounds, but the performance wasn’t there ... the animation in the game became jittery when the sounds were playing. CocosDenshion is an extremely simple sound engine that ships as part of Cocos2D and did the job admirably. When a sound fires off using CocosDenshion, no slow noticeable slowdown in the animation.

There are three view controllers. RootViewController is the primary controller — most of the game state machine and logic are in here. The PlayViewController is brought up to display the game stats and handling the “Player vs. Devil” and “Player vs Player” buttons. The InfoViewController displays the rules and sound volume setting.

Touches for the large red “roll lever” and smaller red “turn lever” are tracked in RootViewController. The info button (in the lower right above) is wired in the standard way through the NIB file. There are no other user-interactions for the RootViewController.