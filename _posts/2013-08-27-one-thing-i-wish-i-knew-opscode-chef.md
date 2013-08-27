---
layout: post
title: The One Thing I Wish I Knew When Starting To Use Chef
---

After a couple of months playing with chef, writing my own recipes, consuming, extending, and fixing bugs in other recipes, creating numerous cookbooks for use with vagrant, and even a couple I've used to provision servers, there is one thing I've picked up that I wish I'd known more than anything when I wrote [Vagrant is easy - Chef is hard](/2013/01/15/vagrant-is-easy-chef-is-hard.html).  Chef has a package manager.

##Librarian-Chef

You don't need to use git sub-modules to manage your cookbooks.  Librarian is a general purpose package manager for creating other packages managers similar to composer for PHP and bundler for Ruby.  Librarian comes with librarian-chef out of the box (although they say it will be separated out at some point) and that allows you to use a `Cheffile` to manage your cookbook dependencies like so:

    cd /my/chef/project
    echo /cookbooks >> .gitignore
    echo /tmp >> .gitignore
    librarian-chef init

You should now have a Cheffile at the root of your project.  You can then add cookbooks as dependencies and manage them with the commands `librarian-chef install` and `librarian-chef update`.  Librarian chef will create a lockfile, so use update and install [the same way as you would with composer](/2013/03/07/composer-install-vs-composer-update.html).

A basic Cheffile for one of my CentOS 6.4 Vagrant VMs looks like this:

{% highlight ruby %}
#!/usr/bin/env ruby
#^syntax detection

site 'http://community.opscode.com/api/v1'

cookbook 'yum'
cookbook 'build-essential'
cookbook 'selinux'
cookbook 'iptables'
cookbook 'openssh'
cookbook 'openssl'
cookbook 'apache2'
cookbook 'php'
cookbook 'xdebug',
    :github => 'xforty/chef-xdebug'
cookbook 'mysql'
cookbook 'database'
{% endhighlight %}

There is some redundancy built in here, as Librarian-chef will recursively resolve cookbook dependencies for you, which I think it does via `metadata.rb` (but don't quote me on that).

The package names are the names of the packages as they appear on [community.opscode.com](http://community.opscode.com), and you can include 3rd party cookbooks from github like so:

    cookbook 'xdebug',
        :github => 'xforty/chef-xdebug'

Where `xforty/chef-xdebug` is `github-username/repo-name`.

With your Cheffile in the root of your project you can run:

    librarian-chef install

Which, much like `composer install` in the PHP world, and `bundle install` for Ruby, will go off to community.opscode.com and find the matching packages, and download them straight to the `./cookbooks` directory.

Similarly, `librarian-chef update` will update your cookbooks to the latest version and install any new ones you've added to your Cheffile.

To lock a cookbook to a specific version, specify it after the comma, like so:

    cookbook 'yum', 0.1.1

This will make sure whenever you run `librarian-chef install` or `librarian-chef update` you will always get the 0.1.1 version of the yum cookbook.

##Read Next

* [Vagrant is easy - Chef is hard](/2013/01/15/vagrant-is-easy-chef-is-hard.html)
