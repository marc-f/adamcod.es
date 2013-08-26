---
layout: post
title: Mark Old Posts as Deprecated in Jekyll
---

This blog is built with jekyll[^1], which is a static blogging platform from the guys at github, and is also the engine behind github pages[^2], where this blog is hosted.

I have written a simple plugin to add a LiquidTag[^3] to render a warning for all posts that reach a certain age.  This is particularly useful for technical blogs such as this one, where the things I'm writing about can move on pretty quickly.  The way something was done a year ago isn't necessarily the way I recommend doing it today.

##Using the Plugin##

If you have a Gemfile, add the `chronic` gem and run `bundle install`. If you don’t have a Gemfile, install the gem with `gem install chronic --no-ri --no-rdoc`.

Now you can add the `mark_old_post_tag.rb` file to your `_plugins` folder.

{% highlight ruby linespans %}{% raw %}
# Mark Old Posts Liquid Tag
#
# A liquid tag for Jekyll sites to mark old posts as deprecated
#
# Usage:
#     {% mark_old_posts <time_ago_in_words|date> %}
#
# Example:
#     {% mark_old_posts 6 months ago %}
#     {% mark_old_posts 1 year ago %}
#     {% mark_old_posts 01/01/2012 %}
#
# Requires:
#     chronic gem: sudo gem install chronic --no-ri --no-rdoc
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# @author Adam Brett <adam@adambrett.co.uk>
# @license BSD-3-Clause
# @version 0.1
# @link http://gist.github.com/adambrett/
# @link http://adamcod.es/2013/02/12/mark-old-posts-liquid-tag-jekyll.html
#

require 'chronic'

module Jekyll
  class MarkOldPostTag < Liquid::Tag
    def initialize(tag_name, cut_off, tokens)
      super
      @cut_off_date = Chronic.parse(cut_off)
      @cut_off = cut_off
    end

    def render(context)
      post_date = context.environments.first["page"]["date"]

      unless (post_date.is_a? Time) && (@cut_off_date.is_a? Time)
        return ""
      end

      if context.environments.first["page"]["mark_old_post"] == false
        return ""
      end

      if post_date > @cut_off_date
        return ""
      end

      html_output_for context.environments.first["page"]["date"]
    end

    def html_output_for(post_date)
      post_date = post_date.strftime("%A, %B %d, %Y")
      return <<-HTML
<div class="alert alert-warning">
  <h4>Out Of Date Warning</h4>

  <p>
    This article was published on <strong>#{post_date}</strong> which was
    <strong>more than #{@cut_off}</strong>, this means the content may be
    out of date or no longer relevant.  You should <strong>verify that the
    technical information in this article is still current</strong> before
    relying upon it for your own purposes.
  </p>
</div>
      HTML
    end
  end
end

Liquid::Template.register_tag('mark_old_posts', Jekyll::MarkOldPostTag)
{% endraw %}{% endhighlight %}

It's not very customisable at the moment.  At some point in the future I'd like to allow you to specify the HTML markup without having to modify the plugin itself, but for now you have to modify the output of the `html_output_for` method if you want to change anything.

To render the warning message, add the tag: `{% raw %}{% mark_old_posts <time ago in words|date >%}{% endraw %}` wherever you want the HTML to be output.  You can specify any sort of date string that `chronic` will understand here, such as `6 months ago`, `12 months ago`, or an actual date such as `01/01/2012`.  You can see the example for this site on github[^4]

##Excluding Posts/Pages##

If you don't want to deprecate an old post, set `mark_old_post: false` in the YFM for the post or page and the plugin won't render anything.

[^1]: http://jekyllrb.com/
[^2]: http://pages.github.com/
[^3]: http://liquidmarkup.org/
[^4]: https://github.com/adambrett/adamcod.es/blob/57014bd1d57ce765ec6b674796abe9bfc8f93a44/_includes/article.html#L8
