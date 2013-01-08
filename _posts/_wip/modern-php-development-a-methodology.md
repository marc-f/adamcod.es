---
layout: post
title: Modern PHP Development - A methodology
---

In the [last post](2013-01-01-modern-php-development-state-of-play) I intended to give an introduction to how I develop modern applications.  Instead I waffled on for a little too long about the state of play, and decided to separate the methodology into a separate post.  This is that post.

Getting right down the specifics.  I don't use any framework for my apps.  I also use all of them.  Let me explain.  I start with a directory structure similar to the following.

    .
    ├── src
    ├── tests
    └── vendor

Ground breaking _I know_.

This is the basic structure for pretty much every PHP library you're going to find on packagist[^1].  I then add a couple of files for phpunit and composer.

    .
    ├── composer.json
    ├── phpunit.xml
    ├── src
    ├── tests
    └── vendor

Still here? Good.  It gets more interesting I promise.  Next I add my namespaces.  Today we're going to make a bookmark REST API.  AWESOME.

    .
    ├── composer.json
    ├── phpunit.xml
    ├── src
    │   └── AdamBrett
    │       └── Bookmarks
    └── tests

So far, this isn't any different to the process of writing a library, and that's kind of the point.  Consistency.  Now things are going to get a little bit more interesting.  Next, I create a new namespace, under Bookmarks, _UseCases_, and replicate this for my tests directory.

    .
    ├── composer.json
    ├── phpunit.xml
    ├── src
    │   └── AdamBrett
    │       └── Bookmarks
    │           └── UseCases
    └── tests
        ├── AdamBrett
        │   └── Bookmarks
        │       └── UseCases
        └── bootstrap.php

Now we want to add a few use cases for our app, and as always the matching test files.

    .
    ├── composer.json
    ├── phpunit.xml
    ├── src
    │   └── AdamBrett
    │       └── Bookmarks
    │           └── UseCases
    │               ├── AddBookmark.php
    │               ├── DeleteBookmark.php
    │               ├── EditBookmark.php
    │               └── VisitBookmark.php
    └── tests
        ├── AdamBrett
        │   └── Bookmarks
        │       └── UseCases
        │           ├── AddBookmarkTest.php
        │           ├── DeleteBookmarkTest.php
        │           ├── EditBookmarkTest.php
        │           └── VisitBookmarkTest.php
        └── bootstrap.php

Notice at this point, we already know what our app is going to do, and we're able to write the code to do it and we haven't looked up any libraries on packagist, or chosen our framework or our database structure.  **That is really important**.  At this point, _we don't even know **if** our application will even use a database_, but we can already start building it.

As it happens our application will need _some_ method for storing the bookmarks.  At this point, we don't care _what_ that method is, so we'll just outline an interface we'll need.

    ├── src
    │   └── AdamBrett
    │       └── Bookmarks
    │           ├── StorageInterface.php
    │           └── UseCases
    │               ├── AddBookmark.php
    │               ├── DeleteBookmark.php
    │               ├── EditBookmark.php
    │               └── VisitBookmark.php

And we should probably add a few method definitions to our interface, so we have something to work towards.

    <?php

    namespace AdamBrett\Bookmarks;

    interface StorageInterface
    {
        public function save($entity);
        public function findAll();
        public function delete($entity);
    }

That will do.  We also need a standard object for our storage and use-cases to pass around, for that, a Bookmark entity, will do, so lets create that.

    ├── src
    │   └── AdamBrett
    │       └── Bookmarks
    │           ├── Entities
    │           │   └── Bookmark.php
    │           ├── Storage
    │           ├── StorageInterface.php
    │           └── UseCases
    │               ├── AddBookmark.php
    │               ├── DeleteBookmark.php
    │               ├── EditBookmark.php
    │               └── VisitBookmark.php

Our tree is getting a little large now, so from this point on, just assume I'm adding a test file for every new PHP file I add, unless it's an interface or something.  For now, our Bookmark entity will look like this:

    <?php

    namespace AdamBrett\Bookmarks\Entities;

    class Bookmark
    {
        public $title;
        public $link;
        public $visits;
    }

Pretty basic, but we don't need anything fancy.  Right.  We haven't added any tests yet, and responsible development is supposed to be test driven, not test-after.  Let's give this test driven development stuff a try and add the following to `tests/AdamBrett/Bookmarks/UseCases/AddBookmarkTest`.

    <?php

    namespace AdamBrett\Bookmarks\Tests\UseCases;

    use Faker\Factory as Faker;
    use Mockery;

    use \AdamBrett\Bookmarks\Entities\Bookmark;
    use \AdamBrett\Bookmarks\UseCases\AddBookmark;

    class AddBookmarkTest extends \PHPUnit_Framework_TestCase
    {
        protected $faker;

        public function setUp()
        {
            $this->faker = Faker::create();
        }

        public function testPersistsNewBookmark()
        {
            $title = $this->faker->word;
            $link = $this->faker->url;

            $bookmark = new Bookmark($title, $link);

            $storage = Mockery::mock('\\AdamBrett\\Bookmarks\\StorageInterface');
            $storage->shouldReceive('save')
                ->once()
                ->with($bookmark)
                ->andReturn(true);

            $useCase = new AddBookmark($bookmark, $storage);
            $result = $useCase->run();

            $this->assertTrue($result);
        }
    }

Woah, Woah, Woah. What's all this and where has it come from.  We seem to have skipped a few steps here.

You're right.  We have.  This is a standard PHPUnit test-case, so I'm going to assume you're familiar with those, or can read the manual[^2] on the website.

The first thing we're doing in this file is to setup our test namespace inside our application namespace.  This isn't strictly necessary, but I think it's tidier.

Then we auto-load Faker[^3] and Mockery[^4].  Both are helper libraries we can load using composer[^5].  Faker generates random but valid data for tests, and mockery is a mocking framework independent of PHPUnit.  I like to alias `Faker\Factory` as `Faker` for syntactic sugar when we instantiate it.

In our `setUp` method on the test we're getting a new instance of Faker and storing it for use in all of our tests, this should be fairly obvious.  We don't need to do this for Mockery as it uses a static interface to generate mocks.

Finally we add a test to our test-case.  Our AddBookmark use-case will have one single purpose (as will all of our use-cases, evident by their names): to add a new bookmark to the system.

It's at this point that we start to make some API decisions, so lets dissect the test one piece at a time.

    public function testPersistsNewBookmark()
    {
        $title = $this->faker->word;
        $link = $this->faker->url;

        $bookmark = new Bookmark($title, $link);

Ok, so: We've decided that we're going to need a new bookmark to test with, that means we have to decide how we're going to create a new bookmark entity.  We could have gone for something like:

    $bookmark = new Bookmark();
    $bookmark->title = $title;
    $bookmark->link = $link;

But instead I decided to setup a new bookmark via it's constructor.  This may turn out to our advantage later, it may not, either way we haven't written any code yet so we can always change our minds.

    $storage = Mockery::mock('\\AdamBrett\\Bookmarks\\StorageInterface');
    $storage->shouldReceive('save')
        ->once()
        ->with($bookmark)
        ->andReturn(true);

Next, we're going to need a storage adapter for the use-case to persist the bookmark with, so we should create a mock of our storage interface.  We know our use-case is going to need to call the save method of whatever storage adapter we use, and it's going to need to pass in the bookmark to save, so we use Mockery to express that.

Now we have to decide the best way to get these objects into our use-case so it can run the test.

The simplest way to do that is to pass them in the constructor, so we've just made an API decision for the use-case based on our tests.  Congratulations, you can now do test driven development.

    $useCase = new AddBookmark($bookmark, $storage);

Traditional PHP probably would have done something like this (in the use-case):

    <?php

    class AddBookmark()
    {
        public $bookmark;
        public $storage;

        public __construct()
        {
            $this->bookmark = new Bookmark();
            $this->storage = new Storage();
        }
    }

What chance have we got of testing that code??  Very little.  Test driven development has forced us to pass them into the constructor for the use-case.  This might seem like more work, but it comes with a massive extra benefit:  Dependency Injection.

This means we can now pass any Entity or any Storage adapter into the AddBookmark use-case and it _should_ work.  Reducing the amount of code we need to write or change if we ever decide to use MySQL instead of Sessions for storage, for example.  This is both the Composite pattern and Polymorphism.  All that stuff is actually useful in real world programming, and we're doing it and it's really easy.

Finally, we have to run the use-case, and make sure it returns true (as per our mock).  We don't need to test anything else, as Mockery will make sure our use-case is calling all the methods we've specified on the mock, with all the right parameters.

        $result = $useCase->run();

        $this->assertTrue($result);
    }



We can't use either of these (or autoload anything, as we're going to use the built in composer autoloader for our app) without loading them first, so lets get our composer.json setup and get these libraries downloaded.

    {
        "name": "adambrett/bookmarks",
        "type": "application",
        "keywords": ["bookmarks", "rest"],
        "description": "Bookmark things on the web",
        "homepage": "http://adamcod.es",
        "license": "New BSD",
        "require": {
            "php": ">=5.3.0"
        }
        "require-dev": {
            "mockery/mockery": ">=0.7.2",
            "fzaninotto/faker": "~1.0"
        },
        "autoload": {
            "psr-0": { "AdamBrett\\Bookmarks\\": "src/" }
        }
    }

This is the basic stuff we need to get composer running properly.

[^1]: http://packagist.com
[^2]: http://phpunit.de
[^3]: https://github.com/fzaninotto/Faker
[^4]: https://github.com/padraic/mockery
[^5]: http://getcomposer.com
