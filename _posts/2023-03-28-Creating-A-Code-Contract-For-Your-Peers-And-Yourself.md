---
layout: post
title: Creating a Code Contract for Your Peers (and Yourself)
categories: [bdd, republished, testing]
---

*A Special Note From Right Now: I originally wrote this piece for publishing on the [Elevator Up Blog](https://elevatorupcompany.tumblr.com/post/83421542100/i-shot-a-bug-in-reno-or-how-i-learned-to-stop-cowboy) exactly one million years ago. I'm reposting it here so I can more easily refer to it when I talk to my colleagues about testing philosophy and because the Elevator Up stylesheet went away when Elevator Up was acquired.*

## I Shot A Bug In Reno ##

Okay, so, I have a confession to make: I’m a loose cannon cowboy coder at heart …

![torches and pitchforks](https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExM2ZjYWFkNjM2NDIzYzJjYWNmZDgzMDIyNGU5MjY5ZDY2NTRlNGZjMCZjdD1n/8PfKWm6AX1IdDRARyg/giphy.gif)

Whoa, hold on now. Let me finish my thought. I’m a loose cannon cowboy coder at heart, and that is specifically why I am a fairly pedantic tester. Which doesn’t really make any sense at all.

## Except It Totally Does ##

So, why is it that my testing practice flies in the face of my nature, and why does that make sense? I recognize that I like to shoot from the hip, and I also know that shooting from the hip is a terrible way to actually hit one’s target. It’s also a pretty good way to generate a headline containing “friendly fire.”

What do I mean by that?

## Tests are contracts ##

It wasn’t until after I started writing code that other people had to use and maintain that I started looking seriously at automated testing. The non-reasons are pretty numerous, but they basically boil down to this:

* I had absolutely no idea what, where, and when to test.
* I was too arrogant to admit that.

Eventually, I swallowed my pride and forced myself to learn about testing in order to lessen the burden of answering questions about my code. There are a lot of benefits to behavior-driven development, but I’m only going to talk about one aspect of the beast today:

> A test is the contract I make with other developers that use my code. It expresses the intended behavior of the code in question, and it also describes the intended usage.

Say that I provide a developer with some awesome, clever class that does its job really well, but doesn’t have an associated set of tests. I’ve left the following questions unanswered:

* Does it work?
* How do you know it works?
* What does this bit right here do?
* How do I use this crazy thing?

Developer sorts are generally really bad at admitting that they don’t understand what something does. So, instead of asking, the person receiving my code is probably going to burn entirely too many calories trying to digest it. They are probably going to fill up the swear jar, too.

On the other hand, what if I had provided tests for the code? Then the recipient can read the behavior description to find out the answers to all of those questions. Effectively, without ever looking at the actual code, they can treat it as a black box and start using it.

## But Wait, There’s More ##

Really, behavior tests are all about testing the side-effects of the code that we write. The simplest tests look like this:

1. Set preconditions
2. Run the code
3. Verify the expected postconditions

That’s pretty handy information to have, but for the bonus round, simply providing a test means that you’re generating a meta-side-effect: There is now a clear boundary/seam for stubbing. That might not sound very handy in itself, but let’s think about that for a moment.

As mentioned previously, the tested code I provided is now a black box with a defined API, and the black box in our scenario takes a very long time to do its thing. When new code is written that depends on that black box, that means that the test for the new code will take forever based solely on the black box taking forever. THAT means that it takes the developer writing this new code forever to get feedback when they run their tests, which slows down the red-green-refactor cycle like crazy. But what is one to do?

The black box is already known to work, we know how to call it, and we know what kind of results it will return. That means we don’t actually have to use it … we can stub the box without compromising the integrity of the new code. That means that the tests for the new code should only take as long as it takes to run the new code. Using this technique in all of our tests means that we end up with a test suite that executes really quickly, and that means that we get to write more code better and faster.

## I Feel Better Now ##

Well, there’s my deep, dark secret. The confession has lifted a great weight from my chest, and it feels great that folks are more confident in using the code that I write these days. If you aren’t testing your code, I won’t say that you’re wrong (even though you totally are), but I do urge you to consider the burden that you are placing on your fellow developers and give it a shot. Drop us a line … maybe we can help.
