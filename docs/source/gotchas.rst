Gotchas
=======

My test fails although I return true?
-------------------------------------

Using `return 1` to signify `true` for a success as is done often in other languages does not mesh well with Bash's 
convention of using return code 0 to signify success and everything non-zero to indicate a failure.

Please adhere to this idiom while using bats, or you will constantly work against your environment.

I cannot register a test multiple times via for loop.
-----------------------------------------------------

The usual bats tests (`@test`) are preprocessed into functions.
Wrapping them into a for loop only redeclares this function.

If you are interested in registering multiple calls to the same function, contribute your wishes to issue `#306 <https://github.com/bats-core/bats-core/issues/306>`_.

I cannot pass parameters to test or .bats files.
------------------------------------------------

Especially while using bats via shebang:

.. code-block:: bash

    #!/usr/bin/env bats

    @test "test" {
        # ...
    }

You could be tempted to pass parameters to the test invocation like `./test.bats param1 param2`.
However, bats does not support passing parameters to files or tests.
If you need such a feature, please let us know about your usecase.

As a workaround you can use environment variables to pass parameters.

Testing functions that return their results via a variable.
-----------------------------------------------------------

The `run` function executes its command in a subshell which means the changes to variables won't be available in the calling shell.

If you want to test these functions, you should call them without `run`.

`run` doesn't fail, although the same command without `run` does.
-----------------------------------------------------------------

`run` is a wrapper that always succeeds. The wrapped command's exit code is stored in `$status` and the stdout/stderr in `$output`.
If you want to fail the test, you should explicitly check `$status` or omit `run`. See also `when not to use run <writing-tests.html#when-not-to-use-run>`_.

`load` won't load my `.sh` files.
---------------------------------

`load` is intended as an internal helper function that always loads `.bash` files (by appending this suffix).
If you want to load an `.sh` file, you can simple `source` it.

I can't lint/shell-format my bats tests.
----------------------------------------

Bats uses a custom syntax for annotating tests (`@test`) that is not bash compliant.
Therefore, standard bash tooling won't be able to interact directly with `.bats` files.
Shellcheck supports bats' native syntax as of version 0.7.

Additionally, there is bash compatible syntax for tests: 

.. code-block:: bash 

    function bash_compliant_function_name_as_test_name { # @test
        # your code
    }


The output (stdout/err) from commands under `run` is not visible in failed tests.
---------------------------------------------------------------------------------

By default, `run` only stores stdout/stderr in `$output` (and `${lines[@]}`).
If you want to see this output, you either should use bat-assert's assertions or have to print `$output` before the check that fails.

My piped command does not work under run.
-----------------------------------------

Be careful with using pipes and with `run`. While your mind model of `run` might wrap the whole command behind it, bash's parser won't

.. code-block:: bash

    run echo foo | grep bar

Won't `run (echo foo | grep bar)` but will `(run echo foo) | grep bar`. If you need to incorporate pipes, you either should do

.. code-block:: bash

    run bash -c 'echo foo | grep bar'

or use a function to wrap the pipe in:

.. code-block:: bash

    fun_with_pipes() {
        echo foo | grep bar
    }

    run fun_with_pipes