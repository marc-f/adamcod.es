---
title: Vagrant is easy - Chef is hard.
layout: post
---

This is part 1 of a 2 part quickstart to using Vagrant and Chef to speed up and simplify your development environment.  If you're already familiar with Vagrant and just want to find out about Chef, go to [part 2 here](/2013/01/15/vagrant-is-easy-chef-is-hard-part2.html).

If you haven't started using Chef[^1] and Vagrant[^2] yet, you should, it's awesome and in a few short weeks has totally changed my development environment.

The only problem is that it's not much use on its own, and getting started with Chef/Puppet is really really hard as there is no good documentation out there for it.  Not even the manual.  Today I'm going to change that.  If you're a developer and just want to build a consistent and reliable test environment, as quickly and with as little hassle as possible pay close attention.

Just before Christmas we had a massive office refurb.  The office was shut and completely inaccessible for just over a week, which meant I spent the week working from home, without access to our UAT box.  Normally this wouldn't be a problem, I'd just have developed locally and uploaded when back in the office, except the issue I was working on was very specific to the PHP version we were running, our ops guys wouldn't upgrade and that meant I needed an environment as close to live as possible for testing.

I took this opportunity to pick-up vagrant.  I'd heard about it before, even installed it, but never really used it.

##Vagrant

Think of vagrant as a command line script for VirtualBox[^3].  I'm going to skip over how to install both, as it's really easy just following the instructions on their websites.  You will need the latest VirtualBox and Vagrant installed for this to work though.

There are a couple of important concepts in Vagrant

###Baseboxes

Baseboxes are virtual machine images.  This is the default start state of your VM.  Think of setting up a new VM, then saving a snapshot so that you can restore to that point any time you want.  That's like a basebox.  Except baseboxes are scripted, so they're way cooler.

Lots of people have created baseboxes for you already[^4], so you don't need to create your own.  The default is `lucid32`, an ubuntu basebox.  This will probably be fine unless you know why you need another one.

Key Command (to add a new box): `vagrant box add lucid32 http://files.vagrantup.com/lucid32.box`

`lucid32` is how you'll reference the box locally, the url is where it can be downloaded.


###VagrantFile

`Vagrantfile` is the name of a textfile in the root of your project.  It provides all of the config settings, such as which directories on the host to mount in the VM (your code, etc), as well as networking config.

You'll want to end up with a `Vagrantfile` that looks something like this:

{% highlight ruby linespans %}
Vagrant::Config.run do |config|
  # Your local name for the basebox you want to use.
  config.vm.box = "lucid32"

  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  config.vm.network :hostonly, "192.168.33.33"

  # Use the vagrant hostmaster plugin[^5] to automatically add a domain name
  config.vm.host_name = "www.example.vm"

  # Share an additional folder to the guest VM. The first argument is
  # an identifier, the second is the path on the guest to mount the
  # folder, and the third is the path on the host to the actual folder.
  # You can add as many of these as you like, anywhere you like
  config.vm.share_folder "v-data", "/srv/data", "../data", :nfs => true
  config.vm.share_folder "v-site", "/srv/site", ".", :nfs => true

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  config.vm.provision :chef_solo do |chef|
    chef.roles_path = "../chef/roles"
    chef.cookbooks_path = ["../chef/site-cookbooks", "../chef/cookbooks"]
    chef.add_role "webserver"
  end
end
{% endhighlight %}

Key Command (to add a new Vagrantfile to your current project): `vagrant init`

###Baseboxes are normally empty

When you have a base ubuntu install, you can't do much with it, that's the same with baseboxes.  While you could build a basebox that already has everything you need installed, that's not really using it to the best of its ability.  To get anything installed, you need a provisioner, and that's where Chef comes in.  You can also use puppet, but don't worry too much about that for now, provisioning is the hard part and we'll cover it in the next post.

###Key Commands

There are 6 key commands you will need day-to-day for vagrant

* `vagrant up`

    This starts the VM if it's not already running.

* `vagrant suspend`

    This saves the machine state and temporarily shuts down the VM.  Running `vagrant up` will bring it back again exactly as it was.

* `vagrant ssh`

    Login to your VM using ssh.  Vagrant uses its own private/public keys which are automatically copied to the VM, so there's no username/password to worry about.

* `vagrant provision`

    This re-runs your provisioner of choice (e.g. if you've updated something) without having to start from scratch.

* `vagrant reload`

    This resets the VM to the basebox's original state and re-runs your provisioner.

* `vagrant destroy`

    This completely removes all trace of the VM from your system (but not the basebox or provisioner).

###Summary

This should be enough to get you started using Vagrant.  If you follow these steps, then run `vagrant up` you should have a functioning VM, and the key commands should be enough to give you a great grounding in how to use vagrant.  Now carry on reading [part 2](/2013/01/15/vagrant-is-easy-chef-is-hard-part2.html) to find out how to make your VM actually do something useful.


[^1]: http://www.opscode.com/chef
[^2]: http://vagrantup.com
[^3]: https://www.virtualbox.org
[^4]: http://vagrantbox.es
[^5]: https://github.com/mosaicxm/vagrant-hostmaster
