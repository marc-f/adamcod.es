---
layout: post
title: How to Build a Rock Solid Application Domain Model Layer
---

In this post we're going to go in to some depth on how to create a domain model layer for your application.  We're going to look at it in a fairly high level and agnostic way, this should translate to pretty much any framework or ORM library, maybe even some languages other than PHP, and by the end of this post you should be empowered to go away and build a rock solid model layer for your own application.

##What is a Domain Model Layer?

Before we can start, we need to fully understand what a domain model layer is.  There's been a lot of debate for quite a while now on what constitutes a model layer.  For those of you up to speed, the model layer is the M in MVC.  Well kind of.  To fully understand what a model layer is you need to understand you cannot implement MVC in PHP[^1], nor most server side languages for that matter.

True MVC, as was designed for smalltalk in the 70s and 80s[^2], is about desktop applications, and the thing that desktop applications have that web applications do not is _state_.  True MVC is far closer to what javascript libraries such as backbone and angularjs do; here's a quick breakdown of roughly how it works:

{% flickr 9348097407 %}

The user looks at the view, all interactions (events) are handled by the controller, which then updates the model with the result of those actions, and finally the model reflects those changes in the view.

Conversely, web-based MVC looks more like this:

{% flickr 9348097417 %}

This is actually a pattern called Model-View-Presenter[^3].  Here, the Presenter ("Controller" in common framework terms) requests information from the Model, does what it needs to do with it, then passes it to the view for rendering.  The key difference being where the model is accessed from.

**The important take-away from this** is that web frameworks don't really implement MVC, and actually build on a misunderstanding of the paradigm which was popularised by Rails.

Not only this, but they don't really implement a model layer either.  Active Record is not a model layer, and a model layer is more than a single file per table, in-fact, your underlying persistence layer might not even consist of tables.

So now we've decided what a domain model isn't, what actually is a domain model?

In proper MVC (and MVP), a model layer consists of a number of objects and layers, all relating to either business logic, or entity persistence.  Those two areas form the main two layers of a domain model: the business logic layer, and the persistence layer.

##Business Logic

The business logic layer is all about the rules of your business (or application).  This contains your Domain Objects[^4], and probably not a lot else.  The main purpose of these objects is to enforce your business rules.

This is all of your classic object oriented programming clichés bundled up.  You make your `$tree->grow()` and your `$car->drive()` or `$person->walk()`.  `$car->maxSpeed` cannot exceed 70 and so on, we'll get on to why later.

Domain objects should be able to validate themselves, and if at all possible, should not be allowed to enter an invalid state.  The business logic layer should know nothing of the underlying data-structures that support them; this is really important.

##Persistence Layer

The persistence layer is all about mapping business objects to the underlying storage.  This layer comprises of the following objects:

* Mappers
* Entities
* Gateways
* Services (maybe)

The interaction between them goes something like this:

{% flickr 9351187236 %}

On a simple level, your application calls your service, your service then constructs or manipulates your domain object and passes it to your mapper.  Alternatively for a find operation your service may call your mapper and receive a domain object in return.

Your mapper then constructs an entity from your domain object (they key difference between entities and domain objects being that entities are able to identify themselves and are otherwise dumb), and then passes it on to the correct gateway.  For find operations your mapper may just call the gateway and receive an entity in return.  It will then map that entity to a domain object and return it.

Gateways are the only layer with knowledge of the underlying data structure.  They know how to store and retrieve data from your database, REST API, whatever it is your happen to be using.  They should always receive and return entities.

There will likely be a one-to-one relationship between gateways and the underlying data structure.  That is, one per text file, table, API end point and what not, but there doesn't have to be.

There should not be a one-to-one relationship between mappers, domain objects, and the underlying data-structure.  These layers shouldn't really know anything about the underlying data-structure at all.  As far as they're concerned you could be storing and retrieving their data from PHP Sessions.  They don't care.  More on that later.

Another quite important factor in this diagram is that objects should only know how to use the object directly below them.  That means the application should only know how to use the service, the service only knows how to use the mapper, and the mapper the gateway.  None of them should know or care about the layers above them.

##Writing the Code

When writing the code for your application's domain model layer, you want to work from the application out.  The key to being successful in creating a rock-solid design is delaying the implantation of the lower layers for as long as possible.

What do I mean by that?

When using test driven development you are able to define the API of your lower-down objects by creating mocks.  That means you can create all of your controllers/presenters, test them using unit tests, and all of the services that they call can be injected as mocks, without having to write any code for the services.

Once you're done at the controller level, you can start to implement your services, again using TTD you can write all of your service layer code, and injecting mocks in place of your mappers, and so on and so forth down through the layers.

If you want to start testing visually, create temporary objects that use PHP sessions or something similar.  You will be amazed at how fast you're able to get a working application and how easy it is to refactor it when working in this way.

##Learn By Doing (A Sample Application)

Let's build a blog!

We're not really going to build a blog.

Let's take a look at how we'd approach building a blog using the delaying techniques we mention above.

###Application Layer

This isn't really our domain model, but it will set some context for us, so let's go as quickly as we can.

We'll start with our blog controller:

    <?php
    //tests/Controllers/BlogTest.php

    namespace Tests\Controllers;

    class BlogTest extends \PHPUnit_Framework_TestCase
    {
        protected $fixture = array(
            'Post One',
            'Post Two',
            'Post Three',
            'Post Four',
            'Post Five',
        );

        public function testIndexListsFirstFivePosts()
        {
            $serviceMock = $this->getMock('stdClass');
            $serviceMock->expects($this->once())
                ->method('getLatestFivePosts')
                ->will($this->returnValue($this->fixture));

            $controller = new Application\Controllers\Blog($serviceMock);

            $this->assertEqual($this->fixture, $controller->index());
        }
    }

Great, our blog controller is responsible for listing the latest 5 posts on the homepage of our blog, and it will fetch them from the service mock, which we will inject via the constructor, and then return them to our view.  This all seems reasonable so far, so let's write our implementation:

    <?php
    // Controllers/Blog.php

    namespace Application\Controllers;

    class Blog
    {
        protected $service;

        public function __construct($service)
        {
            $this->service = $service;
        }

        public function index()
        {
            return $this->service->getLatestFivePosts();
        }
    }

Nice and simple!  Just how I like it.  We just wrote and tested our controller without actually writing the service, or defining any database type stuff.  We want to keep this up.  Let's design a posts controller to display a specific post, and add a new one.

    <?php
    // tests/Controllers/Post.php

    namespace Tests\Controllers;

    class Post extends PHPUnit_Framework_TestCase
    {
        protected $fixture = array(
            'title' => 'Post One',
            'body' => 'Lorum ipsum dolor sit amet.'
        );

        protected $slug = 'post-one';

        public function testViewPostDisplaysPostAndComments()
        {
            $serviceMock = $this->getMock('stdClass');
            $serviceMock->expects($this->once())
                ->method('getPostBySlug')
                ->with($this->equalTo($this->slug))
                ->will($this->returnValue($this->fixture));

            $controller = new \Application\Controllers\Post($serviceMock);

            $this->assertEqual($this->fixture, $controller->view($this->slug));
        }

        public function testCanAddNewPost()
        {
            $serviceMock = $this->getMock('stdClass');
            $serviceMock->expects($this->once())
                ->method('create')
                ->with($this->equalTo($this->fixture))
                ->will($this->returnValue(true));

            $controller = new \Application\Controllers\Post($serviceMock);

            $this->assertTrue($controller->add($this->fixture));
        }
    }

Okay, so we've designed a post controller that will again inject a service via its constructor and will then call a method to return the post, passing in the URL slug, and will return the value to the view.

Our add action will call the `create` method on our service with our post-data (the fixture) and will return true if successful.  Still seems reasonable, even though the add action is quite cut down.  Let's write the implementation.

    <?php
    // Controllers/Post.php

    namespace Application\Controllers;

    class Post
    {
        protected $service;

        public function __construct($service)
        {
            $this->service = $service;
        }

        public function view($slug)
        {
            return $this->service->getPostBySlug($slug);
        }

        public function add($post)
        {
            return $this->service->create($post);
        }
    }

Well that was easy, and remarkably similar to our Blog controller.  Let's quickly abstract away some of the common functionality, so we can get back on track:

    <?php
    // Controllers/AbstractController.php
    abstract class AbstractController
    {
        protected $service;

        public function __construct($service)
        {
            $this->service = $service;
        }
    }

    // Controllers/Blog.php
    class Blog extends AbstractController
    {
        public function index()
        {
            return $this->service->getLatestFivePosts();
        }
    }

    // Controllers/Post.php
    class Post extends AbstractController
    {
        public function view($slug)
        {
            return $this->service->getPostBySlug($slug);
        }

        public function add($post)
        {
            return $this->service->create($post);
        }
    }

Right.  That's our application complete and you have some context.  Hopefully you can see by now how we're going to start constructing our Domain Model Layer and delaying the implementation.  Let's move on.

##Service Layer

The service layer is all about taking application requests, constructing our Domain Objects, then passing them on to our mapper.

Let's assume that your application is fairly basic like our example blog, you can probably construct your Domain Objects and set the values actually inside the service actions.  I don't really care how you set the values on your domain object, you can inject them, use setters, or just set the properties; it's not important.

If you have a more complex application, there might be a number of ways you can receive data from your application, and you'll need to reliably translate that to a Domain Object.  This is an ideal use-case for a factory.  For our example, I'm going to do both, so you can see what it looks like.

    <?php
    // tests/Services/Blog.php

    namespace tests/Services;

    class BlogTest extends \PHPUnit_Framework_TestCase
    {
        protected $postFixture;
        protected $latestFixture = array(
            'Post One',
            'Post Two',
            'Post Three',
            'Post Four',
            'Post Five',
        );

        public function setUp()
        {
            $this->postFixture = new \stdClass;
            $this->postFixture->slug = 'post-one';
            $this->postFixture->title = 'Post One';
            $this->postFixture->body = 'Lorum Ipsum Dolor Sit Amet';
        }

        public function testGetLatestFivePosts()
        {
            $mapperMock = $this->getMock('stdClass');
            $mapperMock->expects($this->once())
                ->method('findLatest')
                ->with($this->equalTo(5))
                ->will($this->returnValue($this->latestFixture));

            $service = new \Application\Service\Blog($mapperMock);
            $this->assertEqual($this->fixture, $service->getLatestFivePosts());
        }

        public function testCreateCallsInsert()
        {
            $mapperMock = $this->getMock('stdClass');
            $mapperMock->expects($this->once())
                ->method('insert')
                ->with($this->equalTo($this->postFixture))
                ->will($this->returnValue(true));

            $service = new \Application\Service\Blog($mapperMock);
            $this->assertTrue($service->create(array $this->postFixture));
        }
    }

There are a few important things we need to note here:

1. We only need one test for both the simple version of Domain Object creation, and the Factory version.  This is because we should be testing functionality, not implementations, and those two changes are implementation changes, not changes to functionality.

2. We're casting `$this->postFixture` to an array, but telling the mapper mock to expect an object.  This is because it's the job of the service to take our post-data from our controller and turn it into a domain object, and post-data comes in as an array.  Now in a real application, there's nothing to say that the post-data will come in in the same format as the object we're going to be creating.  It's part of the job of the service to make sure that it ends up that way.  I'm just doing it this way for the convenience of my examples.

3. We're only using one service for two different controllers.  There's no hard and fast rule for how many to use with each, or how to split them up.  Try to follow the single responsibility principle[^5] and you should do fine.

4. I've skipped the `getPostBySlug` method for simplicity of the examples.  It would be very similar to the `getLatestFivePosts` method anyway.

Okay, so our tests are written, let's give the implementation a go:

    <?php
    // Services/Blog.php

    namespace Application\Services;

    class Blog
    {
        protected $mapper;

        public function __construct($mapper)
        {
            $this->mapper = $mapper;
        }

        public function getLatestFivePosts()
        {
            return $this->mapper->findLatest(5);
        }

        // simple
        public function add($postData)
        {
            $post = new \Application\DomainObjects\Post;
            $post->slug = $postData['slug'];
            $post->title = $postData['title'];
            $post->body = $postData['body'];

            return $this->mapper->insert($post);
        }
    }


That's fairly straight forward, but it still won't pass our tests, as we're creating a new object that doesn't exist yet.  We'll sort that in a moment, but let's look at the alternative version using a factory:

    <?php
    // Services/Blog.php

    namespace Application\Services;

    class Blog
        protected $mapper;

        public function __construct($mapper)
        {
            $this->mapper = $mapper;
        }

        // factory
        public function add($postData)
        {
            $post = \Application\DomainObjects\PostFactory::createFromPost($postData);
            $this->mapper->insert($post);
        }
    }

and the factory:

    <?php
    // DomainObjects/PostFactory.php

    namespace Application\DomainModel;

    class PostFactory
    {
        public static function createFromPost($postData)
        {
            $post = new Post;
            $post->slug = $postData['slug'];
            $post->title = $postData['title'];
            $post->body = $postData['body'];

            return $post;
        }
    }

Now I have to caveat this: Singletons (as shown above with the PostFactory), are bad object oriented design.  They are basically globals and should be avoided at all costs.  You could inject the factory into your service, and that's the simple way to do it, or in more complicated applications where you'll end up in dependency hell, you can use the Facade Pattern[^6] as used by the Laravel 4 framework[^7] to give you some syntactic sugar without the un-testability of the global.




[^1]: http://stackoverflow.com/questions/7621832/architecture-more-suitable-for-web-apps-than-mvc/7622038#7622038
[^2]: http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller#History
[^3]: http://www.wildcrest.com/Potel/Portfolio/mvp.pdf
[^4]: http://c2.com/cgi/wiki?DomainObject
[^5]: http://en.wikipedia.org/wiki/Single_responsibility_principle
[^6]: http://en.wikipedia.org/wiki/Facade_pattern
[^7]: http://laravel.com/docs/facades
