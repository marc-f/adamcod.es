---
layout: post
title: How to Create a Git Plugin (Part 2)
---

This is part 2 of a 2 part series ([part 1 here](/2013/07/12/how-to-create-git-plugin.html)) on creating git plugins.

In the first part I explained how to create a basic plugin, and how to create a plugin runner that will allow you to group a bunch of commands together.

We added two basic commands to that runner, in the same file.  In this part I'm going to show you how to create an external command that gets loaded on-the-fly, and then show you how to install and uninstall your plugin easily using gnumake[^1].

##Some Requirements

In [part 1](/2013/07/12/how-to-create-git-plugin.html) we decided that our hello sub-command should print `Hello World` when we use the command with no options, and print out `Hello {name}` if any further options are passed.

Today I'm going to expand that a little and add a help subcommand to our subcommand that simply prints out our usage information for the subcommand, rather than the usage information for the whole plugin as we did in [part 1](/2013/07/12/how-to-create-git-plugin.html).

##Getting Started

During part 1, we created our runner to work using convention over configuration[^2], that is, it will automatically look for all subcommands in a file named `git-adamcodes-subcommand` where `subcommand` is the name of the command we're running, and inside that file it expects a function named `cmd_subcommand`, again where `subcommand` is the name of the command we're running.  We could of course hard code our subcommands to file and function names, but it's far easier not to.

Now to begin writing our subcommand, create a file at the same level as your `git-adamcodes` file and name it `git-adamcodes-hello`.  In that file, you'll need the following:

{% gist 5983671 git-adamcodes-hello.sh %}

I'll go over this quickly, as it's fairly basic and it should be obvious what it does.  Line 1 is our hashbang, and lines 3-6 define our usage function, which is just echoing out some strings.  The empty echo is an easy way to create a newline.

Line 8 is the function definition for our subcommand.  As we mentioned earlier, it's in the format `cmd_subcommand`, where in this instance, the subcommand is `hello`.  This is the function that our runner from [part 1](/2013/07/12/how-to-create-git-plugin.html) is going to call, and pass in our command line arguments to.

The first line of our command, line 9, checks the number of arguments passed to the function, if it's less than (`-lt`) 1, we just want to say "Hello World", and exit with a success status.

On line 11, we have an else if, which in sh/bash is `elif`, and that checks to see if the number of arguments is equal to 1.  If it is, we have a correct usage of our subcommand.

At this point, we have to check to see if the first parameter of our subcommand was "help", because this means someone wanted the usage information, and I'm pretty sure they didn't mean to say "Hello help", which is just silly.

If the first parameter was "help", we print our usage information and exit with a success status again.  If it wasn't help, that means that the user wanted us to say hello to them, so we call our `say_hello` function again, and pass in the first parameter.  Again, we end a successful execution with `exit 0` to indicate to git and/or the shell that this action was successful.

Finally, in all other instances (i.e. greater than 1 parameter), we want to print the usage information, as it looks like the user was using our subcommand incorrectly.

The last part of our subcommand (lines 22-25) is a helper function.  This is unique to our subcommand, and won't be shared by our other subcommands.  All this function does is take the first argument passed to it and echo it out after the word hello.  This is convenient for us as we can call `say_hello World` and `say_hello $1` on lines 10 and 16 respectively.  Code re-use is good, and all that stuff.

## Pulling it Together

Now our plugin is complete, we need to put both files in `/usr/bin` or somewhere similar on your path.  Then you need to make the wrapper/runner file executable; the subcommands don't need to be executable.

After you've copied the files, run `sudo chmod +x /usr/bin/git-adamcodes` to make the runner executable.

You should then be able to drop in to a shell anywhere you have git available, and give it a try:

{% flickr 9319659531 %}

##Easy Install + Uninstall With Make

Make is basically a build system like Phing or ApacheAnt, but it works with bash/shell, so it's great for simply installing and uninstalling scripts, or in our case, git plugins.

Make starts with a bunch of build-targets (or functions) that are defined like so:

{% gist 5983671 make-targets %}

Each target is on it's own line, and it's the target named follow by a colon.  `all:` is a the target that is run when you don't specify another target, so it's a good place to either build your whole app, or in our case, show a help message.

Each line below the target is a command to run.  Whitespace is important here, each line indented by a tab character tells make that's a shell command it should run.

{% gist 5983671 make-variables %}

Make also has the concept of variables, but unlike shell or bash, whitespace is not important here, you can have as many spaces you like either side of the equals sign.

{% gist 5983671 Makefile %}

Finally, this is our complete makefile for our plugin.  It should live in the same directory as our plugin files, and it should be named `Makefile` (capitalisation is important).

Our first 3 lines define some variables for us to use in the makefile.  Specifically, the directory to install the files, the loader we want to make executable, and the script files we just want to copy.

Line 4 is a bit different, it just adds to the `COMMANDS` variable, like the `.=` operator in PHP.

Finally, we get on to our build targets.  As mentioned above, our default build target, `all:` just prints out some usage information.

Our `install:` target runs a few bash commands.  It uses the `install` command to first ensure our install directory is created and has the correct permissions (`-d` and `-m` flags respectively), and then uses the install command to copy our loader to our install directory with executable permissions (755), and our subcommand files with just regular permissions.

Our `uninstall:` command does something similar in that it just runs a bunch of shell commands again.  It first tests to make sure our install directory exists, it then changes into that directory and uses `rm` to remove the files.  Fairly simple.

We use the backslash operator to tell uninstall this is a single command run over several lines, so that they are executed together rather than one at a time (and will exit without running the rest if any of them fail).

Once this file is in place you can simply run `make install` and `make uninstall` from the same directory as your makefile to copy or delete the plugin to the right place with the right permissions.  This is super useful if you intend to distribute your plugin!

##Summary

In these two posts we've learnt that creating a git plugin is as simple as writing an executable script and naming it in the format `git-pluginname`, and then putting it somewhere accessible.

We've also looked at some more advanced techniques to get you building more complex plugins with multiple subcommands and arguments, and finally how to use gnumake to make installing and uninstalling your plugin really easy for anyone you care to distribute it to.

If you want more content like this, and access to a couple of my own git-plugins I'm going to be open sourcing soon, subscribe to my feed on the right or the mailing list below!

## Read Next

* [Git - A clean branch switching strategy](/2012/08/03/git-cleanly-move-between-branches.html)

[^1]: http://www.gnu.org/software/make/
[^2]: http://en.wikipedia.org/wiki/Convention_over_configuration
