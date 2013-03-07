---
layout: post
title: "\"composer update\" vs \"composer install\""
---

Unless you've been living under a rock, you know about composer[^1] and packagist[^2] for managing dependencies in PHP.  A few days ago, an issue[^3] was closed and merged into master which changes the default behaviour of `composer update` to be functionally equivellent to `composer update --require-dev`.  This confused a few folks[^4], and here's why:

_You should only ever run `composer update` to get the newest versions of your dependencies, not to install them_.

What's not massively clear (or at least wasn't early on) in the composer documentation[^5] is the difference between `composer install` and `composer update` and the relevancy of `composer.lock`.  This is exasperated by composer displaying a warning when running `composer install` with a lockfile present and changes in `composer.json`:

![composer install message](/img/posts/composer-install-message.png)

Not very clear.

Here's a fairly standard composer work-flow:

1. Add `composer.json` with some dependencies
2. Run `composer install`
3. Add some more dependencies
4. Run `composer update` as you've updated your dependencies

This is the _right_ way to use composer.  If you are using composer to deploy your dependencies into a production environment (which many people are), based on this work-flow you may incorrectly assume that you deploy your updated `composer.json` to production and run `composer update` again.  This is the _wrong_ way to use composer.

What's really happening when you run `composer update` is that it's fetching the newest version of your dependencies as specified by `composer.json`.

If you've been testing your code with monolog 1.2, and monolog 1.3 gets released, unless you're very explicit in your `composer.json` composer will fetch monolog 1.3.  Now imagine that a backward incompatible change or bug is introduced with monolog 1.3.  Suddenly your dependencies have broken your production environment. Not good.

What you really need to do is deploy your updated `composer.lock`, and then re-run `composer install`.  You should never run `composer update` in production.  If however you deploy a new `composer.lock` with new dependencies and/or versions (after having run `composer update` in dev) and _then_ run `composer install` composer will update and install new your new dependencies.

![composer install update lockfile](/img/posts/composer-install-update.png)

Whenever composer generates a new `composer.lock` it _locks_ you to a specific set of dependencies and the latest versions of those dependencies it can resolve.

This means if your `composer.json` specifies `monolog/monolog: 1.*`, and it installs monolog 1.2, monolog 1.2 will be included in your lockfile.  From then on when you run `composer install` you will only ever get monolog 1.2, even after monolog 1.3 has been released.

Here's the basic workflow:

![composer install update flow](/img/posts/composer-install-flow.png)

Not too complicated.

Now we can come a full circle back to the issue that prompted this post.  As we never run `composer update` in production, it follows that whenever we run it we will be in our dev environment, and the automatic inclusion of the `--require-dev` flag on `composer update` now makes sense.

If you're still not happy, you can ignore all of this and add the `--no-dev` flag to reverse the behaviour.

Questions? Comments? Head over to [twitter](http://twitter.com/sixdaysad) to let me know what you think.

[^1]: http://getcomposer.org
[^2]: http://packagist.org
[^3]: https://github.com/composer/composer/pull/1644
[^4]: https://github.com/composer/composer/pull/1644#issuecomment-14347890
[^5]: http://getcomposer.org/doc/
