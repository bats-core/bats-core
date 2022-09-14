Warnings
========

Starting with version 1.7.0 Bats shows warnings about issues it found during the test run.
They are printed on stderr after all other output:

.. code-block:: bash

     BW01.bats
     ✓ Trigger BW01
    
     1 test, 0 failures
    
    
     The following warnings were encountered during tests:
     BW01: `run`'s command `=0 actually-intended-command with some args` exited with code 127, indicating 'Command not found'. Use run's return code checks, e.g. `run -127`, to fix this message.
           (from function `run' in file lib/bats-core/test_functions.bash, line 299,
            in test file test/fixtures/warnings/BW01.bats, line 3)

A warning will not make a successful run fail but should be investigated and taken seriously, since it hints at a possible error.

Currently, Bats emits the following warnings:

.. toctree::

    BW01
    BW02
    BW03