---
layout: post
author: adam
title: Unable to run 'adb', Andriod SDK, Ubuntu, Eclipse
summary: If you get this frustraiting and confusing message when trying to install the andriod SDK in Ubuntu, the fix is pretty easy.
---

If you get the following really annoying message while trying to install the andriod SDK on ubuntu:

<pre><code>Stopping ADB server failed (code -1).
Unable to run 'adb': Cannot run program "/home/user/android-sdk-linux/platform-tools/adb": java.io.IOException: error=2, No such file or directory.
Starting ADB server failed (code -1).
</code></pre>

It's because you're running 64bit ubuntu, and phones (and therefore the SDK) are only 32bit, if you run:

<pre><code>apt-get install ia32-libs</code></pre>

It will solve all of your problems and the SDK will install correctly.
