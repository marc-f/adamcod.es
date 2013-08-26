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

{% highlight php linespans %}
<?php

class MagicPublicProperty
{
    protected $_primaryKey = 'id';

    public function __set($property, $value)
    {
        if($property == 'primaryKey') {
            $name = get_class($this);
            throw new Exception("Unable to set property `{$property}` on"
            . " objects of type `{$name}`");
        }
    }

    public function __get($property)
    {
        if($property == 'primaryKey' && isset($this->_primaryKey)) {
            return $this->_primaryKey;
        }
    }

    public function __isset($property)
    {
        if($property == 'primaryKey') {
            return isset($this->_primaryKey);
        }
    }
}
{% endhighlight %}

Here we have a protected property that is obviously only accessible to instances of this class or child classes.

Below that we are using PHP's magic methods `__get` and `__isset` to intercept calls to this class' properties and we're checking to see if the property attempting to be accessed is `primaryKey`.  If it is, we return either the `isset` result or the value, depending on what we want to do.  This bit is fairly straight forward.

To stop anyone from attempting to set the value of this property from outside of the class, we need to add something to the `__set` magic method, if we didn't, it could lead to unexpected results.  We _could_ just trap it and return, doing nothing, but to make sure no-one does this accidentally in their code expecting it work, we should throw an exception with a helpful message.

What if you want it to be modified from outside of the class too?

Make it public (duh).

###Tests###

Here are some quick tests to prove it's working as expected:

{% highlight php linespans %}
<?php

require_once __DIR__ . '/MagicPublicProperty.php';

$test = new MagicPublicProperty;

/*
Added the following methods to MagicPublicProperty for the below tests:

    public function changePrimaryKey() {
        $this->_primaryKey = array(
            'foreign_key_1',
            'foreign_key_2'
        );
    }

    public function removePrimaryKey() {
        unset($this->_primaryKey);
    }

*/

test(isset($test->primaryKey), 'Is set');

test($test->primaryKey == 'id', 'Is accessible');

test(function() use ($test) {
    $test->changePrimaryKey();
    return is_array($test->primaryKey);
}, 'Is internally changeable');

test(function() use ($test) {
    try {
        $test->primaryKey = 'somethingelse';
    } catch (Exception $e) {
        return true;
    }

    return false;
}, 'Exception if set');

function test($c,$m) {
    $c = (is_callable($c)) ? $c() : $c;
    if($c) {
        echo "$m: Passed\n";
    } else {
        echo "$m: Failed\n";
    }
}
echo "\n\n";
{% endhighlight %}
and the results:

    Is set: Passed
    Is accessible: Passed
    Is internally changeable: Passed
    Exception if set: Passed
