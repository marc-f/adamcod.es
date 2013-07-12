---
layout: post
title: How to Create a Git Plugin
---
I think most Git users know by now how to create an alias in Git to make a function or command more accessible.  What I think fewer people know, or at least don't take advantage of, is that you can actually create extensions or plugins to Git to make it do basically anything you want.

What I think even fewer people realise is actually how amazingly easy it is to create one of these extensions.

##What You Need to Know (The Essentials)

1. Create a shell or bash script that does what you want to do
2. Name your shell script git-_name_ where _name_ is the command you want to run after typing `git`.
3. Put your script in `/usr/local/bin` or somewhere similar in your `$PATH`
4. Run your script using `git name`

Using this method you can make Git do anything you want.  However, what you might want to consider is grouping a bunch of similar scripts together into a module of sorts, much like the Git flow plugin[^1].  This would allow you to run your command namespaced, so you could have (for example): `git yourname subcommand` or `git mycompany deploy`.

##More Advanced Usage

Here's the basic concept:

1. Create a "wrapper" or access point for your plugin
2. Create a file/script for each sub-command you want to run
3. Use your wrapper to load and run your sub-command scripts

###Defining Some Requirements

For the sake of simplicity, I'm going to call our namespace "adamcodes" and our plugin is going to do three things:

1. Report its version with the `-v` or `--version` flags
2. Display usage information if the subcommand is missing, or the `-h` or `--help` flags are used
3. Print `Hello {name}|World` when we use the `hello` subcommand, printing out `Hello {name}` if any further options are passed, or `Hello World` if not.

###Getting Started

First, let's create a directory to work in: `mkdir -p ~/src/adamcodes-git-plugin && cd ~/src/adamcodes-git-plugin`.

Now we need to create our wrapper file.  This is the file that will run all of our commands, it will actually be the only executable file in our plugin.

This file needs to be named in the following format, this is essential or Git won't be able to find it.

`touch git-adamcodes`

That's it.  It has to start with `git-` and then the bit that follows is the command you'll use to run it.

Now let's edit that file and add some stuff.  The first line of every executable script is the hashbang or shebang.  This is so the operating system knows what to use to run your script.

You could use PHP, Ruby, Python or whatever here and Git should just run it as normal.  I haven't tested that though, so I'm going to stick to using bash.

###Main Script (Wrapper/Runner)

A hashbang looks like this:

{% gist 5983671 hashbang.sh %}

Now most people will have a compatible shell available in that location, but we can make it a bit more portable by checking the users' ENV for the location of their shell, just in-case:

{% gist 5983671 hashbang-env.sh %}

Next, we need a couple of help functions.  These should be fairly self explanatory, they just print words to the screen.  The first is going to print out our version number:

{% gist 5983671 version.sh %}

And the next is going to print our usage information:

{% gist 5983671 usage.sh %}

Next, we get into the main part.  Tradition dictates that the main execution of a bash script takes place in the `main` function, so that's what we'll call ours, too:

{% gist 5983671 main.sh %}

Okay, if you're not used to shell scripting this will probably look a bit scary.  Let's break it down piece-by-piece.

{% gist 5983671 param-count.sh %}

This first line is fairly simple.  When you pass an argument to a shell script it gets passed in in numbered variables $0 to $N.  Each space is treated as a new variable, with $0 containing the name of the script you ran.  `if [ "$#" -lt 1 ]` is basically saying "if the number of options is less than one".

As we're always expecting a subcommand, we can assume if the number of options is less than 1 we have an error, and should display our usage information.  That's what the next line does `usage` simply runs the `usage` function we defined above.

`exit 1` is all about reporting back to Git (and the shell) whether a command ran successfully or not.  `exit` will kill the execution of a script, just like in PHP, and a successful exit means exiting with `0`.  An exit in the range `1-255` is considered an error and can be used to map to error messages if you have a manual or whatever.  We don't, so we'll just exit with 1 to let the shell know it didn't run successfully, as we expected more parameters.

{% gist 5983671 get-subcommand.sh %}

The next line does two things again.  You can do more than one thing per line in bash by separating with a semi-colon.  If you put them one per line you don't need the semi-colon.  First, we define a local variable called `subcommand`, hence, the `local`, and then we're assigning the first parameter passed to our script into that variable.

The `shift` function moves the numbers for passed variables along the number of spaces passed to it.  That is to say, if we called our script like so:

    ./script.sh hello world this is a test

We would end up with the following:

    $0: ./script.sh
    $1: hello
    $2: world
    $3: this
    $4: is
    $5: a
    $6: test

If we called `shift` without any number afterwards, it will just move things along one space, so in our example this would leave us with:

    $0: ./script.sh
    $1: world
    $2: this
    $3: is
    $4: a
    $5: test

If we then called `shift` but this time passed in the number 2, like so: `shift 2` we should end up with:

    $0: ./script.sh
    $1: this
    $2: is
    $3: a
    $4: test

You'll notice the script name always remains in `$0`, this is important for later.

{% gist 5983671 test-for-version-or-help.sh %}

Next we use a standard case statement to check whether the subcommand we just set is equal to `-h`, `--help`, `-v` or `--version`.  As per our spec above, each of these should run a specific function.  If we find a match we simply run the correct function and exit with 0, which means that we ran successfully.  the `;;` below each set of commands is the equivalent of `break` in PHP and tells the shell to not continue checking the rest of the case statement.

{% gist 5983671 get-working-dir.sh %}

This next snippet gets our working directory.  We need this so we know where to look for our sub-command files, as they should be in the same directory as the script we're running.

To do this, we use a couple of bash tricks.  First, we create a local variable as we did before.  We then use `$(...)`, which allows you to execute a command and capture the result into the variable.

The bash function we're calling is dirname, which like the PHP equivalent takes the name of a file and provides you with the directory name.

As we mentioned earlier, when you run a bash script the script name gets passed into the script in the variable `$0`, so running `$(dirname $0)` should give us what we're after, however, that's not so great for our windows users (e.g. cygwin), as the path separator will be the wrong way around.  Therefore, we nest another `$(...)` call where we echo out the value of `$0`, pipe the output into the `sed` command, and replace all backslashes with forward slashes.  We then take the output of that (captured by the nested `$(...)`) and pass it back into dirname, and then assign the captured output of that to the `workingdir` variable.

{% gist 5983671 check-file-exists.sh %}

Next, we're simply checking to see if the file for the subcommand exists.  We're expecting the files to be in the same directory as our current file, and to be named in the format `git-namespace-subcommand`.  If we don't find it, we need to print out our usage info and exit with an error status.  If we do, we can simply carry on.

{% gist 5983671 load-file.sh %}

`source` is a built-in command that will run a file inside the current shell.  That means it will load all functions and variables from that file and they will be available throughout the shell.  Anything that this script executes will also execute, it's exactly the same as running the file yourself.

This means we can put our sub-commands in their own files, with their own variables, but not run them, just make them accessible when we need them.  Think of this like a PHP `include`.

{% gist 5983671 make-sure-file-includes-subcommand.sh %}

Now we've loaded the file, we should have the sub-command function available to execute, so we test to make sure it exists.  If it doesn't there's obviously something wrong, so do our standard "print usage information and error exit status" step.

{% gist 5983671 run-command.sh %}

Finally we get down to it.  This step runs our sub-command and passes in our `$0...$n` variables as function parameters.  We expect our sub-command's main function to be called `cmd_subcommand` where _subcommand_ is the name of the sub-command you want to type to run it.  If we also called them `main` we'd end up with a conflict with our existing main function.

The reason we used `shift` earlier is so that we can write our sub-commands without any knowledge of this wrapper, as far as they're concerned the variables that get passed in are the same as if they were called directly (without the sub-command name in `$1`).

Now we've built up our `main` function it won't run on its own, we need to actually call it and pass in our `$0...$n` variables.  To do that, we just do the same as above, but call main instead:

{% gist 5983671 runit.sh %}

####Pulling it all Together

Finally, bringing it all together our plugin's main file should look like this:

{% gist 5983671 git-adamcodes.sh %}

In part 2 (early next week) I'll go on to create our hello sub-command, and show you how to write a makefile and use make so installing and removing your add-on becomes really simple.  Make sure you subscribe to my feed so you don't miss it!

[^1]: https://github.com/nvie/gitflow
