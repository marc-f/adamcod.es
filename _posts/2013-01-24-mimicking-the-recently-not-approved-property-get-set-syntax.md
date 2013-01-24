---
layout: post
title: Mimicking the recently not approved Property Get/Set Syntax
---

There was a proposal[^1] for a new getter and setter syntax that would have enabled you to write code like this:

{% gist 4621373 rfc.php %}

The benefit here, is that accessing the properties directly on an instantiated object like this:

{% gist 4621373 rfc-test.php %}

Would result in the getters and setters being called transparently.  Neat!  There are plenty of use-cases for this, and it would drastically reduce the amount of code in a lot of libraries and frameworks that are simple getters and setters, but unfortunately a large enough minority of core-contributors disagreed, or weren't happy with the syntax, or the implementation (or something), and the proposal failed to pass, so it won't be making it into the language. Not so neat.

Fortunately, there is a way to replicate this functionality (albeit with less syntactic sugar) using PHP's existing Magic Methods, and when combined with PHP 5.4's traits[^2], we get something pretty close.  Consider the following:

{% gist 4621373 trait1.php %}


Now if we run our test code again:

{% gist 4621373 rfc-test.php %}

We get the correct output!  For PHP 5.3 we could add the magic methods directly into the class that wants to use them, or create a base class and extend everything we want to have access to the magic getter/setters from that, but that feels messy, traits seem like the cleanest way to do this.

If we add `__isset` and `__unset` to the `Accessor` trait, we can replicate that functionality too:

{% gist 4621373 trait2.php %}

Obviously this is a lot more verbose than the original RFC, but it does provide a way to mimic some of its functionality.  If you want to use it, you can see the full trait in [this gist](https://gist.github.com/4621373#file-trait-full-php).

[^1]: https://wiki.php.net/rfc/propertygetsetsyntax-v1.2
[^2]: http://php.net/manual/en/language.oop5.traits.php
