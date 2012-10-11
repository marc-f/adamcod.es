---
layout: post
author: adam
title: Make a circle thumbnail with the Imagine PHP Image Library
summary: A Filter for the Imagine PHP Image Library to create circle thumbnails
---

## What is Imagine ##

Image processing in PHP is _really_ unpleasant.  Imagine is a PHP 5.3 library which makes image processing suck way less.  According to the [documentation](http://imagine.readthedocs.org):

> [Imagine](https://github.com/avalanche123/Imagine) is a\[n\] OOP library for image manipulation built in PHP 5.3 using the latest best practices and thoughtful design that should allow for decoupled and unit-testable code.

Put simply, Imagine is a nicely PSR-0 namespace'd wrapper that provides a consistent interface for lower level Gd, ImageMagick and GMagick functionality.  And _consistency is good_.

If you haven't heard of Imagine, or aren't familiar with its concepts, go [here](https://speakerdeck.com/u/avalanche123/p/introduction-to-imagine) and read the presentation first, as the code below assumes a knowledge of its features concepts.

## The Problem ##

Whilst re-working an area of our internal CRM, we came up with the idea of cards.  These would be little snippets of information about people, companies, products and other CRM objects related to the page you're on, neatly stacked in order of importance down the right-hand side of a page.

Here's an initial concept for a contact card:

![Contact Card Square](/assets/img/posts/contact-card-square.png)

Pretty good, but we decided we can do a bit bitter, and rounded pictures would be a bit friendlier:

![Contact Card Round](/assets/img/posts/contact-card-face.png)

Only problem, that makes coding the thumbnails a lot harder.  Our users aren't going to upload nice transparent rounded pictures for us, so we're going to have to find a way to process them ourselves.

## Enter Imagine ##

Having read about Imagine, it had peaked my interested, and I'd wanted to use it on a project for a while.  It turns out that creating a circle thumbnail with Imagine is actually really easy.  Much like most custom things in Imagine, you want to create a filter, I called mine `CircleThumbnailFilter` (original, I know).  It looks like this:

{% gist 3060605 CircleThumbnailFilter.php %}

The constructor is fairly self explanatory, it takes an instance of your imagine interface, and a box instance which is used to control the size of your thumbnail.

The apply function is the one that does the work, it is required to take exactly one parameter, an instance of `Imagine\Image\ImageInterface` which is enforced by `Imagine\Filter\FilterInterface`.

The first thing we do is resize our image, if someone uploads a 1000x1000 image, we want to scale it down.

Next, we create a canvas and call it `$mask`.  We so this by calling the `create` method on the `ImageInterface` we passed to our constructor.  We pass in the `BoxInterface` we also passed to our constructor to tell it the size of the image we want to create, and a new `Imagine\Image\Color` to tell it the background colour we want.  We then end up with a brand-new instance of `Imagine\Image\ImageInterface` in `$mask`.

Next, we call the draw method on the image stored in $mask to load the `Drawer` object, and then we tell it to draw us an ellipse.

We first pass in the position we want the ellipse drawn at, which is the exact center of the Box we've been using all the way through, we tell it that we want our ellipse to be the same size as our box (i.e. to fill it), and we tell it to make it black, with no transparency, and finally we pass `true` which tells it that it should be filled, rather than an outline.

Once we have our mask created, if we were to save it, it would look something like this:

![Contact Card Mask](/assets/img/posts/contact-card-mask.png)

We don't want to output our mask though, we just want to use it to make parts of our square thumbnail transparent.  To do that we use Imagine's built-in applyMask filter, passing the mask we created earlier in as the only parameter.  We can then return this image so we can use it in our scripts.

## Usage ##

To use the filter, you need to include Imagine using [one of the methods in the documentation](http://imagine.readthedocs.org/en/latest/usage/introduction.html#installation), I recommend installing it via [composer](http://getcomposer.org), as Imagine is available on [packagist](http://packagist.org/packages/imagine/Imagine), and then using the composer autoloader to load Imagine via the PSR-0 namespace syntax.

You will also need to autoload or require the CircleThumbnailFilter object somehow, you could put it in your app's namespace or just do it the old-school way with `require_once`.  Either way, when both are loaded, you can run the circle filter like so:

{% gist 3060605 usage.php %}

Make sure that no-matter what your input format (which isn't really important, Imagine should know what to do with most valid image formats), make sure you output it as something with transparency (preferably png).  Don't do what I did and spend 40 minutes wondering why the transparency mask wasn't applying when you were outputting as a jpg.