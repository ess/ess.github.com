---
layout: post
title: Cartography Preface
---

Have you ever wanted to create your very own client for a REST API? That's what this series, Cartography, is all about.

Why "cartography?" Well, a lot of the REST APIs out there, regardless of how well documented they may be, require for us to do a bit of journeying and mapping along the way to figure out how things really work. A lot of the time, the API provider will go ahead and publish clients for the popular languages of the day because of the above conundrum, but that isn't always the case.

For example, the [Engine Yard API](https://developer.engineyard.com) is relatively well-documented, and Engine Yard does provide [a Ruby client](https://github.com/engineyard/core-client-rb), but what if I want to consume this API from a Python program?

That is the example that we'll use for this series: implementing a Python client for the Engine Yard API. That said, the techniques used here should be fairly easily adapated to most any language or API.
