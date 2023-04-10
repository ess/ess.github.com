---
layout: post
title: Mocking In Go
categories: [bdd, go, mocking]
---

As mentioned [last time around](/2023/04/04/Still-Into-Testing), the `testing` package is really barebones and doesn't provide the BDD concepts that we all know and love like easy mocking and stuff like that.

A few quick notes:

* While I don't think it should be at all, this entry is about a somewhat divisive topic. In my mind, mock objects are quite possibly the best thing in life for a test-oriented developer. I think the bad rep they get is more or less down to mocking the wrong things at the wrong time. Today, I'm going to focus on the *HOW*, but you have my word that I'll talk about the other interrogatives around mocking some day soon.
* Maybe get yourself a beverage. This is going to be relatively heavy on code samples.

## Mocking ##

There are of course mocking packages for Go. From what I've seen, a good deal of them involve doing compile-time code generation, introspection, and stuff like that. I'm not a real big fan of that sort of thing, to the point that I don't really have a suggestion for an off-the-shelf mocking solution. Well, that's not true. Specifically for mocking HTTP requests against third-party services, packages like [httpmock](https://pkg.go.dev/github.com/jarcoal/httpmock) are pretty great, but that's also relatively niche. If you know me (we've already established that you might), you know that I don't care for one-off niche tools so much.

So, what are we to do? In Ruby projects, I'd use a Plain Ol' Ruby Object (likely a literal instance of `Object`) and attach stubbed methods to it during the test. Go, however, is not nearly as squishy as Ruby. That means the question remains ... what are we to do?

## We POGO, That's What ##

We can implement our very own lightweight mocks with Plain Ol' Go Objects, POGOs.

Way back in the last post, I mentioned that things are awesome if you design your code with testability in mind. While it's definitely not the be-all-end-all concept for that idea, a pretty big part of that to me is to use interfaces absolutely anywhere that it makes sense (and in a few cases where it doesn't). Let's expand on our already conflated example:

```go
package conflatedexample

type interface Validator {
  Validate(interface{}) error
}
```

Okay, so now we have an interface that describes a validator. Also, we need to update our `StringPresence` validator so it implements this interface. Let's start with the spec:

```go
package conflatedexample

import (
  "testing"
)

func TestStringPresence(t *testing.T) {
  input := "sausages"

  subject := func() *StringPresence {
    return &StringPresence{}
  }

  t.Run("Validate()", func(t *testing.T) {
    t.Run("when given a non-string", func(t *testing.T) {
      result := subject().Validate(12345)

      t.Run("it returns an error regarding the bad data", func(t *testing.T) {
        if result == nil {
          t.Errorf("expected an error, got nil")
        }
      })
    })

    t.Run("when given a string", func(t *testing.T) {
      t.Run("that is blank", func(t *testing.T) {
        input := ""
        result := subject().Validate(input)

        t.Run("it returns an error", func(t *testing.T) {
          if result == nil {
            t.Errorf("expected an error, got nil")
          }
        })
      })

      t.Run("that is not blank", func(t *testing.T) {
        result := subject().Validate(input)

        t.Run("it returns no error", func(t *testing.T) {
          if result != nil {
            t.Errorf("expected no error, got %s", result.Error())
          }
        })
      })
    })
  })
}
```

That looks pretty good. We even added an extra scenario, because the type that we take as an argument in our method is now the *any* type, so we need to make sure that we handle the possibility that it receives data that it doesn't know how to handle. Of course, the test fails, because we haven't updated our code yet. So, let's do that.

```go
package conflatedexample

import (
  "errors"
)

type StringPresence struct{}

func (validator *StringPresence) Validate(candidate interface{}) error {
  wrapped, ok := candidate.(string)
  if !ok {
    return errors.New("not a string")
  }

  if len(wrapped) == 0 {
    return errors.New("cannot be blank")
  }

  return nil
}
```

There we go. Now we have a notion of a Validator, and we have a real implementation of that idea that validates that a string contains content. How does that help us with our test?

## It Doesn't ##

What it *does* help us test is things that *use* validators, because now we can mock along the seam that we just created and **code to the interface**. Let's throw down a handy mock validator.

```go
package conflatedexample

import (
  "errors"
)

var errUnimplemented = errors.New("unimplemented")

// just to save us some confusion, i like having names for things that I reference a lot
type validateImpl func(interface{}) error

// NewMockValidator returns a mocked Validator that is configured to always return a failure
// for all methods. This behavior is configurable by chaining `With...` methods.
func NewMockValidator() *MockValidator {
  return &MockValidator{
    validate: func(candidate interface{}) error {
      return errUnimplemented
    },
  }
}

type MockValidator struct {
  validate validateImpl
}

// Implement the Validator API

func (validator *MockValidator) Validate(candidate interface{}) error {
  // to allow for a configurable experience, let's call whatever is stored in the mock
  return validator.validate(candidate)
}

// Allow for configurable behavior

func (validator *MockValidator) Clone() *MockValidator {
  // to help out with thread safety, let's treat our validator as immutable and create
  // a deep copy for modifications
  return &MockValidator{
    validate: validator.validate,
  }
}

func (validator *MockValidator) WithValidate(impl validateImpl) *MockValidator {
  // let's make a clone with a specific validatorValidate implementation
  tweaked := validator.Clone()
  tweaked.validate = impl

  return tweaked
}
```

There we go. Now we have a mock validator that we can use anywhere that we'd need to test code that uses a validator. What's more, we can configure its behavior by chaining calls to it like so:

```go
myValidator := NewMockValidator().
  WithValidate(func(candidate interface{}) error {
    // let's return a specific error rather than the default error
    return errors.New("this is a very specific error")
  })
```

## Use the Mocks ##

So, right now, our conflated example includes not just a notion of a Validator, but also two Validator implementations. One of those is a real validator that validates string presence, and the other is a mock validator that always says no (unless you tell it to say something else).

Let's use this to BDD up a reified process that valdates some data before it saves it to a database.

```go
package conflatedexample

import (
  "errors"
  "testing"
)

// For the purpose of this exercise, let's roll with these
// assumptions:
//
//   * There is a struct named Person with a Name field
//   * There is an interface named Driver that implements
//     database CRUD operations for Person records
//
// To make things even better, I'm going to go ahead and mock the
// Driver in our spec, too.

func TestSavify(t *testing.T) {
  t.Run("Save(*Person)", func(t *testing.T) {
    validationFailureMessage := "validation failure"
    createFailureMessage := "put failure"
    errValidation := errors.New(validationFailureMessage)
    errCreate := errors.New(createFailureMessage)

    badValidate := func(candidate interface{}) error {
      return errValidation
    }

    goodValidate := func(candiate interface{}) error {
      return nil
    }

    badCreate := func(p *Person) error {
      return errCreate
    }

    goodCreate := func(p *Person) error {
      return nil
    }

    validator1 := NewMockValidator().WithValidate(goodValidate)
    validator2 := NewMockValidator().WithValidate(goodValidate)
    driver := NewMockDriver().WithCreate(goodCreate)

    subject := func(driver Driver, validators ...Validator) *Savify {
      return NewSavify(driver, validators...)
    }

    input := &Person{Name: "george"}

    t.Run("when any validator fails", func(t *testing.T) {
      validator1 := validator1.WithValidate(badValidate)

      result := subject(driver, validator1, validator2).Save(input)

      t.Run("it returns a validation error", func(t *testing.T) {
        if result == nil {
          t.Errorf("expected an error, got nil")
        }

        details := result.Error()
        if details != validationFailureMessage {
          t.Errorf("expected a validation failure, got %s", details)
        }
      })
    })

    t.Run("when all validators succeed", func(t *testing.T) {
      t.Run("but the driver can't save the record", func(t *testing.T) {
        driver := driver.WithCreate(badCreate)

        result := subject(driver, validator1, validator2).Save(input)

        t.Run("it returns a create error", func(t *testing.T) {
          if result == nil {
            t.Errorf("expected an error, got nil")
          }

          details := result.Error()
          if details != createFailureMessage {
            t.Errorf("expected a create failure, got %s", details)
          }
        })
      })

      t.Run("and the driver saves the record", func(t *testing.T) {
        result := subject(driver, validator1, validator2).Save(input)

        t.Run("it returns a success", func(t *testing.T) {
          if result != nil {
            t.Errorf("expected no error, got %s", result.Error())
          }
        })
      })
    })
  })
}
```

I know, we sure are writing a lot of code before we ... write any code. Let's look at some things that we know about the thing that we're going to write based on that spec, though:

* `Savify` is an object. It has a Driver and a list of Validators as members
* `Savify` also has a method called Save that takes a Person reference
* There's a friendly `NewSavify()` constructor that takes a driver and a list of validators and gets us a `Savify` reference
* `Savify.Save()` cares about whether or not its validations succeed, but *totally doesn't* care about what those validations do
* `Savify.Save()` cares about whether or not its driver can create the desired record, but *totally doesn't* care about how it does it

Design wise, that's a pretty good way to be. At the least, it keeps Demeter happy. Let's go ahead and implement our Savify object:

```go
package conflatedexample

type Savify struct {
  driver     Driver
  validators []Validator
}

func NewSavify(driver Driver, validators ...Validator) *Savify {
  return &Savify{
    driver:     driver,
    validators: validators,
  }
}

func (s *Savify) Save(person *Person) error {
  for _, v := range s.validators {
    if err := v.Validate(person.Name); err != nil {
      return err
    }
  }

  return s.driver.Create(person)
}
```

## That's ... IT?! ##

Yup. That's it ... I said it almost a decade ago, and I'll say it again now: to me, behavior testing is all about expressing intent. It's almost always the case that the spec for a given chunk of code is going to be larger than said chunk of code.

That's a great thing in itself, but that's not the point of this entry. This entry is all about expressing intent in a different way by using our own lightweight mocks instead of reaching out to a third-party package that's almost certainly full of very clever magic that disallows us from expressing intent.

Now, if you really want to melt your brain on this, consider that the only thing in the project that our tests don't fully cover is the constructors for our mocks. We could totally write behavior tests for these mocks (and we should). I'm going to leave that as an exercise for you, dear friend. Also, you'll need to come up with the meat of both the Driver interface as well as the mock Driver implementation. I know you can do it.

Next time around, we're going to take a moment to talk about the differences between Test-Driven Development and Behavior-Driven Development, and I'll talk a little about why I prefer BDD.
