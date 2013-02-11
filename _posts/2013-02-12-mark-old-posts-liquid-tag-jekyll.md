---
layout: post
title: Mark Old Posts as Deprecated in Jekyll
---

This blog is built with jekyll[^1], which is a static blogging platform from the guys at github, and is also the engine behind github pages[^2], where this blog is hosted.

I have written a simple plugin to add a LiquidTag[^3] to render a warning for all posts that reach a certain age.  This is particularly useful for technical blogs such as this one, where the things I'm writing about can move on pretty quickly.  The way something was done a year ago isn't necessarily the way I recommend doing it today.

If you have a Gemfile, add the `chronic` gem and run `bundle install`. If you don’t have a Gemfile, install the gem with `gem install chronic --no-ri --no-rdoc`.

Now you can add the `mark_old_post_tag.rb` file to your `_plugins` folder.

{% gist 4757705 mark_old_posts.rb %}

It's not very customisable at the moment.  At some point in the future I'd like to allow you to specify the HTML markup without having to modify the plugin itself, but for now you have to modify the output of the `html_output_for` method if you want to change what's output.

To render the warning message, add the tag: `{% raw %}{% mark_old_posts <time ago in words|date >%}{% endraw %}` wherever you want the HTML to be output.  You can specify any sort of date string that `chronic` will understand here, such as `6 months ago`, `12 months ago`, or an actual date such as `01/01/2012`.  You can see the example for this site on github[^4]

If you don't want to deprecate an old post, set `mark_old_post: false` in the YFM for the post or page and the plugin won't render anything.

[^1]: http://jekyllrb.com/
[^2]: http://pages.github.com/
[^3]: http://liquidmarkup.org/
[^4]: https://github.com/adambrett/adamcod.es/blob/57014bd1d57ce765ec6b674796abe9bfc8f93a44/_includes/article.html#L8
