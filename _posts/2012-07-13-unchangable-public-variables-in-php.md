---
layout: post
author: adam
title: Unchangable Public Variables In PHP
summary: If you've ever had a use-case where you want to make a class property publicly read-able, but not modifiable, (without adding a getter), this is how you do it.
mark_old_post: false
---

If you've ever had a use-case where you want to make a class property publicly readable, but not writable, (without adding a getter), this is how you do it.

##Disclaimer##

Obviously, the easiest (and probably correct/best) way to do this is to add a getter to the class that returns the value of the private/protected property.  However this is a trick to make it appear as a normal property (in case you don't want any getters in your API, for example).

##Code##

This trick involves using PHP's magic methods and looks like this:

{% gist 3104351 MagicPublicProperty.php %}

Here we have a protected property that is obviously only accessible to instances of this class or child classes.

Below that we are using PHP's magic methods `__get` and `__isset` to intercept calls to this class' properties and we're checking to see if the property attempting to be accessed is `primaryKey`.  If it is, we return either the `isset` result or the value, depending on what we want to do.  This bit is fairly straight forward.

To stop anyone from attempting to set the value of this property from outside of the class, we need to add something to the `__set` magic method, if we didn't, it could lead to unexpected results.  We _could_ just trap it and return, doing nothing, but to make sure no-one does this accidentally in their code expecting it work, we should throw an exception with a helpful message.

What if you want it to be modified from outside of the class too?

Make it public (duh).

###Tests###

Here are some quick tests to prove it's working as expected:

{% gist 3104351 tests.php %}

and the results:

{% gist 3104351 results %}
