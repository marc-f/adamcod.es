---
layout: post
title: Function vs Method vs Procedure
---

There seems to be a lot of confusion around the different names given to what are all effectively sub-routines.  Some people erroneously believe they are all essentially the same thing, and technically, whilst they are all simply different words for sub-routines, understanding the subtle differences between each can help you write better code.

Sub-routines
------------

Before you can accurately define types of sub-routine, you need to know what a sub-routine is.  It is actually quite simple to define: A sub-routine is a repeatable piece of procedural code you can call by name.

Functions
---------

A function is essentially a sub-routine that returns one or more values.  A function should calculate its return value based on its input; It should provide an answer about its arguments, or compute a new value based on its arguments.  Here are some examples of functions in PHP:

{% highlight php %}
<?php
function isAGreaterThanB($a, $b)
{
    return $a > $b;
}
{% endhighlight %}

This function provides an answer about its arguments.  Namely, is `$a` greater than `$b`?

{% highlight php %}
<?php
function multiply($a, $b)
{
    return $a * $b;
}
{% endhighlight %}

This function calculates a new value based on the values of its inputs, specifically, multiplying `$a` and `$b` together and returning the result.

The above examples are considered _Pure Functions_ because they don't rely on or modify anything outside of their own scope, and they don't cause any side-effects; that means they don't write any files, produce any output etc.  Given the same input, a pure function will always produce the exact same output.

Procedures
----------

A procedure is a sub-routine that doesn't return a value, but does have side-effects.  This could be writing to a file, printing to the screen, or modifying the value of its input.  Here are two procedures in PHP:

{% highlight php %}
<?php
function logMessage($message, $level = 'debug')
{
    $bytesWritten = file_put_contents("{$level}.log", $message, FILE_APPEND);
    return $bytesWritten !== false;
}
{% endhighlight %}

Here, our side-effect is to write a message to a log file.  We can return `true` or `false` to determin whether it failed or not, but really should not return anything else.

{% highlight php %}
<?php
function multiply(&$a, $b)
{
    $a = $a * $b;
}
{% endhighlight %}

This is an example of a procedure that mutates (modifies) its input value.  It is almost identical to our multiply function above, however instead of returning a new value, we pass `$a` by reference and assign it a new value.

Methods
-------

I have deliberately left methods for last, because a method is really a function or procedure that is executed in the context of an _object_.  That means there are two types of methods: A _function method_ and a _procedure method_.

That means a function method calculates a new value based on the values of its inputs and/or the scope of the object instance it's being executed on.

Here are the above function examples in an object context:

{% highlight php %}
<?php
class Integer
{
    protected $a;

    public function __construct($a)
    {
        $this->a = $a;
    }

    public function isGreatherThan($b)
    {
        return $this->a > $b;
    }

    public function multiply($b)
    {
        return $this->a * $b;
    }
}
{% endhighlight %}

Following this logically, a procedure method is a procedure that produces side-effects that can include modifying the state of the object instance it's being executed on.

Here are the above procedure examples in an object context:

{% highlight php %}
<?php

class Logger
{
    protected $level;

    public function __construct($level = 'debug')
    {
        $this->level = $level;
    }

    public function logMessage($message)
    {
        $bytesWritten = file_put_contents("{$this->level}.log", $message, FILE_APPEND);
        return $bytesWritten !== false;
    }

}
{% endhighlight %}

and our multiply example:

{% highlight php %}
<?php
class Integer
{
    protected $a;

    public function __construct($a)
    {
        $this->a = $a;
    }

    public function multiply($b)
    {
        $this->a = $this->a * $b;
    }
}
{% endhighlight %}

Conclusion
----------

It's sometimes easy to forget these distinctions when writing PHP, as everything starts with the `function` keyword, however, if you ask yourself: "What type of sub-routine do I _really_ want here?" you will hopefully find that you start to make better decisions and will write more logical and maintainable code.

Read Next:
----------

* [Interface-Segregation Principle in the Context of Mappers and Gateways](/2013/09/10/interface-segregation-principle-mappers-gateways.html)
