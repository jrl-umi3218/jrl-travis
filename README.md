jrl-travis
==========

This repository gathers build scripts to be used by Travis during
continuous integration.

Currently, two ways of building the software are supported:

 1. head of the development branch (`master`) is built against the
    development versions of its dependencies that are developed by us.
    If the compilation and the tests succeed, the online documentation
    is automatically uploaded so that it stays up-to-date. The code
    coverage statistics are also uploaded to the coveralls.io website
    where it is displayed.

 1. the Debian branch is using git-buildpackage and git-pbuilder to
    build Debian packages for both Debian unstable (Sid) and the
    following Ubuntu releases:
     * Ubuntu 13.10 (Saucy)
     * Ubuntu 13.04 (Raring)
     * Ubuntu 12.10 (Quantal)
     * Ubuntu 12.04 LTS (Precise)
    If the Ubuntu builds succeed, the Debian source package (`*.dsc`)
    is uploaded to the PPA associated with the project to update the
    snapshot PPA. Launchpad will build once more the project and host
    the generated Debian package files. The two supported architecture
    are `amd64` and `i386`.

The dispatch between these two modes is realized by testing whether or
not a `debian/` directory exists in the repository root-level
directory.

Development branch
------------------

### Before Install

In this case, the complex part is that we have to obtain the project
current dependencies both from APT and those which must be compiled
from source.

The following environment variables are defining the project
dependencies:

 * `APT_DEPENDENCIES` is passed directly to `apt-get install`.
 * `GIT_DEPENDENCIES` contains the name of the GitHub repositories that
   will be built from source. For instance: `jrl-umi3218/jrl-mathtools
   stack-of-tasks/dynamic-graph` is a valid chain. Please note that
   you have to list your dependencies in the correct order if some of the
   dependencies depend on other packages compiled from source which must
   be installed first.


### Build

The build step in this case is just configuring the package, building
the package, installing it and running the test suite.


### After success

The last step is uploading the documentation in case of success. To
achive this, the Travis build machine must obtain write access to the
project repository. To do so, you must put an OAuth token into the
`GH_TOKEN` environment variable. Go to your account settings,
Applications, Personal Access Token and click on `Create New
Token`. You can then use the `travis` command-line client to encrypt
the environment variable:

     $ travis encrypt GH_TOKEN=<YOUR OAUTH TOKEN> --add

This has to be run in the project root-level directory. Do _not_ copy
encrypted strings from one project to another. Each repository has its
own key a repository B cannot unencrypt a secure variable encrypted in
repository A. Redo the operation for each repository.

_Be careful:_ the `gh-pages` must never run the build in this
repository. As we are committing to this branch, using these scripts
on this branch may result in an infinite number of successive build
triggered by each documentation update.


Debian branch
-------------

### Before Install

The `before_install` script will first create a pbuilder sandbox
matching the current target distribution. The target distribution is
controlled by the `DIST` environment variable. This environment
variable is put into the build matrix so that we can build the
software for each version of Debian and Ubuntu separately.

### Build

The `build` step first generate a fake entry into the
`debian/changelog` file indicating that this build is a snapshot.

`git-buildpackage` is then called to try building the package into the
pbuilder sandbox. If it success, `git-buidpackage` is called once more
to generate a source package.

To sign the package so that it can be uploaded to a remote location
such as Launchpad, a dedicated key is used. The key public and private
data are provided by this repository. This key (5AE5CD75) is protected
by a passphrase. You have to set the key id using the `DEBSIGN_KEYID`
environment variable while the passphrase is stored in the
`GNUPG_PASSPHRASE` secured environment variable. To generate the
entry, run the following command:

    $ travis encrypt GNUPG_PASSPHRASE=<YOUR KEY PASSPHRASE> --add


### After Success

If the two previous step were successful, the Debian source package is
uploaded to launchpad. The `PPA_URI` allow to control in which PPA the
package will be uploaded. In the case of Debian unstable (Sid), the
package is not uploaded as the snapshot cannot enter the official
repository. Of course, the key used to sign the package must be
allowed to upload packages.


### Debian packaging notes

It is plausible that the content of this repository will not match the
one in the release. Add the following `debian/source/options` file if
necessary:

```sh
extend-diff-ignore = '^\.travis'
```

It will tell `dpkg-source` to ignore all the modifications in this
directory. This is safe because the content of this build is for
Travis only and should _never_ end up changing the final Debian
package in any way.


Using this repository in your project
-------------------------------------

This repository is being meant to be used as submodule. In your
project root directory, please run:

    $ git submodule add git://github.com/jrl-umi3218/jrl-travis.git .travis

You may want to fork the repository first if your project need to be
compiled in a particular way.

You can use the `travis.yml.in` file as a template for your project:

    $ cp .travis/travis.yml.in .travis

All the fields `@FOO@` must be replaced by their real value.


License
-------

The whole content of this repository is licensed under BSD. See
[COPYING](COPYING) for more information.


Authors and Credits
-------------------

 * Thomas Moulard <thomas.moulard@gmail.com>
   Maintainer

We would like to thank very much [Travis](http://www.travis.org) for
their effort and their will to support the Open Source community.
