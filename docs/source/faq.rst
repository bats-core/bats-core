FAQ
===

How do I set the working directory?
-----------------------------------

The working directory is simply the directory where you started when executing bats.
If you want to enforce a specific directory, you can use `cd` in the `setup_file`/`setup` functions.
However, be aware that code outside any function will run before any of these setup functions and my interfere with bats' internals.


How do I see the output of the command under `run` when a test fails?
---------------------------------------------------------------------

`run` captures stdout and stderr of its command and stores it in the `$output` and `${lines[@]}` variables.
If you want to see this output, you need to print it yourself, or use functions like `assert_output` that will reproduce it on failure.

Can I use `--filter` to exclude files/tests?
--------------------------------------------

No, not directly. `--filter` uses a regex to match against test names. So you could try to invert the regex.
The filename won't be part of the strings that are tested, so you cannot filter against files.

How can I exclude a single test from a test run?
------------------------------------------------

If you want to exclude only few tests from a run, you can either `skip` them:

.. code-block:: bash

    @test "Testname" {
        # yadayada
    }

becomes 

.. code-block:: bash

    @test "Testname" {
        skip 'Optional skip message'
        # yadayada
    }

or comment them out, e.g.:

.. code-block:: bash

    @test "Testname" {

becomes 

.. code-block:: bash

    disabled() { # @test "Testname" {

For multiple tests or all tests of a file, this becomes tedious, so read on.

How can I exclude all tests of a file from a test run?
--------------------------------------------------------

If you run your test suite by naming individual files like:

.. code-block:: bash

    $ bats test/a.bats test/b.bats ...

you can simply omit your file. When running a folder like


.. code-block:: bash

    $ bats test/

you can prevent test files from being picked up by changing their extension to something other than `.bats`.

It is also possible to `skip` in `setup_file`/`setup` which will skip all tests in the file.

How can I include my own `.sh` files for testing?
-------------------------------------------------

You can simply `source <your>.sh` files. However, be aware that `source`ing files with errors outside of any function (or inside `setup_file`) will trip up bats
and lead to hard to diagnose errors.
Therefore, it is safest to only `source` inside `setup` or the test functions themselves.

How can I debug a failing test?
-------------------------------

Short of using a bash debugger you should make sure to use appropriate asserts for your task instead of raw bash comparisons, e.g.:

.. code-block:: bash

    @test test {
        run echo test failed
        assert_output "test"
        # instead of 
        [ "$output" = "test" ]
    }

Because the former will print the output when the test fails while the latter won't.
Similarly, you should use `assert_success`/`assert_failure` instead of `[ "$status" -eq 0 ]` for return code checks.

Is there a mechanism to add file/test specific functionality to a common setup function?
----------------------------------------------------------------------------------------

Often the setup consists of parts that are common between different files of a test suite and parts that are specific to each file.
There is no suite wide setup functionality yet, so you should extract these common setup steps into their own file (e.g. `common-test-setup.sh`) and function (e.g. `commonSetup() {}`),
which can be `source`d or `load`ed and call it in `setup_file` or `setup`.

How can I use helper libraries like bats-assert?
------------------------------------------------

This is a short reproduction of https://github.com/ztombol/bats-docs.

At first, you should make sure the library is installed. This is usually done in the `test_helper/` folders alongside the `.bats` files, giving you a filesystem layout like this:

.. code-block::

    test/
        test.bats
        test_helper/
            bats-support/
            bats-assert/

Next, you should load those helper libraries:

.. code-block:: bash

    setup() {
        load 'test_helper/bats-support/load' # this is required by bats-assert!
        load 'test_helper/bats-assert/load'
    }    

Now, you should be able to use the functions from these helpers inside your tests, e.g.:

.. code-block:: bash

    @test "test" {
        run echo test
        assert_output "test"
    }

Note that you obviously need to load the library before using it.
If you need the library inside `setup_file` or `teardown_file` you need to load it in `setup_file`.

How to set a test timeout in bats?
----------------------------------

Unfortunately, this is not possible yet. Please contribute to issue `#396 <https://github.com/bats-core/bats-core/issues/396>`_ for further progress.

How can I lint/shell-format my bats tests?
------------------------------------------

Due to their custom syntax (`@test`), `.bats` files are not standard bash. This prevents most tools from working with bats.
However, there is an alternative syntax `function_name { # @test` to declare tests in a bash compliant manner.

- shellcheck support since version 0.7
- shfmt support since version 3.2.0 (using `-ln bats`)


How can I check if a test failed/succeeded during teardown?
-----------------------------------------------------------

You can check `BATS_TEST_COMPLETED` which will be set to 1 if the test was successful or empty if it was not.
There is also `BATS_TEST_SKIPPED` which will be non-empty (contains the skip message or -1) when `skip` was called.

How can I setup/cleanup before/after all tests?
-----------------------------------------------

Currently, this is not supported. Please contribute your usecase to issue `#39 <https://github.com/bats-core/bats-core/issues/39>`_.