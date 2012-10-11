---
layout: post
author: adam
title: Git - Help! I made my changes on the wrong branch (easy fix)
summary: A simple git one-liner that will help you when you make changes to the wrong branch
---

## We've all done it ##

You get an emergency email from your boss and have to immediately drop everything you're doing to solve his problem.  You listen to what's wrong and make all the necessary changes, test it, and then you're ready to commit, only you're on `feature/awesome-new-stuff` and forgot to checkout `develop` before you made your changes. \*\*\*\*.

_All is not lost_[^1]

Pre-git, I have no idea how I would have fixed this.  Separating your fixes with your feature changes would probably have been done by hand, and taken ages.

However thanks to git we can simply checkout the correct branch, and and our untracked changes will move with us.

## If you've not committed yet ##

First, make sure all of your *feature* changes are committed to the correct branch (but *not* the fixes you want to move!), then:

{% gist 3047748 checkout.sh %}

Be sure to replace `<branch>` with the name of the branch you actually want to commit to.

## If you've already committed the changes ##

If you've already committed your changes, you need to do a SOFT reset. A soft reset will put your changes back into the index, instead of destroying them like a HARD reset would:

{% gist 3047748 soft-reset.sh %}

A quick note here, the ^ is the number of commits to roll-back, so if you wanted to go back 2 commits, you'd use:

{% gist 3047748 soft-reset-2.sh %}

and for 3 commits

{% gist 3047748 soft-reset-3.sh %}

and so on... then you can run the [checkout](#if-youve-not-committed-yet) command above.

## If there is a conflict between the two branches ##

If the changes you want to move will conflict with something on the branch you're moving to git will simply refuse to checkout the new branch.  In this instance you want to use the stash-checkout-pop command like so:

{% gist 3047748 stash-checkout-pop.sh %}

This will stash the changes so you have nothing to move, then checkout the new branch (as with nothing to move there can be no conflicts), and finally pop the stashed changes into the new branch ready for committing.

[^1]: Unless you've made changes in the same files as your fixes, you'll have to find another way, sorry!
