
Installation
============

Supported Bash versions
^^^^^^^^^^^^^^^^^^^^^^^

The following is a list of Bash versions that are currently supported by Bats.
This list is composed of platforms that Bats has been tested on and is known to
work on without issues.


* Bash versions:


  * 3.2.57(1) (macOS's highest bundled version)
  * 4.0, 4.1, 4.2, 4.3, 4.4
  * 5.0, 5.1

* Tested Operating systems:

 * Linux: Alpine (CI), Alma 8 (CI), Arch Linux (manual), Ubuntu 20.04/22.04 (CI)
 * FreeBSD: 11 (CI)
 * macOS: 11 (CI), 12 (CI)
 * Windows: Server 2019 (CI), 10 (manual)
  * Git for Windows Bash (MSYS2 based)
  * Windows Subsystem for Linux
  * MSYS2
  * Cygwin

Linux: Distribition Package Manager
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Following Linux distributions provide Bats via their package manager:

* Arch Linux: `community/bash-bats <https://archlinux.org/packages/community/any/bash-bats/>`_
* Alpine Linux: `bats <https://pkgs.alpinelinux.org/package/edge/main/x86/bats>`_
* Debian Linux: `shells/bats <https://packages.debian.org/search?keywords=bats>`_
* Fedora Linux: `rpms/bats <https://src.fedoraproject.org/rpms/bats>`_
* Gentoo Linux `dev-util/bats <https://packages.gentoo.org/packages/dev-util/bats>`_
* OpenSUSE Linux: `bats <https://software.opensuse.org/package/bats>`_
* Ubuntu Linux `shells/bats <https://packages.ubuntu.com/search?keywords=bats>`_

**Note**: Bats versions pre 1.0 are from sstephenson's original project.
Consider using one of the other installation methods below to get the latest Bats release.
The test matrix above only applies to the latest Bats version.

If your favorite distribution is not listed above,
you can try one of the following package managers or install from source.

MacOS: Homebrew
^^^^^^^^^^^^^^^

On macOS, you can install `Homebrew <https://brew.sh/>`_ if you haven't already,
then run:

.. code-block:: bash

   $ brew install bats-core

Any OS: npm
^^^^^^^^^^^

You can install the `Bats npm package <https://www.npmjs.com/package/bats>`_ via:

.. code-block::

   # To install globally:
   $ npm install -g bats

   # To install into your project and save it as one of the "devDependencies" in
   # your package.json:
   $ npm install --save-dev bats

Any OS: Installing Bats from source
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Check out a copy of the Bats repository. Then, either add the Bats ``bin``
directory to your ``$PATH``\ , or run the provided ``install.sh`` command with the
location to the prefix in which you want to install Bats. For example, to
install Bats into ``/usr/local``\ ,

.. code-block::

   $ git clone https://github.com/bats-core/bats-core.git
   $ cd bats-core
   $ ./install.sh /usr/local


**Note:** You may need to run ``install.sh`` with ``sudo`` if you do not have
permission to write to the installation prefix.

Windows: Installing Bats from source via Git Bash
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Check out a copy of the Bats repository and install it to ``$HOME``. This
will place the ``bats`` executable in ``$HOME/bin``\ , which should already be
in ``$PATH``.

.. code-block::

   $ git clone https://github.com/bats-core/bats-core.git
   $ cd bats-core
   $ ./install.sh $HOME


Running Bats in Docker
^^^^^^^^^^^^^^^^^^^^^^

There is an official image on the Docker Hub:

.. code-block::

   $ docker run -it bats/bats:latest --version


Building a Docker image
~~~~~~~~~~~~~~~~~~~~~~~

Check out a copy of the Bats repository, then build a container image:

.. code-block::

   $ git clone https://github.com/bats-core/bats-core.git
   $ cd bats-core
   $ docker build --tag bats/bats:latest .


This creates a local Docker image called ``bats/bats:latest`` based on `Alpine
Linux <https://github.com/gliderlabs/docker-alpine/blob/master/docs/usage.md>`_
(to push to private registries, tag it with another organisation, e.g.
``my-org/bats:latest``\ ).

To run Bats' internal test suite (which is in the container image at
``/opt/bats/test``\ ):

.. code-block::

   $ docker run -it bats/bats:latest /opt/bats/test


To run a test suite from a directory called ``test`` in the current directory of
your local machine, mount in a volume and direct Bats to its path inside the
container:

.. code-block::

   $ docker run -it -v "${PWD}:/code" bats/bats:latest test


..

   ``/code`` is the working directory of the Docker image. "${PWD}/test" is the
   location of the test directory on the local machine.


This is a minimal Docker image. If more tools are required this can be used as a
base image in a Dockerfile using ``FROM <Docker image>``.  In the future there may
be images based on Debian, and/or with more tools installed (\ ``curl`` and ``openssl``\ ,
for example). If you require a specific configuration please search and +1 an
issue or `raise a new issue <https://github.com/bats-core/bats-core/issues>`_.

Further usage examples are in
`the wiki <https://github.com/bats-core/bats-core/wiki/Docker-Usage-Examples>`_.
