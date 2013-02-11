---
title: Vagrant is easy - Chef is hard (Part 2).
layout: post
---

This is part 2 of a 2 part quick-start to using Vagrant[^1] and Chef[^2] to speed up and simplify your development environment.  If you haven't read the first part, and aren't already familiar with Vagrant go to [part 1 here](/2013/01/15/vagrant-is-easy-chef-is-hard.html).

In part 1 we covered the key commands and config settings you need to get vagrant up and running quickly with little-to-no fuss.  But that was the easy part.  Now comes the hard part.  Chef.

##Chef

The reason Chef is so hard, and the reason it has such as steep learning curve, is that every single blog post or tutorial, and even the chef manual itself, all deal with low-level Chef.  That is not what we want.  As a developer I have a hundred things to do and no time to do them.  I don't care about low-level stuff.  I want stuff that Just Works.  So here we go.  This is the least amount of knowledge you need to get a lamp stack up and running on Vagrant.  As a side effect of that, you'll actually learn quite a bit of Chef along the way.

###Key Points

Before we start, there are a couple of key definitions you're going to need to learn to make your life simpler.  They aren't difficult, and I'll do my best to distil them down to a basic level.

####Cookbooks

Installing things (apache, mysql, php etc) is done by something called Cookbooks.  Cookbooks are a collection of Templates and _Recipes_ (and a few other things we don't care about right now) that  tell Chef how to install something.

#####Recipes

At a basic level, a _Recipe_ is a ruby file that calls a bunch of Chef functions to install something.

#####Templates

A template is much like a PHP app template with variable replacements, loops etc, but for system config files.  Think v-hosts, httpd.conf, php.ini etc.

#####LWRP

You will see LWRPs mentioned a lot and it's not immediately obvious what they are.  It stands for _Light Weight Resource Providers_.  But really they're functions that do something Chefy (like install a Pecl Module/PEAR Library in the PHP Cookbook).  They should just call them that.  You don't really need to use these yet, but I figured you'd want to know what they are when you see them mentioned elsewhere.

####Chef Server vs Chef Solo

Chef comes in two flavours.  Chef Solo and Chef Server.  Chef is always run on the guest or machine being provisioned, not your own machine or workstation.  That means it needs to have the cookbooks copied across in order for it to know where they are.  Chef Server takes care of this for you (the copying across), as well as managing a central repository of your cookbooks.

Chef Server can also do some other fancy stuff (such as provisioning new EC2 instances for you), but unless you're using it for a live server or professional dev-ops (and we're not), forget about it.  We can copy the cookbooks across ourselves (or in reality vagrant will).

One final point of note: Opscode (the company behaind chef) will host a Chef server for you, or you can do it yourself.  It would appear Chef can provision it's own Chef Server, but I've not tried.

####Roles

A role is simply a type of server.  E.g. If you have a distributed architecture with a load balancer, 2x web servers and 2x database servers, your roles would be "Load Balancer", "Web Server", and "Database Server".  That's a role.

A role is not limiting, in reality it's a name given to a collection of cookbooks you want to run.  E.g. You specify that your webserver roll should run the apache, php, and mysql cookbooks.  The cookbooks that a particular role should run is called a "Run List" in Chef, that's because the name of the Chef function you pass the cookbooks to run to is `run_list`.

####Extra Credit

You don't need to know about this, but I will cover it here for completeness.  Chef also has the concepts of "Nodes" and "Data-Bags".  I haven't used these features, but my understanding is that a "Node" is an instance of a Role.  So you have your 2x webservers, each using the "Web Server" role.  Each one of those is a Node.

From my understanding, "Data-Bags" provide additional data to your Recipes, this could be a list of admins or databases to create, or something similar.  I haven't used them, so I'm not familiar with them.

###Getting Started

Now the real quickstart.  You need a directory to hold your Chef related stuff, for simplicity when updating cookbooks, you need that directory managed with git.  This is fairly essential as managing updates to your cookbooks by hand would be a nightmare.  From your application's root directory run:

    cd ../
    mkdir -p chef/{cookbooks,data_bags,nodes,roles,site-cookbooks}
    cd chef
    git init .

That's our basic directory structure.  Done.  Next we need to add some cookbooks.  Thankfully, there are a ton of them available on Github[^3] that we can use.  We don't need to write our own (most tutorials focus on writing your own... I don't know why).

Now think about what you would normally do when building a new ubuntu VM.  First, you sort out apt to make sure everything is up to date.  Cookbooks live in, unsurprisingly, the cookbooks directory, so lets add the apt cookbook to take care of apt for us:

    git submodule add https://github.com/opscode-cookbooks/apt.git cookbooks/apt

Great, now we want apache2 up and running:

    git submodule add https://github.com/opscode-cookbooks/apache2.git cookbooks/apache2

Boom. Done.  MySQL?

    git submodule add https://github.com/opscode-cookbooks/mysql.git cookbooks/mysql

PHP...

    git submodule add https://github.com/opscode-cookbooks/php.git cookbooks/php

Ok.  We have our cookbooks.  Now we need to add a role so Chef knows which ones to run (you could add a whole bunch of cookbooks here, then in the roll only run a select few).

So, create `roles/vagrant-test-box.rb` and add the following:

    # Name of the role should match the name of the file
    name "vagrant-test-box"

    # Run list function we mentioned earlier
    run_list(
        "recipe[apt]",
        "recipe[apache2]",
        "recipe[mysql]",
        "recipe[php]"
    )

That's it.  Done.  Now lets briefly go back to the Vagrantfile we created in part1:

    # Enable provisioning with chef solo, specifying a cookbooks path, roles
    # path, and data_bags path (all relative to this Vagrantfile), and adding
    # some recipes and/or roles.
    config.vm.provision :chef_solo do |chef|
        chef.roles_path = "../chef/roles"
        chef.cookbooks_path = ["../chef/site-cookbooks", "../chef/cookbooks"]
        chef.add_role "vagrant-test-box"
    end

See that bit at the bottom.  That's how vagrant knows to use Chef, and where to find your cookbooks.  If you've stored your cookbooks somewhere other than where I've suggested, update the paths here, otherwise, let's update the role to "vagrant-test-box", as that's what we just created, and then go back to your application root and run `vagrant up`.

Everything should run successfully, you'll see it all whizzing past as Chef installs it, and it will drop you back to a shell prompt with the VM running and provisioned.  Awesome.  You can have a quick test by visiting 192.168.33.33 in your browser, or www.example.vm if you installed the vagrant-hostmaster plugin.

![Successful Chef Provision](/img/posts/successful-chef-provision.png)

Now lets look at what was created in a bit more detail.  Run `vagrant ssh` to login to the VM.  Now type `mysql -u root -p`.

Uh oh.  Two problems.  First, we never set a password for the MySQL server, so we can't login, second, if we run that command without a password, we get the error:

    ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)

MySQL Server isn't installed?? Why??  Lets take a look at the cookbook.

When you add a cookbook to your run list as we did above, Chef will run the default recipe, which can be found in `recipes/default.rb`.  So let's take a look at `cookbooks/mysql/recipes/default.rb` and see what's going on.

    include_recipe "mysql::client"

Right.  We installed the MySQL Client, but not MySQL Server.  The astute amongst you will have spotted another file in `cookbooks/mysql/recipes` called `server.rb`.  A cookbook can contain multiple recipes, and by default the MySQL cookbook only installs the MySQL Client, to install the server we also need to add the MySQL Server recipe to our run list.  You specify a recipe inside a cookbook other than the default using the `::` syntax you can see above.  Lets modify our `vagrant-test-box` role to look like this:

    # Name of the role should match the name of the file
    name "vagrant-test-box"

    # Run list function we mentioned earlier
    run_list(
        "recipe[apt]",
        "recipe[apache2]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]"
    )

We've left the default MySQL recipe in there as we're going to need the MySQL Client to administer our server.

Now run `vagrant provision` to run Chef again, and let's see what happens.

You got an error? Good.  What you've just come across is the complete disaster that is Chef error messages.  Totally useless.  What it's actually complaining about is a missing constant: `Opscode::OpenSSL`.  This is actually a symptom of something else.  Some cookbooks and recipes have dependencies on other cookbooks and recipes.  Specifically in this instance, the `mysql::server` recipe depends on the `openssl` cookbook.

Fortunately for us, the cookbooks in the opscode GitHub repository have fairly good README's that list their dependencies fairly well.  Let's take a look at the cookbooks we've included so far and see if they have any other dependencies we've missed.  Go ahead, I'll wait.

Great, It looks like only `mysql::server` has any dependencies.  Apache2 has some dependencies if you're using RHEL or CentOS, and PHP does if you're going to build it from source, but we're not so we can just add the missing openssl cookbook and get on with it:

    cd ../chef
    git submodule add https://github.com/opscode-cookbooks/openssl.git cookbooks/openssl

Now let's add it to our run list before `mysql::server`:

    run_list(
        "recipe[apt]",
        "recipe[openssl]",
        "recipe[apache2]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]"
    )

I've added it to just after apt for neatness.  You can add it anywhere you want before `mysql::server`.

Now let's try again:

    vagrant provision

Oh no... another cryptic error.  The key line here is:

    FATAL: You must set node['mysql']['server_debian_password'], node['mysql']['server_root_password'], node['mysql']['server_repl_password'] in chef-solo mode. For more information, see https://github.com/opscode-cookbooks/mysql#chef-solo-note

We forgot to set our root password so we can login to the server, and Chef knows it, so it won't let us proceed without it.  Now we need to learn about `override_attributes`.

    override_attributes(
        "mysql" => {
            "server_root_password" => 'iloverandompasswordsbutthiswilldo',
            "server_repl_password" => 'iloverandompasswordsbutthiswilldo',
            "server_debian_password" => 'iloverandompasswordsbutthiswilldo'
        }
    )

Not massively scary.  Put this in your `vagrant-test-box.rb` role before your run list.  This function allows you to override some defaults setup in the cookbooks on a per-role basis.  Nothing too difficult, it is again often documented in the cookbook's README, or is fairly easy to find by searching the cookbooks's templates or recipes for things like:

    node['apache']['log_dir']

That's a fairly good indication we can overwrite that attribute in our role by adding the key to our override attributes function call:

    override_attributes(
        "apache" => {
            "log_dir" => "/srv/logs" # new attribute overridden
        },
        "mysql" => {
            "server_root_password" => 'iloverandompasswordsbutthiswilldo',
            "server_repl_password" => 'iloverandompasswordsbutthiswilldo',
            "server_debian_password" => 'iloverandompasswordsbutthiswilldo'
        }
    )

Ok, don't add that to your role for real, as we haven't created that directory so it will cause an error.

Now your role should look like this:

    # Name of the role should match the name of the file
    name "vagrant-test-box"

    override_attributes(
        "mysql" => {
            "server_root_password" => 'iloverandompasswordsbutthiswilldo',
            "server_repl_password" => 'iloverandompasswordsbutthiswilldo',
            "server_debian_password" => 'iloverandompasswordsbutthiswilldo'
        }
    )

    # Run list function we mentioned earlier
    run_list(
        "recipe[apt]",
        "recipe[openssl]",
        "recipe[apache2]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]"
    )

Save the file and run another `vagrant provision`.

Are you noticing a pattern here?  Well done.  That's how we can debug our recipes.  Change -> `vagrant provision` -> Error -> Repeat until it works.  If the error isn't obvious, Google is your friend.  Chef will also always give you a stack trace which will show you the recipe and line giving the error, a quick read of the source can usually give you a good indication of what's really going on.  It reads close to plain English, so you stand a good chance of understanding even if you don't know Ruby.

This time it should run successfully, so log back in with `vagrant ssh` and try to connect to MySQL with

    mysql -u root -piloverandompasswordsbutthiswilldo

It should drop you into a `mysql>` prompt, where you can run `show databases;`.

    mysql> show databases;
    +--------------------+
    | Database           |
    +--------------------+
    | information_schema |
    | mysql              |
    +--------------------+
    2 rows in set (0.00 sec)

This is looking good.  Type `quit` to exit MySQL, now type `php --version`

    PHP 5.3.2-1ubuntu4.18 with Suhosin-Patch (cli) (built: Sep 12 2012 19:33:42)
    Copyright (c) 1997-2009 The PHP Group
    Zend Engine v2.3.0, Copyright (c) 1998-2010 Zend Technologies

Even better. Now let's enable the default site and test Apache.

    sudo a2ensite default
    sudo service apache2 reload

You'll notice we didn't need to type a password, vagrant was good enough to add itself to the automatic sudoer's list.  Now visit www.example.vm or 192.168.33.33 if you aren't using the hostmaster plugin.

![Apache Default Site](/img/posts/it-works.png)

We're getting there.

    echo "<?php phpinfo();" | sudo tee /var/www/info.php

Visit www.example.vm/info.php or 192.168.33.33/info.php to see if it works.  Damn, it downloaded the file.  Ok.  A quick look through the recipes in the Apache2 cookbook shows a `mod_php5` recipe.  We probably need to add that, so lets add it to our run list and try again:

    # Run list function we mentioned earlier
    run_list(
        "recipe[apt]",
        "recipe[openssl]",
        "recipe[apache2]",
        "recipe[apache2::mod_php5]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]"
    )

Now run `vagrant provision` and try to load the info file in our browser again when it's finished.

![Not Found](/img/posts/not-found.png)

What's that all about?  Well, Chef has just re-installed everything for you, so Apache's config is all new again.  Let's repeat the steps above.  Make a note we need to find a way to make our virtual hosts persistent.  We'll come back to it soon.

    vagrant ssh
    sudo a2ensite default
    sudo service apache2 reload
    echo "<?php phpinfo();" | sudo tee /var/www/info.php

Now try to load info.php again.

![Vagrant phpinfo()](/img/posts/vagrant-phpinfo.png)

Success!  But a quick scan of the `info.php` output shows the MySQL section is missing.  Let's verify that.

    php --info | grep mysql

Nothing.  Let's check the PHP cookbook.  There's a `module_mysql` recipe! Excellent.  Are you spotting another pattern here?  Nothing is enabled by default with the opscode cookbooks, if it's optional, you have to specify it.

    # Run list function we mentioned earlier
    run_list(
        "recipe[apt]",
        "recipe[openssl]",
        "recipe[apache2]",
        "recipe[apache2::mod_php5]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]",
        "recipe[php::module_mysql]"
    )

Now run `vagrant provision` again.

    vagrant ssh
    php --info | grep mysql

Much better.

![Vagrant php mysql info](/img/posts/vagrant-mysql-info.png)

That just leaves us with one last thing.  Getting our data and virtual hosts to persist between provisions.

I know I said we wouldn't need them, but to get our virtual host to point at our code and persist between provisions, we need to use a LWRP.  Specifically the `web_app` LWRP from the apache2 cookbook.

This may or may not be the _right_ way to do this, but I know it works so it's how I'm going to do it until I find a better way.  Create a directory in `chef/site-cookbooks` called `apache2`.  Inside there, create another directory called `recipes`.  Now add a file called `vhosts.rb` with the content:

    #
    # Cookbook Name:: apache2
    # Recipe:: vhosts
    #
    # Copyright 2012, Adam Brett. All Rights Reserved.
    #
    # Unless required by applicable law or agreed to in writing, software
    # distributed under the License is distributed on an "AS IS" BASIS,
    # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    # See the License for the specific language governing permissions and
    # limitations under the License.
    #
    include_recipe "apache2"

    web_app "example" do
      server_name "www.example.vm"
      server_aliases ["example.vm"]
      allow_override "all"
      docroot "/srv/site/"
    end

Remember how in our `Vagrantfile` we told Vagrant to mount the current directory at `/srv/site`?  That's so our source code was available in the VM.

Now we create a custom recipe (hence the site-cookbooks location), and import the apache2 default recipe.

There's something important to note here.  If you create a recipe in `site-cookbooks` that has a recipe of the exact same name and location as one in `cookbooks`, the one in `site-cookbooks` will be used.  This allows you to extend or modify the opscode cookbooks without having to modify them directly.  This is why we used git to manage this directory.  We can now very easily update all of our cookbooks with git without worrying about overwriting any of our custom modifications.

The `web_app` LWRP (or function) is defined in `cookbooks/apache2/definitions/web_app.rb`. If you open this file and take a look, you can see in here lots of calls to `params[:something]`.  These are the params you can pass to the function call.  You can also see it's using the template `web_app.conf.erb`.  Open this file in the `apache2/templates/default` directory and you can see a bunch more params you can pass to this function/LWRP.  We only need to use a couple so we'll leave the recipe as it is.

You include your own recipes in the run list exactly as you would a normal one, so lets add ours:

    # Run list function we mentioned earlier
    run_list(
        "recipe[apt]",
        "recipe[openssl]",
        "recipe[apache2]",
        "recipe[apache2::mod_php5]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]",
        "recipe[php::module_mysql]",
        "recipe[apache2::vhosts]"
    )

Now run `vagrant provision` again, and visit www.example.vm in your browser.

![Vagrant Local Website](/img/posts/vagrant-local-website.png)

Success!  Any index.html you have in your application root should now be loaded in your browser.  If you need to load an `index.php` or something else, add the `directory_index` paramter to the web_app LWRP call.

    web_app "example" do
      server_name "www.example.vm"
      server_aliases ["example.vm"]
      directory_index ["index.html", "index.php"]
      allow_override "all"
      docroot "/srv/site/"
    end

So we're pretty close.  All that's left now to have something _really_ useful is to import our database schema.

Fortunately for us, the guys have opscode have a cookbook for that too.  It's called database, and we're going to need some LWRP providers from it again.

    cd ../chef
    git submodule add https://github.com/opscode-cookbooks/database.git cookbooks/database

The `database` cookbook recipe `mysql` has a dependency on the `build-essential` cookbook, so let's add that too.

    git submodule add https://github.com/opscode-cookbooks/build-essential.git cookbooks/build-essential

Now add the database::mysql recipe, build-essential default recipe, and another custom one we're about to create to your run list.

    # Run list function we mentioned earlier
    run_list(
        "recipe[apt]",
        "recipe[build-essential]",
        "recipe[openssl]",
        "recipe[apache2]",
        "recipe[apache2::mod_php5]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]",
        "recipe[php::module_mysql]",
        "recipe[apache2::vhosts]",
        "recipe[database::mysql]",
        "recipe[database::import]"
    )

Now let's setup that custom recipe.  Bear in mind, there is probably a _correct_ way to do this.  I'm not aware of it, and this way _works_:

    mkdir -p site-cookbooks/database/recipes

Then add `import.rb` in your newly created directory with the following content:

    #
    # Cookbook Name:: database
    # Recipe:: import
    #
    # Copyright 2012, Adam Brett. All Rights Reserved.
    #
    # Unless required by applicable law or agreed to in writing, software
    # distributed under the License is distributed on an "AS IS" BASIS,
    # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    # See the License for the specific language governing permissions and
    # limitations under the License.
    #
    include_recipe "database::mysql"

    # Store this in a variable so we don't keep repeating it
    mysql_connection_info = {
        :host => "localhost",
        :username => 'root',
        # automatically get this from the override_attributes call!
        :password => node['mysql']['server_root_password']
    }

    # my_database = database name
    mysql_database 'my_database' do
      connection mysql_connection_info
      action :create
    end

    # import an sql dump from your app_root/data/dump.sql to the my_database database
    execute "import" do
      command "mysql -u root -p\"#{node['mysql']['server_root_password']}\" my_database < /srv/site/data/dump.sql"
      action :run
    end

    # this isn't really necessary, as we're using root and not creating a database
    # user, but I'm including it and commenting it out so you can see what it looks like
    # mysql_database_user 'my_user' do
    #  connection mysql_connection_info
    #  database_name 'my_database'
    #  action :grant
    # end

Now, make sure the database dump exists, and run `vagrant provision`.

Error!

Again!

It turns out that there is some weirdness with Chef and build-essential and Ruby Gems (which is what gives us the database LWRPs).  A quick scan of the build-essential README reveals we need to add:

    default_attributes(
        "build_essential" => {
            "compiletime" => true
        }
    )

to our role definition.  Go ahead and do that, so the whole thing should look like this:

    # Name of the role should match the name of the file
    name "vagrant-test-box"

    default_attributes(
        "build_essential" => {
            "compiletime" => true
        }
    )

    override_attributes(
        "mysql" => {
            "server_root_password" => 'iloverandompasswordsbutthiswilldo',
            "server_repl_password" => 'iloverandompasswordsbutthiswilldo',
            "server_debian_password" => 'iloverandompasswordsbutthiswilldo'
        }
    )

    # Run list function we mentioned earlier
    run_list(
        "recipe[apt]",
        "recipe[build-essential]",
        "recipe[openssl]",
        "recipe[apache2]",
        "recipe[apache2::mod_php5]",
        "recipe[mysql]",
        "recipe[mysql::server]",
        "recipe[php]",
        "recipe[php::module_mysql]",
        "recipe[apache2::vhosts]",
        "recipe[database::mysql]",
        "recipe[database::import]"
    )


Then run it again: `vagrant provision`.

All done? Let's verify it worked:

    vagrant ssh
    mysql -u root -piloverandompasswordsbutthiswilldo


    mysql> show databases;
    +--------------------+
    | Database           |
    +--------------------+
    | information_schema |
    | my_database        |
    | mysql              |
    +--------------------+
    3 rows in set (0.00 sec)

    mysql> use my_database;
    Database changed

    mysql> show tables;
    +-----------------------+
    | Tables_in_my_database |
    +-----------------------+
    | my_table              |
    +-----------------------+
    1 row in set (0.00 sec)

Success!  You should now be able to put your vagrant database details into your app and have it load as expected, and if not, I should have given you access to the tools and knowledge you need to start experimenting and debugging for yourself.

In the months and years to come Vagrant and Chef are going to become as indispensable for any serious developer, so please give it a go and let me know on [twitter](http://twitter.com/sixdaysad) if there's anything you think needs improving or clarifying in this post!

[^1]: http://vagrantup.com
[^2]: http://www.opscode.com/chef
[^3]: https://github.com/opscode-cookbooks/
[^4]: https://github.com/mosaicxm/vagrant-hostmaster
