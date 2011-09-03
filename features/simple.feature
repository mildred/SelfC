Feature: Syntax parsing

  Background:
    Given a file "code.self" with
      """
      string:
        (|
          println =
          (
            "Invoke the builtin $external slot which invoke the puts function
             with the parameter $content: 1 which is i8*. $content: 0 is the
             string length"
            $external: 'puts' With: $content: 1.
          )
        |).
        
      """

  @wip
  Scenario:
    Given I append to "code.self":
      """
      (
        'Hello World' println
      )
      """
    When I execute the cluster "code.self"
    Then I should see
      """
      Hello World
      
      """

  @wip
  Scenario:
    Given I append to "code.self":
      """
      ( | hello = 'hello world' |
        hello println
      )
      """
    When I execute the cluster "code.self"
    Then I should see
      """
      hello world
      
      """

  @wip
  Scenario:
    Given I append to "code.self":
      """
      ( |
          main = ( 'Doing' println )
        |
        'Welcome' println.
        main
      )
      """
    When I execute the cluster "code.self"
    Then I should see
      """
      Welcome
      Doing
      
      """
