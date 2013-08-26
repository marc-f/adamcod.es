---
layout: post
title: Mimicking the recently not approved Property Get/Set Syntax
---

There was a proposal[^1] for a new getter and setter syntax that would have enabled you to write code like this:

{% highlight php linespans %}
<?php

// Code sample indicating the terminology
class TimePeriod
{
    private $Seconds; // <-- Traditional Property

    public $Hours { // <-- Guarded Property
        get() { return $this->Seconds / 3600; }   // <-- Accessor, more specifically a getter
        set($x) { $this->Seconds = $x* 3600; }    // <-- Accessor, more specifically a setter
        isset() { return isset($this->Seconds); } // <-- Accessor, more specifically an issetter
        unset() { unset($this->Seconds); }        // <-- Accessor, more specifically an unsetter
    }
}
{% endhighlight %}

The benefit here, is that accessing the properties directly on an instantiated object like this:

{% highlight php linespans %}
 <?php
 // Accessing the property is the same as accessing a class member
 $time = new TimePeriod();
 $time->Hours = 12; // Stored as 43200
 echo $time->Hours; // Outputs 12
{% endhighlight %}

Would result in the getters and setters being called transparently.  Neat!  There are plenty of use-cases for this, and it would drastically reduce the amount of code in a lot of libraries and frameworks that are simple getters and setters, but unfortunately a large enough minority of core-contributors disagreed, or weren't happy with the syntax, or the implementation (or something), and the proposal failed to pass, so it won't be making it into the language. Not so neat.

Fortunately, there is a way to replicate this functionality (albeit with less syntactic sugar) using PHP's existing Magic Methods, and when combined with PHP 5.4's traits[^2], we get something pretty close.  Consider the following:

{% highlight php linespans %}
<?php
trait Accessors
{
    public function __get($name)
    {
        $getter = "get{$name}";
        if (method_exists($this, $getter)) {
            return $this->$getter();
        }
    }

    public function __set($name, $value)
    {
        $setter = "set{$name}";
        if (method_exists($this, $setter)) {
            return $this->$setter($value);
        }
    }
}

// Code sample indicating the terminology
class TimePeriod
{
    use Accessors;

    private $Seconds;  // <-- Traditional Property

    protected function getHours()
    {
        return $this->Seconds / 3600;
    }

    protected function setHours($value)
    {
        return $this->Seconds = $value * 3600;
    }
}
{% endhighlight %}


Now if we run our test code again:

{% highlight php linespans %}
 <?php
 // Accessing the property is the same as accessing a class member
 $time = new TimePeriod();
 $time->Hours = 12; // Stored as 43200
 echo $time->Hours; // Outputs 12
 {% endhighlight %}

We get the correct output!  For PHP 5.3 we could add the magic methods directly into the class that wants to use them, or create a base class and extend everything we want to have access to the magic getter/setters from that, but that feels messy, traits seem like the cleanest way to do this.

If we add `__isset` and `__unset` to the `Accessor` trait, we can replicate that functionality too:

{% highlight php linespans %}
<?php
trait Accessors
{
    public function __isset($name)
    {
        $issetter = "isset{$name}";
        if (method_exists($this, $issetter)) {
            return $this->$issetter();
        }
    }

    public function __unset($name)
    {
        $unsetter = "set{$name}";
        if (method_exists($this, $unsetter)) {
            return $this->$unsetter();
        }
    }
}

// Code sample indicating the terminology
class TimePeriod
{
    use Accessors;

    private $Seconds;  // <-- Traditional Property

    protected function issetHours()
    {
        return isset($this->Seconds);
    }

    protected function unsetHours($value)
    {
        return unset($this->Seconds);
    }
}
{% endhighlight %}

Obviously this is a lot more verbose than the original RFC, but it does provide a way to mimic some of its functionality.  If you want to use it, you can see the full trait in [this gist](https://gist.github.com/4621373#file-trait-full-php).

[^1]: https://wiki.php.net/rfc/propertygetsetsyntax-v1.2
[^2]: http://php.net/manual/en/language.oop5.traits.php
