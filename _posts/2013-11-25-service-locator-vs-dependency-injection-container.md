---
layout: post
title: Service Locator vs Dependency Injection Container (or Tell, Don't Ask Part 2)
---

Last week I wrote about [Tell Don't Ask](/2013/11/22/tell-dont-ask.html) type code smells and why you should avoid them.  Tell Don't Ask is also present in another more wide-spread form: Service Locators.

Dependency Injection is a hot topic in web development, and all of the current generation frameworks have some sort of Dependency Injection Container to attempt to simplify this for you.  The idea behind the Dependency Injection Container is that it knows how to create all of your objects and their dependencies, so you can easily get an object with all of its dependencies with one simple call.  Let's take a look at an example:

{% highlight php startinline %}
class ExampleController
{
    protected $request;
    protected $response;

    public function __construct()
    {
        $this->request = new ExampleRequest($_GLOBALS);
        $this->response = new ExampleResponse(new ExampleView());
    }
}

$router = new ExampleRouter($_SERVER);

call_user_func_array(
    [new $router->getControllerName(), $router->getActionName()],
    $router->getParams()
);
{% endhighlight %}

This is a fairly typical, if somewhat simplified and fictitious controller and dispatch process for a 2006 era framework.  Objects were created when a class was constructed, and little if anything was injected.

Current generation frameworks have learnt a great deal, and the above would now be more likely to be injected in some form, maybe something like this:

{% highlight php startinline %}
class ExampleController
{
    protected $request;
    protected $response;

    public function __construct(ExampleContainer $container)
    {
        $this->request = $container->request();
        $this->response = $container->response();
    }
}

$container = new ExampleContainer();

$container->request = function () {
    return new ExampleRequest($_GLOBALS);
};

$container->router = function () {
    return new ExampleRouter($_SERVER);
}

$container->view = function () {
    return new ExampleView();
}

$container->response = function () use ($container) {
    return new ExampleResponse($container);
}

$router = $container->router();
$controller = $router->getController();

call_user_func_array(
    [new $controller($container), $router->getActionName()],
    $router->getParams()
);
{% endhighlight %}

Uh oh!  Did you spot the code smell?  That's right, we're asking our container for the request and response, instead of telling it what request and response to use, and that's a violation of Tell Don't Ask.

What's the Difference?
----------------------

I'm covering this here and now, because when I explain away the above code-smell it's important you understand the distinction between the two.  I have searched The Internet quite a bit for a definitive answer to the question _what's the difference between a service locator and a dependency injection container?_ and turned up a whole bunch of Stack Overflow answers and blog posts which gave similar wishy-washy, contradictory or uncertain answers.

I'm going to stick my neck on the line and give a definitive answer: **There is no difference between a Service Locator and a Dependency Injection Container**, at least in terms of how they are implemented.

The bottom line is, **the difference between a Service Locator and a Dependency Injection Container is how you consume them**.  The implementation of both can be identical, but with a Service Locator you inject the container and _ask_ it for the object you want, whereas with a Dependency Injection Container you use it to construct objects, but a Dependency Injection Container should only ever call itself, and never be called by any other objects.

In other words, your application is aware it's using a Service Locator, but your application should be totally un-aware that it's using a Dependency Injection Container.

Looking at our above code example, that code is using `$container` as a Service Locator.  It's expecting it to be injected, then _asking_ it for the Request and Response Objects.

We can re-write our example to use our container object as a Dependency Injection Container with some very small changes:

{% highlight php startinline %}
class ExampleController
{
    protected $request;
    protected $response;

    public function __construct(ExampleRequest $request, ExampleResponse $response)
    {
        $this->request = $request;
        $this->response = $response;
    }
}

$container = new ExampleContainer();

$container->request = function () {
    return new ExampleRequest($_GLOBALS);
};

$container->router = function () {
    return new ExampleRouter($_SERVER);
}

$container->view = function () {
    return new ExampleView();
}

$container->response = function () use ($container) {
    return new ExampleResponse($container->view());
}

$router = $container->router();
$controllerName = $router->getController();
$controller = new $controllerName($container->request(), $container->response());

call_user_func_array(
    [$controller, $container()->router()->getActionName()],
    $container->router()->getParams()
);
{% endhighlight %}

See, this is now a Dependency Injection Container, not a Service Locator, but the implementation hasn't changed at all.  People have such a hard time telling the difference between the two because they're really the same thing.  The only distinction is that one is used in a way that violates the Tell, Don't Ask principle, and the other is not.

Why Bother?
-----------

So, why use a container at all, why not just use straight up dependency injection?  Well, you can, but the point of a dependency injection container _for your application_ (n.b. you should never use a container in library code) is for complex dependency graphs.  In our very simple and trivial example we're constructing the `ExampleController`, which requires the `ExampleResponse` object which then depends on the `ExampleView` object. Now imagine `ExampleView` depends on `ExampleCache` and `ExampleTwigAdapter`, which each in turn depend on `ExampleFileCache` and `Twig` itself.  Let's take a look at that example using regular old Dependency Injection:

{% highlight php startinline %}
$request = new ExampleRequest($_GLOBALS);
$router = new ExampleRouter($_SERVER);
$fileAdapter = new ExampleFileCache();
$cache = new ExampleCache($fileAdapter);
$twig = new Twig();
$twigAdapter = new ExampleTwigAdapter($twig);
$view = new ExampleView($cache, $twigAdapter);
$response = new ExampleResponse($view);
$controller = new ExampleController($request, $response);
{% endhighlight %}

That's a whole lot of objects to create every time you want to create a controller.  Sure, you could shorten it by not creating the variables and injecting the new objects directly, but that doesn't save you much:

{% highlight php startinline %}
$router = new ExampleRouter($_SERVER);
$controller = new ExampleController(
    new ExampleRequest($_GLOBALS),
    new ExampleResponse(
        new ExampleView(
            new ExampleCache(
                new ExampleFileCache()
            ),
            new ExampleTwigAdapter(
                new Twig()
            )
        )
    )
);
{% endhighlight %}

You might think that's not too bad, but imagine you've created a new cache object in 5 or 6 different places and then want to update it to use `ExampleMemcache`.  With a Dependency Injection Container you only create your objects in one place, so you only ever need to update them in one place:

{% highlight php startinline %}
$container->cacheAdapter = function () {
    return new ExampleFileCache();
};

$container->cache = function () use ($container) {
    return new ExampleCache($container->cacheAdapter());
};
{% endhighlight %}

Becomes:

{% highlight php startinline %}
$container->cacheAdapter = function () {
    return new ExampleMemcache();
};

$container->cache = function () use ($container) {
    return new ExampleCache($container->cacheAdapter());
};
{% endhighlight %}

And our application gets updated everywhere the cache is injected.  Awesome.  But the Dependency Injection Container has another added benefit, because all of our object construction is pre-defined, constructing our previously complicated controller becomes as simple as:

{% highlight php startinline %}
new ExampleController($container->request(), $container->response());
{% endhighlight %}

Our container then knows what dependencies `ExampleRequest` and `ExampleResponse` are expecting, and in turn the dependencies of those objects and so on and so forth.

Conclusion
----------

Lots of people call Service Locator an anti-pattern, mostly because it hides your dependency graph away, and whilst it's true, it does, the same could also be argued (although less so) about Dependency Injection Containers.

The most important downside of a Service Locator is the violation of the Tell, Don't Ask principle, and [as I said last week](/2013/11/22/tell-dont-ask.html), due to the tight coupling that it introduces, violation of Tell, Don't Ask can often be fatal, and that's why you should probably avoid it in your next application.

##Read Next:

* [Tell, Don't Ask](/2013/11/22/tell-dont-ask.html)
