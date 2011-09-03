Feature: Syntax parsing

  @wip
  Scenario:
    Given I append to "code.self":
      """
      string:
        (|
          println =
          (
            "Invoke the builtin :$external slot which invoke the puts function
             with the parameter :$content: 1 which is i8*. :$content: 0 is the
             string length"
            :$external: 'puts' With: (:$content: 1).
          ).
        |).
        
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
      string:
        (|
          println =
          (
            "Invoke the builtin :$external slot which invoke the puts function
             with the parameter :$content: 1 which is i8*. :$content: 0 is the
             string length"
            :$external: 'puts' With: (:$content: 1).
          ).
        |).
        
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
      string:
        (|
          println =
          (
            "Invoke the builtin :$external slot which invoke the puts function
             with the parameter :$content: 1 which is i8*. :$content: 0 is the
             string length"
            :$external: 'puts' With: (:$content: 1).
          ).
        |).
        
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
