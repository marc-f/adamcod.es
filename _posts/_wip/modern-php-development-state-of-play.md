---
layout: post
title: Modern PHP Development - State of play
---

This is part 1 of a 5 part series on Modern PHP Development.  You can find the other parts here:

2. Modern PHP Development - A Methodology
3. Modern PHP Development - Suggested Skeleton
4. Modern PHP Development - [Test Driven] Design Decisions (and how to delay them)
5. Modern PHP Development - Pulling it Together

The 2000's was all about Web 2.0.  We're all past that now and Web 2.0 is just _web_.  The rise of PHP Frameworks was a part of that early naughties renaissance and they provided structure in a world that had none.  Back then, PHP was still 4.x, had poor object oriented support, quite often interspersed with tables, and included a lot of:

    include 'common.inc';
    include 'header.php';

    ...

    include 'footer.php';

The framework revolution, with it's PHP 5-like features, _object oriented programming_ and _separation of concerns_ seemed like enlightenment, especially to a new developer fresh out of university.  Fast forward a few years, and the landscape is very different.

Today, we have composer[^1] and packagist[^2], the PHP FIG[^3], PHPUnit[^4], Behat[^5], and a whole[^6] bunch[^7] of tools[^8] to help us build websites that are _written in other languages_.  Frameworks such as Laravel4[^9] and Symfony2[^10] are totally component based and can be used for full-stack development and pulled apart to use only the parts you need.  The community has grown up and we are no-longer CakePHP or CodeIgniter developers, we're not even really PHP developers any-more, we've come a full circle and we're _web developers_ again.

So where does this leave us now?  How should we be coding our apps?  Should we build our own stacks using the best parts of all of the frameworks and components?  Doesn't that seem a little regressive?

In truth, the community is still in a transitional state.  I think things will become a little more rigid as the frameworks catch up, and the thought leaders form and publish their opinions.  Right now there are a lot of people doing things the _old_ way, still using CakePHP and CodeIgniter, or _thinking_ they're doing it the right way, using composer with one of the more recently updated frameworks such as ZendFramework2 or Symfony2.  A few _though leaders_ are rolling their own with components from all over the place, and that's great too, but a little too regressive and reminiscent of _roll-your-own-framework_ for my liking.

This post was originally going to be a how-to guide to my version of modern PHP coding, but my introduction has waffled on for a few too many paragraphs, so instead I'll end it here with a quick list of my requirements for modern PHP development, and I'll show how I implement them in another post.

In no particular order:

    * Easy to follow
    * Easy to understand
    * Component/Library Based
    * Framework Independent
    * Unit Tested (Easily)

Go (here)[2013-01-08-modern-php-development-a-methodology] to see how I put this into practice.

[^1]: http://getcomposer.com
[^2]: http://packagist.com
[^3]: http://www.php-fig.org
[^4]: http://phpunit.de
[^5]: http://behat.org
[^6]: http://www.opscode.com/chef/
[^7]: http://www.vagrantup.com/
[^8]: https://github.com/mojombo/jekyll
[^9]: http://laravel.com/
[^10]: http://symfony.com/
