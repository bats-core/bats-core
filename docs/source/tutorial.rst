Tutorial
========

This tutorial is intended for beginners with bats and possibly bash.
Make sure to also read the list of gotchas and the faq.

For this tutorial we are assuming you already have a project in a git repository and want to add tests.
Ultimately they should run in the CI environment but will also be started locally during development.

..
    
    TODO: link to example repository?

Quick installation
------------------

Since we already have an existing git repository, it is very easy to include bats and its libraries as submodules.
We are aiming for following filesystem structure:

.. code-block:: 

    src/
        project.sh
        ...
    test/
        bats/               <- submodule
        test_helper/
            bats-support/   <- submodule
            bats-assert/    <- submodule
        test.bats
        ...

So we start from the project root:

.. code-block:: console
    
    git submodule add https://github.com/bats-core/bats-core.git test/bats
    git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
    git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert

Your first test
---------------

Now we want to add our first test.

In the tutorial repository, we want to build up our project in a TDD fashion.
Thus, we start with an empty project and our first test is to just run our (non existing) shell script.

We start by creating a new test file `test/test.bats`

.. code-block:: bash

    @test "can run our script" {
        ./project.sh
    }

and run it by

.. code-block:: console

    $ ./test/bats/bin/bats test/test.bats
     ✗ can run our script
       (in test file test/test.bats, line 2)
         `./project.sh' failed with status 127
       /tmp/bats-run-19605/bats.19627.src: line 2: ./project.sh: No such file or directory

    1 test, 1 failure

Okay, our test is red. Obviously, the project.sh doesn't exist.
Let us fix both problems. First, we create the file `src/project.sh`:

.. code-block:: console

    mkdir src/
    echo '#!/usr/bin/env bash' > src/project.sh
    chmod a+x src/project.sh

A new test run gives us

.. code-block:: console

    $ ./test/bats/bin/bats test/test.bats
     ✗ can run our script
       (in test file test/test.bats, line 2)
         `./project.sh' failed with status 127
       /tmp/bats-run-19605/bats.19627.src: line 2: ./project.sh: No such file or directory

    1 test, 1 failure

Oh, we still use the wrong path. No problem, we just need to use the correct path to `project.sh`.
Since we're still in the same directory as when we started `bats`, we can simply do:

.. code-block:: bash

    @test "can run our script" {
        ./src/project.sh
    }

and get:

.. code-block:: console

    $ ./test/bats/bin/bats test/test.bats 
     ✓ can run our script

    1 test, 0 failures

Yesss! But that victory feels shallow: What if somebody less competent than us starts bats from another directory?

Let's do some setup
-------------------

The obvious solution to becoming independent of `$PWD` is using some fixed anchor point in the filesystem.
We can use the path to the test file itself as an anchor and rely on the internal project structure.
Since we are lazy people and want to treat our project's files as first class citizens in the executable world, we will also put them on the `$PATH`.
Our new `test/test.bats` now looks like this:

.. code-block:: bash

    setup() {
        # get the containing directory of this file
        # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
        # as those will point to the bats executable's location or the preprocessed file respectively
        DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
        # make executables in src/ visible to PATH
        PATH="$DIR/../src:$PATH"
    }

    @test "can run our script" {
        project.sh # notice the missing ./
    }

still giving us:

.. code-block:: console

    $ ./test/bats/bin/bats test/test.bats 
     ✓ can run our script

    1 test, 0 failures

What happened? The newly added `setup` function put the absolute path to `src/` onto `$PATH`.
This setup function is automatically called before each test.
Therefore, our test could execute `project.sh` directly, without using a (relative) path.

Dealing with output
-------------------

Okay, we have a green test but our executable does not anything useful.
To keep things simple, let us start with an error message. Our new `src/project.sh` now reads:

.. code-block:: bash

    #!/usr/bin/env bash

    echo "Welcome to our project!"

    echo "NOT IMPLEMENTED!" >&2
    exit 1

And gives is this test output:

.. code-block:: console

    $ ./test/bats/bin/bats test/test.bats 
     ✗ can run our script
       (in test file test/test.bats, line 11)
         `project.sh' failed
       Welcome to our project!
       NOT IMPLEMENTED!

    1 test, 1 failure

Okay, our test failed again, because we now exit with 1 instead of 0.
Additionally, we see the stdout and stderr of the failing program.

Our goal now is to retarget our test and check that we get the welcome message.
bats-assert gives us some help with this, so we should now load it (and its dependency bats-support),
so we change `test/test.bats` to

.. code-block:: bash

    setup() {
        load 'test_helper/bats-support/load'
        load 'test_helper/bats-assert/load'
        # ... the remaining setup is unchanged

        # get the containing directory of this file
        # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
        # as those will point to the bats executable's location or the preprocessed file respectively
        DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
        # make executables in src/ visible to PATH
        PATH="$DIR/../src:$PATH"
    }

    @test "can run our script" {
        run project.sh # notice `run`!
        assert_output 'Welcome to our project!'
    }

which gives us the following test output:

.. code-block:: console

    $ LANG=C ./test/bats/bin/bats test/test.bats 
     ✗ can run our script
       (from function `assert_output' in file test/test_helper/bats-assert/src/assert_output.bash, line 194,
        in test file test/test.bats, line 14)
         `assert_output 'Welcome to our project!'' failed
    
       -- output differs --
       expected (1 lines):
         Welcome to our project!
       actual (2 lines):
         Welcome to our project!
         NOT IMPLEMENTED!
       --
    

    1 test, 1 failure

The first change in this output is the failure description. We now fail on assert_output instead of the call itself.
We prefixed our call to `project.sh` with `run`, which is an internal bats function that executes the command it gets passed as parameters.
Then, `run` sucks up the stdout and stderr of the command it ran and stores it in `$output`, stores the exit code in `$status` and returns 0.
This means `run` never fails the test and won't generate any context/output in the log of a failed test on its own.

Failing the test is and printing context information is up to the consumers of `$status` and `$output`. 
`assert_output` is such a consumer, it compares `$output` to the the parameter it got and tells us quite succinctly that it did not match in this case.

For our current test we don't care about any other output or the error message, so we want it gone.
`grep` is always at our fingertips, so we tape together this ramshackle construct

.. code-block:: bash

    run project.sh 2>&1 | grep Welcome

which gives us the following test result:

.. code-block:: console

    $ LANG=C ./test/bats/bin/bats test/test.bats 
     ✗ can run our script
       (in test file test/test.bats, line 13)
         `run project.sh | grep Welcome' failed

    1 test, 1 failure

Huh, what is going on? Why does it fail the `run` line again?

This is a common mistake that can happen when our mind parses the file differently than the bash parser.
`run` is just a function, so the pipe won't actually be forwarded into the function. Bash reads this as `(run project.sh) | grep Welcome`, 
instead of our intended `run (project.sh | grep Welcome)`.

Unfortunately, the latter is no valid bash syntax, so we have to work around it, e.g. by using a function:

.. code-block:: bash

    get_projectsh_welcome_message() {
        project.sh  2>&1 | grep Welcome
    }

    @test "Check welcome message" {
        run get_projectsh_welcome_message
        assert_output 'Welcome to our project!'
    }

Now our test passes again but having to write a function each time we want only a partial match does not accomodate our lazyness.
Isn't there an app for that? Maybe we should look at the documentation?

    Partial matching can be enabled with the --partial option (-p for short). When used, the assertion fails if the expected substring is not found in $output.

    -- the documentation for `assert_output <https://github.com/bats-core/bats-assert#partial-matching>`_

Okay, so maybe we should try that:

.. code-block:: bash

    @test "Check welcome message" {
        run project.sh
        assert_output --partial 'Welcome to our project!'
    }

Aaannnd ... the test stays green. Yay!

There are many other asserts and options but this is not the place for all of them.
Skimming the documentation of `bats-assert <https://github.com/bats-core/bats-assert>`_ will give you a good idea what you can do.
You should also have a look at the other helper libraries `here <https://github.com/bats-core>`_ like `bats-file <https://github.com/bats-core/bats-file>`_, 
to avoid reinventing the wheel.

..

    TODO
    - teardown
    - setup_file/teardown_file
    - sourcing your own .sh files
    - testing functions that return via variables