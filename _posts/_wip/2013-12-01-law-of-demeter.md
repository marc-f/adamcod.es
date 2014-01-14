---
layout: post
title: Friends of friends are strangers; don't talk to them
---

The Law Of Demeter[^1] also known as The Principle of Least Knowledge says that you should only talk to friends, not friends of friends, but what does that really mean.  Put simply: _An object should only call methods on objects it created or was passed directly_.  It's loosely related to the [Tell, Don't Ask](/2013/11/22/tell-dont-ask.html) principle, and just like the [Tell, Don't Ask](/2013/11/22/tell-dont-ask.html) principle, it's all about loose coupling.  Here's an example:

{% highlight php startinline %}
class ExampleTable
{
    protected $tableGateway;

    public function __construct($tableGateway)
    {
        $this->tableGateway = $tableGateway;
    }

    public function persist()
    {
        $this->tableGateway->dbAdapter->insert('example_table', $this->toArray());

        // could also be:
        $this->tableGateway->getDbAdapter()->insert('example_table', $this->toArray());
    }
}
{% endhighlight %}

Here, our friend is the `tableGateway`, and our friend's friend is the `dbAdapter`.  The fact that we're accessing the `dbAdapter` through `tableGateway` means that `ExampleTable` has knowledge of the inner workings of `tableGateway`, and therefore if the inner workings ever changed then `ExampleTable` would possibly stop working.

There are two ways to avoid this, the first looks like this:

{% highlight php startinline %}
class ExampleTable
{
    protected $tableGateway;

    public function __construct($tableGateway)
    {
        $this->tableGateway = $tableGateway;
    }

    public function persist()
    {
        $this->tableGateway->insert('example_table', $this->toArray());
    }
}
{% endhighlight %}

Here, `tableGateway` has been modified to allow `ExampleTable` to call a method on it directly to insert the record.  Internally it can just proxy it to `dbAdapter` still, but now `ExampleTable` doesn't know that, so it doesn't matter if the implementation changes at some point.  The second solution looks like this:

{% highlight php startinline %}
class ExampleTable
{
    protected $dbAdapter;

    public function __construct($dbAdapter)
    {
        $this->dbAdapter = $dbAdapter;
    }

    public function persist()
    {
        $this->dbAdapter->insert('example_table', $this->toArray());
    }
}
{% endhighlight %}

Here, we're simply passing the `dbAdapter` directly to `ExampleTable`, as that's what example table actually needs, so we're bypassing the middle-man.



[^1]: http://en.wikipedia.org/wiki/Law_of_Demeter
