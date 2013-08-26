---
layout: post
author: adam
title: Class 'String' not found in app/Model/User.php on line xx
summary: This is a rare error that may crop-up when developing a CakePHP application - this is how to solve it
---

This is a really easy to fix error that occurs in a very specific situation.  Namely when developing an application in CakePHP that makes use of the ACL behavior whilst also having a `beforeSave` method on the User model.  It can be pretty frustrating at first because there's nothing about it on the Internet, and as far as you can tell, there isn't an error on line xx, and you're not using the String object anywhere.

It's happening because of a missing options array on the `beforeSave` method you added to the User model.  Simply change:

{% highlight php linespans %}
<?php
    public function beforeSave() {
{% endhighlight %}

to

{% highlight php linespans %}
<?php
    function beforeSave($options = array()) {
{% endhighlight %}

and make sure that you call `parent::beforeSave($options)` somewhere in your method definition.
