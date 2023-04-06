---
layout: post
title: Still Into Testing
categories: [bdd, go, inside testing]
---

My previous post here is a repost of a post (post post post) written on behalf of a Ruby-focused employer some years ago. It was all about how into testing I was at the time. I'm no longer working primarily with Ruby, so I don't really do much Ruby testing these days. What does testing in Go look like, though?

## It Looks Pretty Awesome ##

Well, it looks awesome if you're designing your code with testability in mind (more on that in the next post post post). Generally speaking, though, the testing story for any language or environment most often comes down to the tools available to you for doing that testing. Much like `minitest` eventually became part of the official Ruby distribution (which is no longer the case, if memory serves, but it's my example, and I'm sticking to it), Go ships with a standard testing library, `testing`.

Now, at first glance, the `testing` package seems lacking in a behavior-driven context. At its core, it's just a handful of unit testing primitives. Good luck writing a spec!

## An Example Go Spec ##

So, I could flail around here for a minute and show you how to make all of your `rspec` or `minitest-spec` dreams come true by using [ginkgo](https://onsi.github.io/ginkgo/) and [gomega](https://onsi.github.io/gomega/), but I'm not going to do that. I'm not saying that it's a bad solution at all. Quite the opposite: it's good stuff, but it just doesn't suit my tastes. Those are links specifically because I think you should go check them out if you're struggling with the notion of BDD in Go. It's a great stand-in if you need a full-blown `rspec` equivalent.

I'm a bare bones sort of person. I like minimalism, and I always really liked `minitest-spec`. I'm here to tell you, the standard `testing` package is a *perfect* stand-in for it.

Let's consider this little struct:

```go
package conflatedexample

import (
  "errors"
)

type StringPresence struct {
  wrapped string
}

func (validator *StringPresence) Validate() error {
  if len(elevated.wrapped) == 0 {
    return errors.New("cannot be blank")
  }

  return nil
}
```

That's a wonderful conflated example right there. For those Rails folk, it's sort of a presence validation. Now, we could just write a unit test (specifying inputs and expected outputs either on a per-case basis or looped over a table of examples), but we can also write something a whole lot like a spec:

```go
package conflatedexample

import (
  "testing"
)

// Test functions are generally named TestObjectUnderTest_MethodUnderTest,
// and they take a *testing.T object that provides the basic primitives
// for testing.

func TestStringPresence_Validate(t *testing.T) {
  // Directly create a variable as you would via `let` in a spec.
  // Make the value of this variable indicative of the happy path.

  input := "sausages"

  // Let's create a generator for the object that we're testing.
  subject := func(input string) *StringPresence {
    return &StringPresence{input}
  }

  // To start a new context (`context`/`describe`/`it` from the spec world),
  // you `t.Run()` a new example, which takes both a name and a test-style
  // function.

  t.Run("when given an empty string", func(t *testing.T) {
    // Within a context, shadow any variables that need to be changed
    // for the context.

    input := ""
    result := subject(input).Validate()

    t.Run("it returns an error", func(t *testing.T) {
      // Check the result

      if result == nil {
        // The code didn't do what we wanted, so we
        // need to provide that feedback.

        t.Errorf("expected an error, got nil")
      }
    })
  })

  t.Run("when given a non-empty string", func(t *testing.T) {
    // Our input let is already set in the enclosing context, so
    // we don't need to shadow it here.

    result := subject(input).Validate()

    t.Run("it returns no error", func(t *testing.T) {
      if result != nil {
        t.Errorf("expected no error, got %s", result.Error())
      }
    })
  })
}
```

If you know me (two of you who read this do, so it's not out of the question), you know the thing that I care about most in testing is expressing intent, so I always format my spec results in "doc" format. To get that behavior with the above spec, we just have to tell go to be verbose:

```
% go test -v ./...
=== RUN   TestStringPresence_Validate
=== RUN   TestStringPresence_Validate/when_given_an_empty_string
=== RUN   TestStringPresence_Validate/when_given_an_empty_string/it_returns_an_error
=== RUN   TestStringPresence_Validate/when_given_a_non-empty_string
=== RUN   TestStringPresence_Validate/when_given_a_non-empty_string/it_returns_no_error
--- PASS: TestStringPresence_Validate (0.00s)
    --- PASS: TestString_Validate/when_given_an_empty_string (0.00s)
        --- PASS: TestStringPresence_Validate/when_given_an_empty_string/it_returns_an_error (0.00s)
    --- PASS: TestStringPresence_Validate/when_given_a_non-empty_string (0.00s)
        --- PASS: TestStringPresence_Validate/when_given_a_non-empty_string/it_returns_no_error (0.00s)
PASS
ok  	codeberg.org/ess/conflatedexample	0.001s
```

Aside from some formatting choices (would prefer to see contexts with a new line and an appropriate number of tabs), that looks a WHOLE lot like rspec doc formatting to me, and I'm here for it.

## And But So, In Conclusion ##

That sure did sound like a fancy heading, didn't it? All I wanted to do here is to bookend the idea that BDD is awesome in every language, and it's pretty neat that Go gives us something in the standard library that can be used to do it in a manner with which we're already familiar.

Next time, we'll talk more about crazy testing ideas, because we're going to talk about mocking in Go.
