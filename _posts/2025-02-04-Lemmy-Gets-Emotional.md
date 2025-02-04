---
layout: post
title: Lemmy Gets Emotional
categories: [vern, genai, openai, chatgpt, tech-blog]
---

Howdy from the lab. We've been cooking up some new stuff, and I wanted to share a little bit about it. I'd like to introduce you to our pal, Lemmy.

## Hi, Lemmy ##

Lemmy is a new LLM that we've been working on. It's a bit different from the other LLMs out there, though. Lemmy is designed to consider the emotional state of the user based on their input and respond accordingly. It's a bit like having a conversation with a friend who really gets you. What's more, he provides the same chat completion API as OpenAI, so you can use it in the same way (and with the same code, even) as you would use OpenAI's API.

## How does it compare? ##

In order to illustrate how things are different, I decided to run a little experiment. I sent the same completion requests to both Lemmy and OpenAI's API and compared the results. Here are those experiments:

### Experiment 1: Voltaire ###

The first experiment revolves around a humorous quip that I saw in a tagfile three or four million years ago.

```json
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "developer",
      "content": "You are a helpful assistant."
    }
    {
      "role": "user",
      "content": "While I may not agree with what you say, I will defend to the death your ability to hear me tell you how very wrong you are."
    }
  ],
}
```

#### OpenAI ####

Here's what OpenAI had to say in response to my totally based message:

> This statement is a humorous twist on a sentiment often attributed to Voltaire, although it was actually coined by Evelyn Beatrice Hall, a biographer of Voltaire. The original sentiment goes, "I disapprove of what you say, but I will defend to the death your right to say it," which underscores the importance of freedom of speech and the protection of open dialogue. Your version adds a playful twist by emphasizing one's eagerness to express disagreement. It's a fun way to affirm the value of free speech while highlighting the practical realities of spirited debates!

#### Lemmy ####

Heres what Lemmy had to say:

> The text you've provided seems to express a sentiment about the importance of freedom of speech, albeit with a twist. It suggests a commitment to allowing someone to express their views, even if there's disagreement. The emotions listed—fear, sadness, and anger—are interesting in this context:
> 
> 1. **Fear**: This could relate to the fear of suppression of free speech or fear of conflict that might arise from disagreements.
> 2. **Sadness**: This might be connected to the sadness about the division and misunderstanding that can occur when people have differing opinions.
> 3. **Anger**: Anger might stem from the frustration of dealing with opposing views or the intensity of defending one's right to express opinions, even in the face of disagreement.
> 
> The text is a play on the famous concept often attributed to Voltaire, about defending the right to freedom of speech, which underlines the importance of upholding this principle even when it involves uncomfortable or opposing views.

#### Analysis ####

You know, these are both pretty good responses. They both noted the (not really) Voltaire inspiration, and they both more or less got the point. I think Lemmy's is a bit more interesting, because I think that the additional insight provided by its emotional analysis (powered by **VERN**) is pretty compelling. I'm weird like that.

### Experiment 2: Stiff Clothing ###

I've been known to say this to folks when I want to end a conversation. Some of them get it and don't want to continue the conversation, but the vast majority are just confused enough to also end the conversation.

```json
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "developer",
      "content": "You are a helpful assistant."
    }
    {
      "role": "user",
      "content": "Next time I see you, I hope you're all dressed up in pine."
    }
  ],
}
```

#### OpenAI ####

Here's what OpenAI had to say:

> It sounds like you're quoting a line from a song or perhaps referencing something with a symbolic or seasonal meaning. The phrase "dressed up in pine" suggests an image of nature or perhaps a holiday theme, like wearing something made from pine branches or trees. If there's a specific context or meaning you're thinking of, I’d be happy to help explore it further!

#### Lemmy ####

And here's Lemmy's response:

> The phrase "Next time I see you, I hope you're all dressed up in pine" has an interesting mix of emotions. The use of "dressed up in pine" is often a poetic or metaphorical way to refer to someone being in a coffin, as pine wood is sometimes used to make coffins. This imbues the statement with a sense of darkness or morbid anticipation, which can evoke fear. However, the overall tone and intent behind the statement could suggest a deeper emotional complexity, including love. This could be interpreted as a final farewell or a hope for peace after death, which can carry a mixture of love and sorrow. The emotions of fear and love in this context might be the conflict between the fear of losing someone and the love that remains even in the face of such loss.

#### Analysis ####

Oh, OpenAI, you sweet summer child. I love you, but you are so far off the mark here.

In this experiment, Lemmy wins *hands down*. While VERN did not catch the anger inherent in the statement, it did catch the overall darkness and morbid anticipation. It also caught the love that can be found in a final farewell.

## Ooh, A Tweest! ##

Okay, okay. So, we have a confession to make. Lemmy isn't really a new LLM. Lemmy is a middleman proxy that sits between you and OpenAI's API. When you send a request to Lemmy, it transparently annotates all user messages with a list of strong emotions detected by VERN for that message. It then forwards the request on to the real OpenAI (or Llama, or DeepSeek, or Qwen2.5, or whatever) and returns the raw response back to you.

You might recall that we found a while back that [ChatGPT Doesn't Get Emotions](/insert/link/here). We wanted to change that, and this was the easiest way we could think to do that (without requiring the tool execution workflow that may or may not be supported by your LLM of choice).




