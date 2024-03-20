---
layout: post
title: Pleasant Workflows
categories: [ruby, workflows, dry-rb, fp, testing]
---

I just stumbled upon [a Reddit post asking about dry-rb](https://www.reddit.com/r/rails/comments/1bjjgi4/whats_the_deal_with_dryrb/). It made me think about how much I enjoy some of the dry-rb gems, and specifically [dry-transaction](https://dry-rb.org/gems/dry-transaction/). Somebody asked about why that specific gem is so neat, so I figured I'd saunter over here and answer that question (without paying any regard to the fact that I haven't written anything in about a year).

## What's it all about? ##

In short, dry-transaction is a neat little gem that provides one a way to do Railway-Oriented Programming in Ruby. What that really means is somewhat complicated, so let's gloss over some of that.

A Railway is a process made up of several steps, any of which are allowed to fail. The analogy generally used to describe a railway is, well, a railway. Once you set a train in motion, each junction in the track allows you to follow one of two paths.

In the case of a ROP railway, you get the Right (success) path that continues on to the next junction or the Left (failure) path that halts the malfunctioning tran so it can do no more damage.

## That sounds a lot like an iterative program. ##

Well, it more or less is an iterative program, but with a bit of a twist in the context of dry-transaction. The twist, simply, is that it's presented in a very convenient package that lends itself well to testing. There are some more advanced concepts exposed by dry-transaction, but for the purposes of this description, we're going to pretend that only the raw basics are a thing.

A Transaction (the dry-transaction name for a Railway) is constructed of steps via a class-level DSL, passing the output of one step in as the input to its subsequent step. Each of these steps can be implemented either directly in the transaction as instance methods or as wholly separate operations. Regardless of how a step is implemented, these must all be true:

* A step must receive an input. It can be of any type at all, but a popular choice is a `Hash`.
* A step must return a `Success` (wrapping a value to be used later) or a `Failure` (to explain why the transaction failed), which are the value types of dry-monad's `Result` type.

When a Transaction is executed, it tries to execute each of the steps in order, passing the unwrapped output of a successful step as the input of the step that follows. If any step should fail, the whole process is halted and that failure is returned so the caller may react to it.

This makes the execution of complex workflows rather convenient in that you don't have to define that process and all of the error handling around it yourself. It's not incredibly difficult to do all of this the Hard Way (TM), but it is definitely tedious, and I think we can all agree that we have better things to do with our lives.

## But how is that good for testing? ##

I did mention that the gem lends itself well to testing. You caught me trying to hand-wave things. Go you!

I see two major benefits to testing when working with dry-transaction and libraries like it. The first of these is that of a lower surface area. Consider this method:

```ruby
def workifier
  random = SuperRandomInt.generate

  if random % 2 != 0
    raise "odd values are totally uncooth"
  end

  random * 2
end

# Subsequent usage
begin
  value = workifier
  # continue on your merry way
rescue
  # try to save the whole world
end
```

That seems just inconsequential enough to be a great example function, so we're going to go with it.

Now, we're all smart people that can immediately see what's going on with this method. It's generating a random integer, and if that value is odd, it's raising an error. Otherwise, it's returning double that value. It's a relatively simple method. But I have a few questions that are bugging me:

* How are we suppsoed to reliably test this thing?
* We're raising an exception when we receive bad input. Is this the right thing to do?

To the first of those, I almost immediately want to use a mocking library to redefine the behavior of `SuperRandomInt.generate` so I can dictate the values that it produces in my test suite. There's a seam there, so that's allowed (provided that this totally fake class and class method actually exist and is well-tested in its own right). Another gut reaction I have is that I should refactor this into a form that is more easily tested, because Sandi lovingly reminds us that friction when trying to forumlate a test usually indicates a bad design. So, let's refactor that method.

```ruby
class Workifier

  def call
    random = generate_random

    validate_random(random)

    double_random(random)
  end

  def generate_random
    SuperRandomInt.generate
  end

  def validate_random(input)
    raise "odd values are totally uncooth" if input % 2 != 0
  end

  def double_random(input)
    input * 2
  end
end

# Subsequent usage

workifier = Workifier.new

begin
  value = workifier.call
  # continue on your merry way
rescue
  # try to save the whole world
end
```

Okay, sweet. Now I have a class that I can instantiate to do the thing every time I use the `call` method. I have three methods comprised of my own code (`call`, `validate_random`, and `double_random`) that need tests, and I can write two of them really easily. To test `call`, though, I still have to mock out the random int generator (either directly or by mocking out my internal wrapper method, which is dubiously allowed at best). So, it's easier to test, but still hard to test.

One way to improve the testability would be to change it up so that `call` receives the random int instead of generating it, but we can't always make that sort of change work, particularly in larger and/or older projects. What we really need is a way to both have and eat our cake: we need a way to have that call method, but without having to explicitly write the method. It would also be kinda great if we weren't relying on the exception system. So, let's consider this Transaction instead:


I still have to mock the random integer generation, either by mocking out the generator itself or, if I'm totally down for looking like I'm breaking the rules, by mocking out my own `generate_random` method. I'm still raising an exception for bad values, and I'm still not sure if that's really what I want to do. We're all pretty good at handling exceptions badly, after all, and some folks would even prefer that we return `nil` rather than raising an exception.

```ruby
class Workifier
  include Dry::Transaction

  step :generate_random
  step :validate_random
  step :double_random

  def generate_random(input)
    Success(SuperRandomInt.generate)
  end

  def validate_random(input)
    input[:random] % 2 == 0 ?
      Success(input) :
      Failure(:odd_values_are_totally_uncooth)
  end

  def double_random(input)
    Success(input * 2)
  end
end

# Subsequent usage

workifier = Workifier.new

workifier.call do |match|
  match.success do |result|
    value = result
    # continue on your merry way
  end

  match.failure do |reason|
    # try to save the whole world
  end
end
```

While it's not necessarily readily apparent, this checks all of the boxes for hte concerns that I've raised:

* We still have a `call` method. It's just provided by `Dry::Transaction` and is tested on its own, so we don't have to test it.
* We can independently test all of our meaningful methods. Testing `generate_random` will still involve a mocking library, but instead of mocking actual behavior, our test would simply verify that `SuperRandomInt.generate` is called (if we even want to explicitly test it).
* We're not returning `nil`, and we're not raising an exception. We're returning a `Failure` object for the whole transaction if any of the steps produce a failure. We only have one point of failure, and we're returning a symbol that expresses what sort of failure occurred.

What else is somewhat neat here is that we *could* extract each of those methods out as an `Operation` (in short, a class with a `call` method that follows the same rules as a step as defined way above all of the example code). Doing that, our Transaction might look something like this:

```ruby
class Workifier
  include Dry::Transaction

  step :generate, with: Ops::GenerateRandom
  step :validate, with: Ops::ValidateRandom
  step :calculate, with: Ops::DoubleRandom
end

# Subsequent usage same as above
```

There are a few things about this implementation that I particularly like. First of, it's just insanely readable. That, of course, is a very subjective observation, but the reason that I say this is strongly related to my next point.

As there is no longer any actual code involved in this class, we can technically get away with not writing an explict test for it, rather relying on the tests that we've written for the individual operations. In practice, we're totally going to be writing some tests around code that involves this thing, but we're unlikely to write a test for this thing itself, and that is TOTALLY FINE.

## Bonus Neat Stuff ##

So, the definition of an Operation is a class with a `call` method that follows the same rules as we defined for steps. I didn't mention this above, which is why it's bonus neat stuff: that is also the description of a Transaction itself. That is, the `call` method brought in when you include `Dry::Transaction` takes zero or more inputs.

That means that you could also use a Transaction as an Operation in situations where you need to break extremely complicated workflows down into more human navigable pieces. It's Operations and monads the whole way down.

## So, yeah. Transactions. ##

I don't do a ton of work with Ruby these days, but when I do, I use the dry-transaction gem *as heavily as possible*. Maybe I'm odd. I adore the positive effects it has on my cognitive load when I'm reasoning about things, and that's reason enough for me to keep usig the gem. I also appreciate that new folks joining projects where it's being used seem to need far fewer questions answered about how things work, so maybe that's a bit more universal than I think it is?

Either way, give it a shot the next time you have a crazy iterative process to work on.
