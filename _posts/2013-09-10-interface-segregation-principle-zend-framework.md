---
layout: post
title: Interface-Segregation Principle in the Context of Mappers and Gateways
---

The interface-segregation principle is the _I_ in the SOLID[^1] acronym that describes the 5 basic principles of good object oriented design.  It states that no client (read: _object_) should be forced to depend on methods it does not use.

Take this simple snippet that that will probably be familiar to most of you:

{% highlight php %}
<?php
class SomeMapper
{
    protected $gateway;

    public function __construct(Zend_Db_Table_Abstract $someGateway)
    {
        $this->gateway = $someGateway;
    }
}
{% endhighlight %}

This is a fairly simple form of Dependency Injection where the gateway that we're operating on is injected in to our mapper, meaning that we could pass any subclass of `Zend_Db_Table_Abstract` to our mapper when we construct it and safely expect all of the methods of `Zend_Db_Table_Abstract` to be available to us.

Let's take a look at the methods available to us in `Zend_Db_Table_Abstract`:

    setOptions
    setDefinition
    getDefinition
    setDefinitionConfigName
    getDefinitionConfigName
    setRowClass
    getRowClass
    setRowsetClass
    getRowsetClass
    addReference
    setReferences
    getReference
    setDependentTables
    getDependentTables
    setDefaultSource
    getDefaultSource
    setDefaultValues
    getDefaultValues
    setDefaultAdapter
    getDefaultAdapter
    getAdapter
    setDefaultMetadataCache
    getDefaultMetadataCache
    getMetadataCache
    setMetadataCacheInClass
    metadataCacheInClass
    init
    info
    select
    insert
    isIdentity
    update
    delete
    find
    fetchAll
    fetchRow
    fetchNew
    createRow

That's 38 methods that are available to our mapper.

In reality, does our mapper need to use all of those?  Chances are it doesn't, but if we type hint on `Zend_Db_Table_Abstract`, any object we pass in to our mapper will _have_ to implement all of those methods[^2].

The interface-segregation principle **requires** us to use a better way.  If we expand on our mapper a little bit, we could end up with something like this:

{% highlight php %}
<?php
class SomeMapper
{
    protected $gateway;

    public function __construct(Zend_Db_Table_Abstract $someGateway)
    {
        $this->gateway = $someGateway;
    }

    public function findAllByName($name)
    {
        $select = $this->gateway->select()
            ->from($this->gateway)
            ->where('name = ?', $name);

        return $this->gateway->fetchAll($select);
    }
}
{% endhighlight %}

This is a fairly common use-case.  We only use a few methods from `Zend_Db_Table_Abstract` in our mapper, so why not create an interface just for those methods:

{% highlight php %}
<?php
interface SelectableInterface
{
    public function select();
    public function fetchAll(Zend_Db_Select $select);
}
{% endhighlight %}

Now we should make sure our mapper depend on this interface, instead of the full `Zend_Db_Table_Abstract` interface:

{% highlight php %}
<?php
class SomeMapper
{
    protected $gateway;

    public function __construct(SelectableInterface $someGateway)
    {
        $this->gateway = $someGateway;
    }

    // ... snip ...
{% endhighlight %}

Now, we make sure our concrete gateway class implements our new interface, like so:

{% highlight php %}
<?php
class OurGateway extends Zend_Db_Table_Abstract implements SelectableInterface
{}
{% endhighlight %}

We don't actually need to add any methods, as `Zend_Db_Table_Abstract` implements them for us.

The benefits are immediately obvious here.  Let's say we don't want to use `Zend_Db_Table_Abstract` for our gateway anymore, and instead we just want to use PDO straight-up.

{% highlight php %}
<?php
class OurGateway implements SelectableInterface
{
    protected $pdo;

    public function __construct(PDO $pdo)
    {
        $this->pdo = $pdo;
    }

    public function select()
    {
        // fetch all type hints on Zend_Db_Select and as it just returns
        // SQL in its __toString method there shouldn't be a problem
        // using it with PDO.
        return new Zend_Db_Select();
    }

    public function fetchAll(Zend_Db_Select $select)
    {
        $statement = $this->pdo->query($select);
        return $statement->fetchAll();
    }
}
{% endhighlight %}

This implementation still works with our mapper just as well as the original which was based on `Zend_Db_Table_Abstract`.

But what about when you want to add some more methods to the gateway?  I don't like to build any SQL outside of my gateways, as I don't think mappers should have knowledge of the underlying data-structure, so let's move our `findAllByName` method's SQL building part down a level, to the gateway:

{% highlight php %}
<?php
class OurGateway extends Zend_Db_Table_Abstract implements FetchableInterface
{
    public function getFindAllByNameSelect($name)
    {
        return $this->select()
            ->from($this)
            ->where('name = ?', $name);
    }
}
{% endhighlight %}

And the relevant mapper:

{% highlight php %}
<?php
class SomeMapper
{
    protected $gateway;

    public function __construct(FetchableInterface $someGateway)
    {
        $this->gateway = $someGateway;
    }

    public function findAllByName($name)
    {
        return $this->gateway->fetchAll(
            $this->gateway->getFindAllByNameSelect()
        );
    }
}
{% endhighlight %}

and finally the updated interface:

{% highlight php %}
<?php
interface FetchableInterface
{
    public function fetchAll(Zend_Db_Select $select);
}
{% endhighlight %}

This example is somewhat contrived, you wouldn't implement these classes this way in real life, but I want to use them to illustrait a point.

The `FetchableInterface` doesn't require the `getFindAllByNameSelect` method to be present, but our mapper depends on it.  The reason for this is that we want our interfaces to be as small as possible.  The smallest possible (useful) interface for our gateways is the `FetchableInterface`; saying that we can fetch all instances of an object from that gateway based on a `Zend_Db_Select` object.

Not all of our gateways are going to have a `getFindAllByNameSelect` method, so we don't want to add it to our interface that may well be used for a large number of our gateways.  So for our `getFindAllByNameSelect` method, we create another interface:

{% highlight php %}
<?php
interface FindByNameInterface
{
    public function getFindAllByNameSelect();
}
{% endhighlight %}

Fortunately, PHP lets you implement multiple interfaces, so we can update our gateway to enforce this:

{% highlight php %}
<?php
class OurGateway extends Zend_Db_Table_Abstract
    implements FetchableInterface, FindByNameInterface
{
    // ... snip ...
}
{% endhighlight %}

But this leads to a problem:  We can't type hint on multiple interfaces in our mapper.  Thankfully, PHP has a little-known feature in that interfaces can use multiple inheritance.  That means we can create a new third interface that our mapper _can_ type hint on:

{% highlight php %}
<?php
interface FetchableByNameInterface
    extends FetchableInterface, FindByNameInterface
{

}
{% endhighlight %}

This interface doesn't need any methods (though you could add some if you wanted to), as it inherits methods from both `FetchableInterface` and `FindByNameInterface`.  Now we can update our mapper to type hint on this new interface:


{% highlight php %}
<?php
class SomeMapper
{
    protected $gateway;

    public function __construct(FetchableByNameInterface $someGateway)
    {
        $this->gateway = $someGateway;
    }

    // ... snip ...
}
{% endhighlight %}

and our gateway:

{% highlight php %}
<?php
class OurGateway extends Zend_Db_Table_Abstract
    implements FetchableByNameInterface
{
    // ... snip ...
}
{% endhighlight %}

As I said before, the examples here are somewhere contrived, and could be achieved in different or simpler ways (such as `FindByNameInterface` extending `FetchableInterface`), but the main point of this post was to demonstrait how to use multiple-inheritance with interfaces to achieve really nice and simple interface-segregation.

Hopefully armed with this knowledge you can go out and start creating objects that depend on the smallest possible interface, which will help you write easier and smaller unit tests (fewer methods to mock), and more reliable and robust code that is ultimately easier to maintain too!

##Read Next:

* [Example of this code on 80+ PHP versions](http://3v4l.org/Yff7T)
* [Zend Framework 1.x, PHPUnit 3.4 and PHPUnit 3.7 side-by-side](/2013/05/30/zend-1.x-phpunit-3.4-and-3.7-composer.html)

[^1]: http://en.wikipedia.org/wiki/SOLID_%28object-oriented_design%29
[^2]: Actually, as `Zend_Db_Table_Abstract` is an abstract class and not an interface it will need to _extend_ Zend_Db_Table_Abstract which already has all of those methods implemented.
