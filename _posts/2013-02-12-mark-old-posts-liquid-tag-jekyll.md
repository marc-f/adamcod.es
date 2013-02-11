---
layout: post
title: Mark Old Posts as Deprecated in Jekyll
---

This blog is built with jekyll[^1], a static blogging platform from the guys at github, and is also the engine behind github pages[^2], where this blog is hosted.

I have written a simple plugin to add a LiquidTag[^3] to render a warning for all posts that exceed a certain date threshold.  This is particularly useful for technical blogs such as this one, where the things I'm writing about can move on pretty quickly, so the way something was done a year ago isn't the way I recommend doing it today.

I wrote this plugin because I couldn't find one that already exists, so I figured someone else might find it useful.

It requires the `chronic` gem, so if you have a Gemfile, add the chronic gem and run `bundle install`. If you don’t have a Gemfile, install the gem with `gem install chronic --no-ri --no-rdoc`.

Now you can add the `mark_old_post_tag.rb` file to your `_plugins` folder.

{% gist 4757705 mark_old_posts.rb %}

It's not very customisable at the moment.  At some point in the future I'd like to allow you to specify the HTML markup without having to modify the plugin itself, but for now you have to modify the output of the `html_output_for` method.

To render the warning message, add the tag: `{% mark_old_posts <time ago in words|date>%}` wherever you want the HTML to be output.

[^1]: http://jekyllrb.com/
[^2]: http://pages.github.com/
[^3]: http://liquidmarkup.org/
