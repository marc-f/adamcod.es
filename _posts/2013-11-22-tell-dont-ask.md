---
layout: post
title: Tell, Don't Ask
---

Violation of the Tell, Don't Ask principle is one of the most common mistakes I see in legacy code-bases, and one of the most common mistakes I see in new code that I review.  Left unchecked it can lead to serious problems down the line.

Here's an example:

{% highlight php startinline %}
class ExampleForm
{
    const SELECT = '<select name="%s">%s</select>';
    const OPTION = '<option value="%s">%s</option>';

    protected $mapper;

    public function __construct(ExampleMapper $mapper)
    {
        $this->mapper = $mapper;
    }

    // ...snip...

    public function getExampleSelect()
    {
        $options = [];
        foreach ($this->mapper->fetchList() as $id => $value) {
            $options[] = sprintf(self::OPTION, $id, $value);
        }

        return sprintf(self::SELECT, 'someSelect', join("\n", $options));
    }
}

$someForm = new ExampleForm($mapper);
echo $someForm->getExampleSelect();
{% endhighlight %}

On the face of it, this code is actually pretty good.  It's some sort of form class, and the `getExampleSelect` method is building up an HTML select element.  The mapper was injected, meaning the code is pretty easy to test, as we can replace the mapper with a mock object.

There is a problem, however, and the problem is a fundamental one.  Left unchecked, this problem can grow and fester with your software.  Over time it can cause your development pace to slow to the point adding even trivial new features or changes to existing code can take weeks or months, slowing development velocity to a crawl, or stalling it altogether.

The problem with the above code, which may not be obvious at first, is the `getExampleSelect` method _asking_ the mapper for a list to iterate over. By injecting the mapper and then _asking_ it for the list we are tying the implementation of that form not only to the mapper, but also the implementation of the mapper.

This means that in 6 months, 12 months, or even (as in the case at my current employment) 8 years later, you want to create an instance of `ExampleForm` that specifies the list options manually, rather than relying on the mapper, you have very few options to re-use this form class.  You can either sub-class it, or you can hack `$mapper->fetchList()` to return different things, adding in some sort of flag depending on the situation.

Over time this can grow and lead to a mess of sub-classes and hacky code with cryptic flags that anyone who has maintained a large enough legacy application has seen hundreds of times before.

Taking a step back and looking at this code objectively, does your form really need to know about the mapper?  Does it really care _where_ that list comes from, or does it just care about the list itself?  Really all it needs is the list, so how about if we re-wrote it, something like this:

{% highlight php startinline %}
class ExampleForm
{
    const SELECT = '<select name="%s">%s</select>';
    const OPTION = '<option value="%s">%s</option>';

    protected $exampleList;

    public function __construct(ExampleList $exampleList)
    {
        $this->exampleList = $exampleList;
    }

    // ...snip...

    public function getExampleSelect()
    {
        $options = [];
        foreach ($this->exampleList as $id => $value) {
            $options[] = sprintf(self::OPTION, $id, $value);
        }

        return sprintf(self::SELECT, 'someSelect', join("\n", $options));
    }
}

$someForm = new ExampleForm($mapper->fetchList());
echo $someForm->getExampleSelect();
{% endhighlight %}

The change here is a very subtle, but very fundamental one.  As our form object doesn't ever need to know where its list is coming from, just that it receives it, our form has suddenly become a whole lot more flexible.

By telling the form upfront that we want it to use _this_ list, the implementation doesn't ever need to change, as the form doesn't care _where_ that list comes from, as long as it is always there.

Feature Envy
------------

Feature Envy[^1] is when one class uses a lot of the methods of another class, or a class performs actions on and changes the internal state of another object.  Tell, Don't Ask can be used to avoid this type of code-smell.  Here is another example that illustrates this type of problem:

{% highlight php startinline %}
class IssueTracker
{
    // ... snip ...

    public function closeBug($bug)
    {
        if ($bug->isFixed()) {
            $bug->setStatus('closed');
        }
    }
}
{% endhighlight %}

This example is a less obvious Tell, Don't Ask type code-smell, but because we're asking the object about its state and then altering it based on the result, it does qualify.  Inside the object itself this wouldn't be a problem, but outside of the object it's indicative of Feature Envy.

An object should always be responsible for altering its own state, so the above should be rewritten as:

{% highlight php startinline %}
class IssueTracker
{
    // ... snip ...

    public function closeBug($bug)
    {
        $bug->close();
    }
}

class Bug
{
    // ... snip ...

    public function close()
    {
        if ($this->isFixed()) {
            $this->setStatus('closed');
        }
    }

    protected function setStatus(...)
}
{% endhighlight %}

This changes our `IssueTracker` so that is tells the bug to close, rather than asking the bug for its state and altering it based on the result.

This also encapsulates the domain logic for the `Bug` entity (i.e. that it cannot be closed unless it is fixed) inside the `Bug` object.  This means that whenever a `Bug` object is created it can never enter an invalid state, because the public interface won't allow it, the decision is always made by the `Bug` itself, and never the object that's calling it.

Exceptions
----------

As with all rules, there are exceptions to Tell, Don't Ask.  The most obvious of which is the Parameter Object[^2].

Consider the following example:

{% highlight php startinline %}
class ExampleMapper
{
    public function store(ExampleEntity $entity)
    {
        $this->gateway->update([
            $entity->getName(),
            $entity->getValue(),
        ]);
    }
}
{% endhighlight %}

Here, we're treating our Entity as a Parameter Object, and  _asking_ it for its values, rather than _telling_ the mapper what values to use.  In this instance, it is an acceptable trade-off, as the entity shouldn't know that it's persisted, as some types of entities may never be stored anywhere (e.g. an `InMemoryEntity`), so it doesn't make sense to have a `store` method on the entity. Also, because an entity could evolve over time our method signature could be constantly evolving, or an entity could have a large number of properties that would be inconvenient to specify manually.

Conclusion
----------

If you're already doing Dependency Injection, Tell Don't Ask is going to be one of the most powerful tools you have for writing code that is as flexible and de-coupled as possible.  Add it to the things you check for in code-reviews, teach it to your junior developers, and make sure you refactor it away whenever you spot it in legacy code.

##Read Next:

* [Function vs Method vs Procedure](/2013/09/27/function-method-procedure.html)

[^1]: http://c2.com/cgi/wiki?FeatureEnvySmell
[^2]: http://c2.com/cgi/wiki?ParameterObject
