---
layout: post
title: Chef Best Practices
---

After a couple of months playing with chef, writing my own recipes, consuming, extending, and fixing bugs in other recipes, creating numerous cookbooks for use with vagrant, and even a couple I've used to provision servers, these are the things I've picked up that I wish I'd known when I wrote [Vagrant is easy - Chef is hard (Part 2)](/2013-01-15-vagrant-is-easy-chef-is-hard-part-2.html).

##Librarian-Chef##

You don't need to use git sub-modules to manage your cookbooks.  Librarian is a general purpose package manager for creating other packages managers similar to composer for PHP and bundler for Ruby.  Librarian comes with librarian-chef out of the box (although they say it will be separated out at some point) and that allows you to use a `Cheffile` to manage your cookbook dependencies like so:

    cd /my/chef/project
    echo /cookbooks >> .gitignore
    echo /tmp >> .gitignore
    librarian-chef init

You should now have a Cheffile at the root of your project.  You can then add cookbooks as dependencies and manage them with the commands `librarian-chef` install and `librarian-chef update`.  Librarian chef will create a lockfile, so use update and install [the same way as you would with composer](/2013/03/07/composer-install-vs-composer-update.html).

A basic Cheffile for one of my CentOS 5.8 Vagrant VMs looks like this:

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

There is some redundancy built in here, as Librarian-chef will recursively resolve cookbook dependencies for you, which I think it does via `metadata.rb`.

