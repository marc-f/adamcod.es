---
layout: post
title: Modern PHP Development - A methodology
---

In the [last post](2013-01-24-modern-php-development-state-of-play) I intended to give an introduction to how I develop modern applications.  Instead I waffled on for a little too long about the current state of play, and decided to separate the methodology into a separate post.  This is that post.

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

That will do.  We also need a standard object for our storage and use-cases to pass around, for that, a Bookmark entity will do, so lets create that.

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

Pretty basic, but we don't need anything fancy.  Right.  We haven't added any tests yet, and responsible development is supposed to be test driven, not test-after.

So far, we've got our basic application structure, and it looks just like any modern PHP library out there, not really an application.  As we start to fill in our use-cases and tests, we may want to add packages from Packagist.  We can do this, and we would expect them to go into the normal ./vendor location.  In part 5, we will add another directory, `dist` which will tie everything together, giving you a root structure a little like this:

    .
    ├── composer.json
    ├── dist
    ├── phpunit.xml
    ├── src
    ├── tests
    └── vendor

For now, let's move on and give this test driven development stuff a try with the next part of this series: [Test Driven Design Decisions (Coming soon)].

[^1]: http://packagist.com

