require 'cgi'
require 'chronic'

require 'pp'

module Jekyll
  class MarkOldPostTag < Liquid::Tag
    def initialize(tag_name, cut_off, tokens)
      super

      @cut_off_date = Chronic.parse(cut_off)
      @cut_off = cut_off
    end

    def render(context)
      post_date = context.environments.first["page"]["date"]

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

Liquid::Template.register_tag('old_post_warning', Jekyll::MarkOldPostTag)
