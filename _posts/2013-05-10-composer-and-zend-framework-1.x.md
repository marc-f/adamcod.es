---
layout: post
title: Zend Framework 1.x and Composer
---

Using Zend Framework 1.x with composer is fairly straight forward, even if not immediately obvious.  First, let's create a new Zend Framework 1 project in the standard way, using the zf tool:

    zf create project zend-composer
    cd zend-composer/public
    php -S 127.0.0.1:8000

Now visit http://127.0.0.1:8000 in your browser and you should see the familiar "Welcome to the Zend Framework!" page.

![Welcome to Zend Framework](/img/posts/welcome-to-zend-framework.png)

The default project is loading Zend Framework from your include path, so first off, let's break that.  Edit `./public/index.php` and comment out the `get_include_path()` line, like so:

    // Ensure library/ is on include_path
    set_include_path(implode(PATH_SEPARATOR, array(
        realpath(APPLICATION_PATH . '/../library'),
        // get_include_path(),
    )));

Refresh your browser and you should now be getting an error similar to this:

![Zend missing include path](/img/posts/zend-include-path.png)

That's good, now we're going to install Zend Framework via composer and add that to our include path.  Close the PHP server using `Ctrl+C` and run the following[^1]:

    cd ..
    composer init

Fill in the details for your project until you get to:

    Would you like to define your dependencies (require) interactively [yes]?

Press `return` for yes, then search for `zendframework1`:

![Search for dependencies](/img/posts/search-dependencies.png)

Enter the number for the line that matches `zendframework/zendframework1` which for me is `0`, and probably will be for you too.

Next, enter the version you require, use `1.*` for the latest 1.x version[^2].

At the next `Search for a package []:` prompt, press `return`, we don't want to define any dev dependencies yet, so type `no` at the next prompt then `return` to confirm generation.

You should end up with a file in your project root called `composer.json` that looks similar to this:

    {
        "name": "adam/zend-composer",
        "require": {
            "zendframework/zendframework1": "1.*"
        },
        "authors": [
            {
                "name": "Adam Brett",
                "email": ""
            }
        ]
    }

Now type `composer install` to get things started.  Composer will go away and download a fresh copy of the latest version of Zend Framework and place it in your projects `./vendor` directory.

We can check like so:

    $ tree vendor -L 1
    vendor
    ├── autoload.php
    ├── composer
    └── zendframework

Great.  We're almost done.  Now remember that line we commented out?  We need to update that to point at our new Zend Framework download.  The actual library lives in `./vendor/zendframework/zendframework1/library` so open up `./public/index.php` and change the commented line to match:

    // Ensure library/ is on include_path
    set_include_path(implode(PATH_SEPARATOR, array(
        realpath(APPLICATION_PATH . '/../library'),
        realpath(APPLICATION_PATH . '/../vendor/zendframework/zendframework1/library')
    )));

Now if we restart the PHP server using:

    cd public
    php -S 127.0.0.1:8000

And refresh the site in our browser, we should see the "Welcome to Zend Framework" page again.  Success!

There's one last thing to do if you want to consume other composer packages in Zend Framework, and that's to add composer's autoloader.  Edit `./public/index.php` again and add the autoloader around line 17, just above the `require_once` for `Zend_Application`:

    require_once realpath(APPLICATION_PATH . '/../vendor/autoload.php');

    /** Zend_Application */
    require_once 'Zend/Application.php';

Now repeat these steps in `./tests/bootstrap.php` and we're all done!

## Read Next

* [Zend Framework 1.x, PHPUnit 3.4 and PHPUnit 3.7 side-by-side](/2013/05/30/zend-1.x-phpunit-3.4-and-3.7-composer.html)

## Further Reading

* [Getting start with composer](https://getcomposer.org/doc/00-intro.md)
* [Packagist](https://packagist.org/)

[^1]: I'm assuming you have composer [installed system wide](https://github.com/composer/composer#global-installation-of-composer-manual)
[^2]: Zend Framework 2 is a [separate composer package](https://packagist.org/packages/zendframework/zendframework), rather than a version 2.x, so it's impossible to install ZF2 via the zendframework1 package.
