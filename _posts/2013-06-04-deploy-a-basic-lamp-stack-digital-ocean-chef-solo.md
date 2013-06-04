---
layout: post
title: Deploy a basic lamp stack to Digital Ocean with Chef Solo
tweet: Deploy a basic lamp stack to @digitalocean with @opscode chef solo
---

I wrote previously that Chef is hard[^1].  That was not too long after I started using Vagrant and Chef on a regular basis.  I plan to write an update on that post in the future because I've learnt quite a bit about using Chef since then, and there have been a few significant updates to Vagrant too.

In the meantime, this is a very quick start guide to deploying a LAMP stack to a VPS.  My provider of choice is [Digital Ocean](https://www.digitalocean.com/?refcode=dd312899e4e9), but the same process should work for pretty much any VPS or physical server.

##What is Chef

Chef is a provisioning tool.  A provisioning tool is something which can script the deployment or set-up of a server, attempting to solve the snowflake[^2] issue by providing a consistent and reliable process that can be automated and therefore replicated many times.

There are many different provisioning tools out there, the most popular of which are Chef and Puppet.  Chef uses Ruby, Puppet uses a DSL (Domain Specific Language), there are others that use simple bash too, but today we're going to focus on Chef.

##Quick Chef Primer

Chef comes in two versions, Server and Solo.  Server requires a Chef Server which will manage your other multiple servers for you.  Chef Solo does not require another server, but has the drawback that it can only manage servers manually or one-at a time.

Chef has the concept of _recipes_ and _cookbooks_.  Think of a recipe as a single script which does something on your server.  A cookbook is a collection of recipes related to a particular topic, for example installing and configuring apache.  A cookbook is just a directory containing a bunch of folders and files, recipes live in a folder called "recipes" inside the cookbook.  Each recipe is saved as "recipe-name.rb" and is a simple Ruby script.

A cookbook can also have nodes, roles, and data-bags.  We'll get onto all of that in another blog post.

Chef has a command-line tool called knife which helps manage your cookbooks and servers for you.  Out of the box, knife only works with Chef Server, but there is an add-on which allows it to work with Chef Solo.  That's what we're going to be using today.

##Step 1 - A New VPS

The first thing we need to do is create a new VPS instance.  If you don't already have one, sign up for an account on [Digital Ocean](https://www.digitalocean.com/?refcode=dd312899e4e9).  They'll have you up and running in 55 seconds.  No joke.

Once you're signed in, click "SSH Keys" on the left-hand menu, then click "Add SSH Key".  If you don't have an SSH Key, we'll need to create one.

Open up a terminal and type `ssh-keygen`.  Press `return` to select the default location, then enter a passphrase.  You'll need to remember this passphrase, as you'll need to use it every time you want to access your VPS.

{% flickr 8935261856 %}

Now browse to `~/.ssh` and open `id_rsa.pub` in your favourite text editor.  Copy everything you see there to your clipboard, and paste it into the "Public SSH Key" field in the [Digital Ocean](https://www.digitalocean.com/?refcode=dd312899e4e9) control panel.

Now give your key a name, it doesn't matter what it is, it's just for your reference in-case you have a few SSH Keys for different uses.  Click "Create SSH Key" and you're all done.

{% flickr 8935274328 %}

Next, click the big green 'Create' button to create a new 'Droplet' (the name [Digital Ocean](https://www.digitalocean.com/?refcode=dd312899e4e9) give to a VPS instance).

Enter a host name for your new Droplet at the top, and select a size.  The smallest will do for this demo, but feel free to select a larger one, [Digital Ocean](https://www.digitalocean.com/?refcode=dd312899e4e9) charge by the hour, not the month.

{% flickr 8935205666 %}

Now select a region and a distribution.  Choose whatever region is closest to you, I've heard the UK should be coming in 2013, but I'll select Amsterdam until then.

You can also use whatever distribution you want with Chef, most cookbooks are agnostic, but for this demo we'll be using "Ubuntu 12.10 x64 Server" as that's the current LTS release.

{% flickr 8935308328 %}

Finally, select the SSH Key that you added earlier, leave VirtIO enabled and click "Create Droplet"

{% flickr 8935320904 %}

Now wait whilst [Digital Ocean](https://www.digitalocean.com/?refcode=dd312899e4e9) creates your new droplet, it should take under 55 seconds; seriously.  Whilst writing this blog post it took around 20 seconds.  When it's done it will drop you into the control panel for that Droplet, and will give you an IP Address at the top.  We need that IP Address, so save it somewhere.

{% flickr 8935403056 %}

##Step 2 - Dependencies

To get Chef working properly on your local machine you need a few things:

1. Ruby
2. knife/knife-solo
3. librarian-chef

You can install Ruby from the website[^3], or your package manager of choice.  **Make sure you use Ruby 1.9.x and not Ruby 2.x as you will get errors with the json 1.6.1 Gem on 2.x**.  I use `rbenv` to help me keep several different Rubies on the one machine.  Once you have Ruby installed, install the two required Gems:

    gem install knife-solo --no-ri --no-rdoc
    gem install librarian-chef --no-ri --no-rdoc

You will notice that even though Chef is just a Ruby Gem itself, we haven't included it in our dependencies, and that's because Chef runs on our server, not on our local machine, so we don't explicitly need it.

**Note:** You won't be able to use bundler to manage these dependencies as knife-solo and librarian-chef have a dependency conflict which cannot currently be resolved, but they will happily live side-by-side if installed manually.

You'll also notice that we have specified knife-solo, even though knife-solo requires knife (which incidentally comes with Chef).  This is because Ruby Gems will make sure all of the required Gems are installed on your system for you.  As you should see, there are quite a few dependencies, so this saves us a fair bit of time.

You can now test your new setup by running `knife solo` and you should get output like:

{% flickr 8936842096 %}

And running `librarian-chef` which should produce output like:

{% flickr 8936219737 %}

##Step 3 - Opscode Cookbooks

Much like Ruby Gems and Bundler, or Packagist and Composer for PHP, Opscode (the people behind Chef) maintain a list of pre-built cookbooks that they or the community have created[^4].  Librarian-chef that we installed in the previous section can be used to download and install these cookbooks and their dependencies for us automatically.  This is by far the easiest way to maintain your cookbooks.

First, open a terminal and create a directory where you'd like to store your project, then change directory into it and create a new chef project using knife:

    cd ~/Projects
    mkdir chef-demo
    cd chef-demo
    knife solo init .

The last `.` is important.  It tells knife-solo that we want to create the project in the current directory.  Knife will warn you about a missing configuration file.  Ignore this, as it relates to Chef Server which we won't be using.  Knife will keep reminding you about this file, and you can safely keep ignoring it.

Now we have a basic Chef project it's time to get some cookbooks to install some stuff on our server.  For our very basic setup we want 3 things:

1. Apache
2. MySQL
3. PHP

Run `librarian-chef init` in the root of your project to make librarian-chef manage it.  You should now have a file in the root of your project called `Cheffile`, open it in your favourite editor and add the following below the line `site 'http://community.opscode.com/api/v1'`:

    cookbook 'apache2'
    cookbook 'mysql'
    cookbook 'php'

The syntax of this file is fairly straight forward, and there should be some commented out examples in there for you to examine.  The cookbook name corresponds to the name of the cookbook on the opscode community website.

Now run `librarian-chef install` and it should go off and grab your cookbooks and dependencies for you.

{% flickr 8937074144 %}


Third party cookbooks should always live in `./cookbooks`, so this is where librarian-chef has put them.  If you ever need to override something in a cookbook, never modify it, instead, put the corresponding changes in `./site-cookbooks`.  Don't worry about that for now though, we will cover that in another blog post.

## Step 4 - Your Node

In [Digital Ocean](https://www.digitalocean.com/?refcode=dd312899e4e9), a VPS is a Droplet, in Chef, a VPS (or server) is called a node.  Not surprisingly, node configuration files live in `./nodes`.  They should be named in the format `{hostname|ip}.json`.  If you don't know either yet, you can call it anything you want, but you will lose a little syntactic sugar on the command-line a little later on.

Change into your `nodes` directory and create a new node file.  For my purposes, that would be either `chef-demo.adamcod.es.json` or `82.196.8.99.json`.  Your hostname is probably better long term as your IP address can change, however as this is just a demo I'm not going to actually create the hostname, I'll be using the IP Address.

    cd nodes
    touch 82.196.8.99.json

Now open the file in your text editor and add the following:

    {
      "run_list": [
        "recipe[apache2]",
        "recipe[mysql]",
        "recipe[php]"
      ]
    }

Save the file, and go back to the terminal.  A run list is a list of cookbooks, and the recipes inside those cookbooks that we want to run on our server.  They're specified in the format: `recipe[cookbook::recipe]`.  If you leave off the `::recipe` part Chef will assume a recipe named "default".

Now we're ready to go; that's all we need to do.  Let's move back to the root of your project and try provisioning your server:

    cd ~/Projects/chef-demo
    knife solo bootstrap root@82.196.8.99

Substitute `82.196.8.99` with your IP or Hostname, and root with your user-account if you're not using [Digital Ocean](https://www.digitalocean.com/?refcode=dd312899e4e9).  You can add an optional 4th parameter here which is the path to your nodefile if you didn't name it in the recommended format.

You should soon see knife logging into the server, then downloading, installing, and running Chef.  Knife Solo has 3 main commands you should be familiar with:

1. knife solo bootstrap

   This will login to your server, download and install chef, copy across your cookbooks, and then run chef.  This is the composite of the two commands below.

2. knife solo cook

   This will login to your server, copy across your cookbooks, and then run chef

3. knife solo prepare

   This will login to your server, then download and install chef.

Once Chef has finished its run open up a browser and visit your IP Address or Hostname for this Droplet and you should see something like this:

{% flickr 8936739547 %}

That's great!  That means that Chef has worked.  Normally you would expect to see something like "It works!" here, but the apache2 Chef recipe doesn't install the "Default Site" that apache normally comes with.

Now we can login to the server to do this, using `a2ensite default`, or we can do it the Chef way.  We're going to do it the Chef way, not just because this is a Chef blog post, but also because any manual changes you make to the server will be overwritten every time you run Chef, so doing things via Chef is the recommended way.  Remember: We want to end up with a set of recipes we can run over and over again to get a server to the exact same specification each time, so anything we have to do manually should be seen as a bad.

##Step 5 - Final Tweaks

We're nearly there.  We have a working apache server, but we don't have any sites loading.  First, we need to enable the default site in apache, and we do that by editing our "node attributes" for apache.

If you open `cookbooks/apache2/attributes/default.rb` you will see a whole bunch of attributes for different platforms.  The one we're interested in is `default_site_enabled` under ubuntu, which is currently set to `false`.

Do not edit this here.  Node attributes can be over-ridden on a node-by-node basis in our node file.  Basically, any key in our node file's json which is not `run_list` is a node attribute.  You can see in the attributes file for each recipe (which matches the recipe name but in the attributes directory in the cookbook) what attributes are available for us to over-ride.  We're only interested in this one today, so update your node file like so:

    {
      "apache": {
        "default_site_enabled": true
      },
      "run_list": [
        "recipe[apache2]",
        "recipe[mysql]",
        "recipe[php]"
      ]
    }

You can see that the key names and hierarchy matches that of the attribute file we looked at above.  Now we re-run Chef using knife, and this time we use the `cook` command instead of `bootstrap` as we don't need to install Chef on the server again.

Just a quick note: Chef is smart enough to know when it's already been run, so it's fairly safe to run it multiple times and it will only modify things that have changed in your local cookbooks.

    knife solo cook root@82.196.8.99

Now reload your browser and you should see the familiar "It works!" page:

{% flickr 8936945923 %}

Progress!  Now let's test PHP And MySQL.  Login to your server using SSH and run `php -v`.

{% flickr 8937594046 %}

Success!  Now you're probably thinking you'd like to test MySQL.  But there's a problem.  If you run `mysql` without any parameters on your new server you'll find it can't connect.  That's because the `default` recipe for the `mysql` cookbook only installs the MySQL client, not the MySQL server.  If you take a look in `./cookbooks/mysql/recipes` you should see a recipe called `server.rb`.  It's a good bet that that's what installs MySQL Server, so let's add that to our `run_list` after `recipe[mysql]`.  We'll leave the default MySQL recipe there as we are going to need the client too.  Our node file should now look like this:

    {
      "apache": {
        "default_site_enabled": true
      },
      "run_list": [
        "recipe[apache2]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]"
      ]
    }

Exit out of your SSH session on your server and run `knife solo cook root@your.ip.or.hostname` from the root of your project to re-run Chef with our new settings.  You should see something like this:

{% flickr 8937090475 %}

Welcome to the hell that is Chef error messages.  By trying to be really helpful, they bombard you with far too much information, making it really difficult to decipher what's actually gone wrong.

The real problem here is something I thought it important to highlight.  In some recipes some node attributes are not optional, you have to set them for your node, and the MySQL cookbook's `server` recipe is one such recipe.  We need to set a MySQL root password for this node!  Fortunately this is usually quite well documented in the README for whatever cookbook you're using.  Update your node file to look like the following.

    {
      "apache": {
        "default_site_enabled": true
      },
      "mysql": {
        "server_root_password": "yoursecretsecurepassword",
        "server_repl_password": "yoursecretsecurepassword",
        "server_debian_password": "yoursecretsecurepassword"
      },
      "run_list": [
        "recipe[apache2]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]"
      ]
    }

Now re-run your `knife cook` command and once it's complete ssh back into your server.  Run `mysql -u root -pyoursecretsecurepassword` and you should be dropped into a nice `mysql>` prompt, showing your MySQL Server is now installed and working!

{% flickr 8937807398 %}

Finally, we have one last thing to do, test PHP on apache.  Still in your ssh session, type `exit` to quit MySQL, then add an `info.php` to your default site:

    mysql> exit
    Bye
    cd /var/www
    touch info.php
    nano info.php

Now enter:

    <?php phpinfo();

and save and exit using `ctrl+x` and typing `y` at the prompt to save.  Now open up `http://yourserver/info.php` in your browser.

It should ask you to download the file.  This is a classic symptom of PHP not being installed.  But we checked it on the command line! I hear you cry.  Yes, we did, but I hope by now you're starting to spot a theme.  The default opscode community cookbooks tend to do the absolute minimum required, and you have to explicitly say if you want something to be installed.  Taking a look through the PHP cookbook's recipes there doesn't seem to be anything relevant, but looking inside apache's recipes you should notice a mod_php5 recipe.  That's what we want, so let's add that to our `run_list`.

    {
      "apache": {
        "default_site_enabled": true
      },
      "mysql": {
        "server_root_password": "yoursecretsecurepassword",
        "server_repl_password": "yoursecretsecurepassword",
        "server_debian_password": "yoursecretsecurepassword"
      },
      "run_list": [
        "recipe[apache2]",
        "recipe[apache2::mod_php5]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]"
      ]
    }

You'll notice we put `mod_php5` before `php` in our `run_list`.  Normally Chef will run things in order, but the `mod_php5` recipie _requires_ the `php` recipe, so Chef is smart enough to know to run that first.

Now we can exit our SSH session and re-run `knife cook` and refresh our `info.php` in the browser.

{% flickr 8937944348 %}

##Conclusion

We now have a functional LAMP stack, it obviously requires quite a bit more work to become a secure and reliable server, but we have deployed it in an automated, reliable, and replicable way.  We've learnt how to manage attributes and settings for applications via their cookbooks, and how to combine and manage our cookbooks to build our own server, with different settings and applications for different servers.

Hopefully you've gained enough knowledge to feel confident looking at and experimenting with the other cookbooks available on the opscode website and add them to your own cookbook as necessary to make your server secure, reliable and production ready.

I'm planning to release this blog post as a screen-cast, as well as a more detailed blog post to make a production ready LAMP stack using Chef and [Digital Ocean](https://www.digitalocean.com/?refcode=dd312899e4e9) (but should work with any other server or VPS you may want to use).

To hear about that when it happens, as well as other exclusive content not available here, make sure you enter your email address in the subscribe box below, and let me know on [twitter](https://twitter.com/sixdaysad) or [ADN](https://alpha.app.net/adambrett) if you have any questions or comments.

[^1]: http://adamcod.es/2013/01/15/vagrant-is-easy-chef-is-hard-part2.html
[^2]: http://martinfowler.com/bliki/SnowflakeServer.html
[^3]: http://www.ruby-lang.org/en/downloads/
[^4]: http://community.opscode.com
