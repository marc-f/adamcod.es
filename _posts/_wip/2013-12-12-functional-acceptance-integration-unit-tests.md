---
layout: post
title: Acceptance vs Functional vs Integration vs Unit Tests
---

Once upon a time, a developer came to me very excited:

    "I just spoke to marketing and they want us to write something to help them manage Widgets!".
    "That's great", I said, "What's your next step?".
    "Well", continued the developer, "I'm going to start by adding a new database table called `widgets`, then I'm going to add a new controller and mapper and gateway, all called `Widgets`, at which point I'm going to..."
    "Stop", I interrupted.
    "How do you know this solves your users problem?".

The developer paused for a minute to think.

    "Well, they want to manage Widgets, so they're going to need a database table".
    "Okay," I said, "does the user care that you're storing the Widgets in a database table?".
    "Of course!" retorted the developer, "how else are they going to manage them?"
    "Isn't that what the software you're building is for?"
    "Yes, and that needs a database table!"
    "Does it?  What if you used text files instead?" I asked.
    "That would be silly, it's so much easier to use a database".
    "Yes, it is, for you, but your user doesn't care if the Widgets are stored in a database, a whole bunch of text files, or etched on the moon with a giant laser.  What the user cares about is that the Widget they enter into the system is still there when they go to view it later."
    "I think I understand what you're saying", the developer concluded.

This developer made the classic mistake of confusing functionality with implementation.  This is the same problem people have when trying to understand the different types of tests that are available, so here is how you tell the difference to avoid making this mistake yourself.

Acceptance Tests
----------------

Acceptance tests, as the name suggests, are the tests used by the end user to certify the work as complete.  These could be as detailed or as broad as you like, and often merge with functional tests.  Here is an example of an acceptance test:

    When I visit the widget page and click on the "New Widget" button I will be able to complete a form with all of the details about the Widget, and when I click "Save Widget" button the widget will be saved.

The acceptance test is fairly broad, and allows for a large number of possible solutions and implementations.  You and your users may or may not be comfortable with this.

The key here is that the acceptance tests are used to sign off the system, this is the set of criteria that the system will be checked against, so they should be as specific or as broad as your project requires.

Acceptance tests are always written from the point of view of the user, they should be written in the language of the business, and not the language of the computer.  There should be no mention of databases, file structures, controllers, nor anything else that your average user wouldn't understand in the day-to-day process of doing their job.

Acceptance tests usually aren't automated or programmable, so there's no real framework or structure to them, unless you use your functional tests as your acceptance tests.

Functional Tests
----------------

Functional tests start to get a bit more specific, but they are still entirely in the language of the business.  In some cases, your functional tests may also be your acceptance tests.  This is okay.

There is an entire language created just for writing functional tests, called Gherkin[^1].  Functional tests use the Gherkin syntax, and the "Given-When-Then" pattern to describe specific interactions with the system, but entirely from the point of view of the user.  Your functional tests should never check that a database record was created, or mention any programmer terms that your users wouldn't understand in the context of their day-to-day job.  Here is an example of a functional test:

{% highlight gherkin %}
Feature: Store and manage Widgets
  In order to better provide our customers with information on Widgets
  As an member of the marketing team
  I want to manage information about Widgets in a digital system we can share with customers

  Scenario: Add a new Widget to the system
    Given I am on the "Add Widget" page
     When I fill in the "Widget Name" with "Lorum"
      And I fill in the "Widget Description" with "Dolor Sit Amet."
      And I select "Expensive" as the price
      And I click "Save Widget"
     Then I should be redirect back to the list of Widgets
      And I should see "Your widget was added successfully"
{% end highlight %}

And here it is again with the steps generalised into a template:

{% highlight gherkin %}
Feature: Some terse yet descriptive text of what is desired
  In order to realize a named business value
  As an explicit system actor
  I want to gain some beneficial outcome which furthers the goal

  Scenario: Some determinable business situation
    Given some precondition
      And some other precondition
     When some action by the actor
      And some other action
      And yet another action
     Then some testable outcome is achieved
      And something else we can check happens too
{% end highlight %}

You can see here, functional tests are getting much more specific, they're talking about pages in a system and forms that a user will be interacting with, but at no point does it say "When I `POST` to the `AddAction` of the `WidgetsController`" or anything similar the business users do not care about.

Under the "Store and manage Widgets" feature, you could expect to have a whole bunch of scenarios relating to that feature, including how you edit/delete/view a Widget, what the user sees if they enter invalid information in the form and any other situations that might arise as part of that feature.

The key for functional tests is to be very specific about how the user interacts with the system, what the user will see, and how they will complete tasks required for the feature without mentioning programming or implementation related.

You would usually test the full stack with your functional tests, including JavaScript.  You can use any of a number of headless browsers to achieve this, or use something like Selenium to drive an actual browser like Firefox or Chrome.  In terms of frameworks, Behat[^2] and Mink [^3] are designed to do this out of the box, and PHPUnit[^4] has some useful features to help make this work too.  StoryPlayer[^5] is a new project in this area that's also work keeping an eye on.

Integration Tests
-----------------

Integration tests are not for the user.  The user does not care about integration tests, which means we can now start using some code.  Integration tests should be testing how the components of our system work together, from your app, through the framework all the way to the database (if you're using one).  You don't need to worry about your JavaScript or browser here, this is all about your PHP code.

Integration tests still follow the "Given-When-Then" pattern, but integration tests care more about the actions and controllers being dispatched, and the side-effects that that produces.  Here is the above functional test re-written as an integration test in PHPUnit (simplified):

{% highlight php %}
<?php

class WidgetsTest extends \PHPUnit_Framework_TestCase
{
    protected $app;
    protected $request;
    protected $response;

    public function setUp()
    {
        $this->pdo = new \PDO();
        $this->app = new \My\App();
        $this->request = new \My\App\Request();

        parent::setUp();
    }

    public function testAddNewWidget()
    {
        // When I fill in with...
        $widget = $this->getWidgetFixture();
        $this->setPost($widget);

        // I click "Save Widget"
        $this->dispatch(['controller' => 'widgets', 'action' => 'add']);

        // Make sure it's actually saved
        $this->assertWidgetTableMatch('widgets', $widget);

        // I should be redirected
        $this->assertRedirect(['controller' => 'widgets', 'action' => 'index']);

        // I should see...
        $this->dispatch(['controller' => 'widgets', 'action' => 'index']);
        $this->assertContains("Your widget was added successfully", $this->response->getBody());
    }

    // test helper functions
    protected function assertRedirect(array $action, $message = '')
    {
        $this->assertTrue($this->response->isRedirect(), $message);
        $this->assertEquals($action, $this->response->getRedirect(), $message);
    }

    protected function assertWidgetTableMatch($data, $message = '')
    {
        $stmt = $this->pdo->prepare('SELECT * FROM `widgets` WHERE id = :id');
        $stmt->execute(array('id' => $data['id']));
        $result = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        $this->assertEquals($data, $result, $message);
    }

    protected function dispatch(array $action)
    {
        $this->app->setRequest($this->request);
        $this->response = $this->app->dispatch($action);
    }

    protected function setPost(array $widget)
    {
        $this->request->setPost($widget);
    }

    protected function getWidgetFixture()
    {
        return [
            'name' => 'Lorum',
            'description' => 'Dolor sit amet.',
            'price' => 'Expensive'
        ];
    }
}
{% endhighlight %}

Here, we're checking our full application stack, but in a programmable way, so we don't actually use a web server.  What we're really saying is:

  1. Given this very controlled and known environment
  2. When I dispatch this action in this environment
  3. Then the environment should end up in this expected state

The key point for an integration test is that we do care about how the functionality is implemented overall, but we don't care about the minutiae of each action.

We want to make sure that when we dispatch a specific action and controller in our full application that we get the correct side effects (i.e. a record in the database and a redirect), but we don't care if you have a `flashMessenger` helper to display the message, nor do we care if you have a `redirector` helper to set the redirect.  Calling `$_SESSION` and `header()` directly would both be perfectly valid solutions in this instance.  At this stage, we're still testing functionality, but we're testing is as a programmer would think about it, not a user.

Generally speaking, you won't want to use mocks in your integration tests.  The one exception being 3rd party services and APIs that you can't create a controlled environment for locally.

THe key frameworks here are really Behat and PHPUnit.

Unit Tests
----------

Finally, we have the most common form of automated tests, unit tests.  Unit tests are just that.  The smallest part of your code you can possibly think to test, not just a class or method, but a single path through a method in a single state.  Every single NPath for your method should have a test.

Each unit of code should be tested in isolation, and without relying any external dependencies.  All of your external dependencies should be replaced with Mocks, Stubs, or Fakes that you control and know the exact state of, so you can say definitively: If I create this object and execute this method in this state with these dependencies in this state, it will **always** do _this_.

Here's an example of a unit test:

{% highlight php %}
<?php
class WidgetGatewayTest extends \PHPUnit_Framework_TestCase
{
    public function testInsertStoresNewWidget()
    {
        $widget = $this->getWidgetFixture()
        $gateway = new WidgetGateway($this->getPdoMock($widget));
        $this->assertTrue($gateway->store($widget);
    }
{% endhighlight %}
{% highlight php %}
<?php

class WidgetGatewayTest extends \PHPUnit_Framework_TestCase
{
    public function testInsertStoresNewWidget()
    {
        $widget = $this->getWidgetFixture()
        $gateway = new WidgetGateway($this->getPdoMock($widget));
        $this->assertTrue($gateway->store($widget);
    }

    protected function getPdoMock()
    {
        $pdo = $this->getMock('\PDO');

        $pdo->expects($this->once())
            ->method('prepare')
            ->with($this->equalTo(
                'INSERT INTO `widgets` (`name`, `description`, `price`) VALUES(:name, :description, :price)'
            ))
            ->will($this->returnValue($this->getStatementMock($widget)));

        return $pdo;
    }

    protected function getStatementMock($widget)
    {
        $stmt = $this->getMock('\PDOStatement');
        $stmt->expects($this->once())
            ->method('execute')
            ->with($this->equalTo([
                ':name'=> $widget['name'],
                ':description'=> $widget['description'],
                ':price'=> $widget['price']
            ]))
            ->will($this->returnValue(true));
    }

    protected function getWidgetFixture()
    {
        return [
            'name' => 'Lorum',
            'description' => 'Dolor sit amet.',
            'price' => 'Expensive'
        ];
    }
}
{% endhighlight %}


[^1]: http://docs.behat.org/guides/1.gherkin.html
[^2]: http://behat.org/
[^3]: http://mink.behat.org/
[^4]: http://phpunit.de/manual/3.8/en/selenium.html
[^5]: http://datasift.github.io/storyplayer
