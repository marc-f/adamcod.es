---
layout: post
author: adam
title: Git - A clean branch switching strategy
summary: Some git strategies swapping branches without bringing the uncommitted or experimental changes with you
---

##Background

You're working on `feature/awesome-new-stuff` and have a whole bunch of changes that you don't want to commit yet, and you get a call about a bug that needs to be fixed asap.  You checkout develop, create a hotfix branch and make your changes.  Then you do `git status` and see all of your experimental changes from `feature/awesome-new-stuff` have come with you, making it harder to spot the changes relating only to the hotfix.

##The Quick and Dirty

The simplest way to avoid this is to stash any changes before you move to another branch, this looks something like this:

{% gist 3075876 quick-and-dirty.sh %}

However, if you find yourself doing this a lot, for a lot of different features and branches, this can get messy pretty quickly.  Instead, why not leverage the flexibility of git and just commit early and often, and simply amend as you go:

{% gist 3075876 wip.sh %}

Because you are working locally in git commits can be undone and re-done at will, it's only when you push the commit to a central repository that you need to pay serious attention.

So create a work in progress commit, and then use `git commit --amend` to add to it often.  Then when you go to switch branches to work on another feature you don't have to worry about stashing and popping or bringing changes with you.

When you're ready for the real commit on a branch you can run:

{% gist 3075876 finish.sh %}

The first reset will undo your last commit (the WIP commit), with the second reset un-staging the files.  You can now re-commit all of your changes paying more serious attention to your commit message.
