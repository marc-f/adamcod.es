---
layout: post
title: Getting Started with dotCloud's Docker
---

If you haven't seen it yet, Docker is the new hotness on the server.  Docker is a Linux Container manager that lets you build independent images which can then be deployed anywhere docker is installed.

What's all the fuss about?
--------------------------

Docker lets you build an image on your local machine, or in your dev environment or on a build server (or anywhere you like) which you can then deploy to any server running docker.

Why is this a good thing?  A Docker image contains everything your app needs to run, this is everything from the OS packages up, meaning the only thing you need to configure on the server is docker.

Need a new copy of your app running? Provision a server with docker running, copy your image over, and then run `docker run yourapp` and it's ready to go.  Everything inside the container is unaware that it's running inside the container.

There are hundreds if not thousands of possibilities for this, most of which we're only just beginning to explore.  Currently I use it for a MySQL image on a dev server which is automatically deploys multiple git branches.  This allows us to add `docker run mysql` into our deployment scripts for our dev branches and have a pre-configured MySQL instance ready to run that new feature, allowing our users to test each feature individually without worrying about side effects.

Linux containers (though not docker itself) are also at the core of technologies such as Heroku, and there is even a small bash script called Dokku[^1] which uses Docker to create a Heroku like environment on your own servers.

Getting Started
---------------

