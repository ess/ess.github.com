---
layout: post
title: Rethinking Specs (an update)
categories: [bdd, go, inside testing, update]
---

So, last time around, I promised that we'd talk about mocking next. That's still the plan for the next real post. However, I had a conversation yesterday with my pal Ian around the idea of lightweight specs using Go's standard `testing` library (and specifically the spec that I presented in the previous post). We came to the conclusion that there's a slight change we could make to make that spec even more like a real spec, so let's explore that.

## Orange ##

When I first started the journey of trying to adapt my BDD practices to Go back in the Triassic period, there was a fairly predominant opinion that since Go isn't primarily an OOP environment, we should only describe behaviors (functions), not the data constructs to which they're attached. So, the convention was to have (at least) one `TestSomething` func for every behavior that one wished to test.

That's fine and good, but also a bit limiting, and it makes us think of things at a bit too low of a level: instead of thinking about an API, we're thinking about one specific behavior at a time. Let's keep talking about our conflated example from last time around. In ruby, we'd do something like this:

```ruby
describe Validations::StringPresence do
  let(:input) {'sausages'}
  let(:validator) {described_class.new(input)}

  describe '#validate' do
    let(:result) {validator.validate()}

    context "when given an empty string" do
      let(:input) {''}

      it 'raises an error' do
        expect {result}.to raise_error
      end
    end

    context "when given a non-empty string" do
      it 'raises no error' do
        expect {result}.not_to raise_error
      end
    end
  end

end
```

That is, we'd describe the class that we're testing, then we'd nest a description for each of the methods of that class that we wish to test. We'd generally keep the description for the entire `StringPresence` API in one place, so we'd have all of the knowledge about its behavior right there, read to go (regardless of how many files we spread that functionality across). Our `rspec` output also looks amazing:

```
Validations::StringPresence
  #validate
    when given an empty string
      raises an error
    when given a non-empty string
      raises no error
```

## The New Black ##

So, with a couple small tweaks, we can make roughly the same thing happen for our Go spec. First, let's change the name of our test func to express that we're testing an object and its methods, not just a func:

```go
package conflatedexample

import (
  "testing"
)

func TestStringPresence(t *testing.T) {
  input := "sausages"
  subject := func(input string) *StringPresence {
    return &StringPresence{input}
  }

  t.Run("when given an empty string", func(t *testing.T) {
    input := ""
    result := subject(input).Validate()

    t.Run("it returns an error", func(t *testing.T) {

      if result == nil {
        t.Errorf("expected an error, got nil")
      }
    })
  })

  t.Run("when given a non-empty string", func(t *testing.T) {
    result := subject(input).Validate()

    t.Run("it returns no error", func(t *testing.T) {
      if result != nil {
        t.Errorf("expected no error, got %s", result.Error())
      }
    })
  })
}
```

Now, let's add a context to declare the method we're describing:

```go
package conflatedexample

import (
  "testing"
)

func TestStringPresence(t *testing.T) {
  input := "sausages"
  subject := func(input string) *StringPresence {
    return &StringPresence{input}
  }

  t.Run("Validate()", func (t *testing.T) {
    t.Run("when given an empty string", func(t *testing.T) {
      input := ""
      result := subject(input).Validate()

      t.Run("it returns an error", func(t *testing.T) {

        if result == nil {
          t.Errorf("expected an error, got nil")
        }
      })
    })

    t.Run("when given a non-empty string", func(t *testing.T) {
      result := subject(input).Validate()

      t.Run("it returns no error", func(t *testing.T) {
        if result != nil {
          t.Errorf("expected no error, got %s", result.Error())
        }
      })
    })
  })
}
```

Now, those seem like trivial changes to make, and that's because they are. However, we now have a fully described object instead of just a method. What's more, our verbose test output now also treats the `Validate` method as an actual concept rather than just a name on a test func declaration. Here's the output we had before:

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

That's okay and all, but I honestly prefer this a bit better, because it gives my brain meat a clearer picture of what I'm dealing with:

```
% go test -coverprofile=coverage.out -v ./...
=== RUN   TestStringPresence
=== RUN   TestStringPresence/Validate()
=== RUN   TestStringPresence/Validate()/when_given_an_empty_string
=== RUN   TestStringPresence/Validate()/when_given_an_empty_string/it_returns_an_error
=== RUN   TestStringPresence/Validate()/when_given_a_non-empty_string
=== RUN   TestStringPresence/Validate()/when_given_a_non-empty_string/it_returns_no_error
--- PASS: TestStringPresence (0.00s)
    --- PASS: TestStringPresence/Validate() (0.00s)
        --- PASS: TestStringPresence/Validate()/when_given_an_empty_string (0.00s)
            --- PASS: TestStringPresence/Validate()/when_given_an_empty_string/it_returns_an_error (0.00s)
        --- PASS: TestStringPresence/Validate()/when_given_a_non-empty_string (0.00s)
            --- PASS: TestStringPresence/Validate()/when_given_a_non-empty_string/it_returns_no_error (0.00s)
PASS
coverage: 100.0% of statements
ok      codeberg.org/ess/conflatedexample       0.001s  coverage: 100.0% of statements
```

## Wait Just A Second There ##

No. We're not going to talk about the test coverage stuff right now. That's a topic for a different day. I'll see y'all again Tuesday to talk all about mocking.
