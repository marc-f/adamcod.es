---
layout: post
title: Why PSR-3 Doesn't Make Sense and Why I'm Excited About It.
---

PSR-3[^1] doesn't make sense because people aren't writing the right kind of PHP yet.  By this I mean that people aren't writing the kind of PHP that would benefit from having a standard logging interface across multiple frameworks and libraries.

Most people are still writing Symfony PHP, or CakePHP, or CodeIgniter, or Zend or... you get the picture.  Why would it matter if they have a logger that they can use across all of the libraries and frameworks.  They only use the one.

Some people use a slightly more modern approach, they use one of the more up-to-date frameworks with PSR-0 and composer support.  To them, it makes more sense.  If they're using a library from packagist, wouldn't it be great if you could tell (Symfony\|Zend\|Laravel) to use the same logger as all of your libraries when it was writing its logs, then you'd only need _one_ logger instance for all your apps, and it would write all your logs to the one place.  Great.

I think this is likely where the original proposal came from, and that _is_ great, but I still think it misses the point.

Imagine, if you would, the following application:

    .
    ├── dist
    │   ├── rest <-- SlimPHP
    │   │   ├── README.md
    │   │   ├── composer.json
    │   │   ├── composer.lock
    │   │   ├── logs
    │   │   ├── public
    │   │   ├── templates
    │   │   └── vendor
    │   └── web <-- CakePHP
    │       ├── README.md
    │       ├── app
    │       ├── build.properties
    │       ├── build.xml
    │       ├── index.php
    │       ├── lib
    │       ├── plugins
    │       └── vendors
    ├── logs
    ├── src <-- My Application Code
    │   └── AdamBrett
    │       └── Application
    │           ├── Entities
    │           ├── StorageAdapters
    │           └── UseCases
    ├── tests
    └── vendor <-- My 3rd Party Libraries
        └── Psr
            └── Log

Now this is the beginnings of a modern PHP application.  The source of the application, the bulk of the logic and entities are stored in the `src` directory.  The REST API is delivered by the micro-framework SlimPHP, and the web application is delivered by CakePHP.

They both have very little controller logic.  A controller action would basically setup a `StorageAdapter` (imagine `CakeStorage` and `IdiormStorage` objects both implementing `StorageInterface`), and pass it along to the relevant use-case - potentially with any relevant entity object - to perform the action required.  No repetition of code, a highly testable modern application.

Then you look at the logging situation.  Slim is logging to `./dist/rest/logs`, Cake is logging to `./dist/web/app/tmp/logs`, and your use-cases use monolog[^2] to log to somewhere else.  Yuk.

The guys in camp 2, who kind of gets PSR-3, are now thinking: Wouldn't it be great if we could just use monolog throughout to log to `./logs`?  That's what PSR-3 is for.

No! _No cookies for you_.

I don't want to sift through my logs and find entries from Slim, Cake, and my own code.  If one of my users has an issue with the API why would I care about Cake's logs when Cake only handles my web requests?

For that matter - why would I care about the logs my use-cases produce when called from Cake?  I don't.  At all.  What I want, what I _really_ really want, is to say: Hey, I have a problem with the REST API, let's check through the SlimPHP logs _and_ see the logs from any use cases it calls.  All in one place.  Together.  In date order.  As it happened.

For me, _that's_ what's exciting about PSR-3.  I don't want all my logs in one place.  I want to see my use-cases in Cake's logs when I'm debugging my web app, and I want to see my use-cases in Slim's logs when I'm debugging my REST API.

Once SlimPHP and CakePHP support the PSR-3 logger standard internally, I want to pass _their_ loggers to _my_ use-cases and get the output _I_ want in the format _I_ want - in the location I expect it - with a high signal-to-noise ratio.

The PSR-3 LoggerInterface has the potential to give me that.  And I think that's pretty exciting.

[^1]: https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-3-logger-interface.md
[^2]: https://github.com/Seldaek/monolog
