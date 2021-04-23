# branchout

A tool for managing organisations with many repositories in a structured way, commonly called a Projected Monorepo

* consistent naming
* fast updates
* single command line view

## Badges

[![Build Status](https://travis-ci.com/Branchout/branchout.svg?branch=master)](https://travis-ci.com/Branchout/branchout)

## Structure

Project repositories are named group-project-name

When the projects are branched out locally they look like this

group one
- project one
- project two

group two
- project three
- project four

The reason is simple, it gives a consistent structure for developers
* if you name a project badly it ends up in a weird place, and is more likely to be fixed
* when looking for something you have a pattern to follow to find it
* things are grouped so its easy to start in one place especially for new people, which reduces congnitive load

## Getting Started

### Brew

Brew is a handy tool for consistent tooling, it can be run on OSX and Linux

```
brew tap Branchout/homebrew-branchout
brew install branchout
```

### Initialise an existing or new organisation

To start with an existing project just init it from the git url

```
branchout init https://github.com/Branchout/branchout-reactor.git [optionalDirName]
cd ~/project/branchout-reactor
branchout status
branchout pull
```

This will create the Branchoutfile and Branchoutprojects if needed, for example if the repo is new/empty and you're setting it up for the first time.

The default branchout name is the name of the root project, but can be overridden.

You can now add projects

```
branchout add <project-name>
```

They will show as not cloned until you `branchout pull`

If you want to clone when you add 

```
branchout clone <project-name>
```

### Need to trust a certificate or ca bundle

If you have a corporate CA bundle that you need to trust just add it at `<metarepo>/.branchout/cacerts`

branchout-yarn will configure the environment so that yarn can trust certificates in or signed by certificates in cacarts

### Common config in Branchoutfile

#### Repo name prefixes

If in your git structure your repos are all commonly prefixed with the same thing, and you'd like that to be ignored by Branchout as a prefix, then add:

```
BRANCHOUT_PREFIX=prefix-without-trailing-hyphen
```

to the Branchoutfile and you'll get whatever the next hyphen-separated part is used as the group for directory layout.

#### Branchout name override

In case of your branchout repository having a long name that you don't want as part of the two branchout paths, you can override by adding:

```
BRANCHOUT_NAME=shorter-name
```

to the Branchoutfile and ideally use the same value as the optionalDirName during branchout init.


## Grokking the code and contributing


### Tooling

Installing the required tools

```
brew install git bats-core shellcheck
```

### Running the tests

The tests are written in bats https://github.com/bats-core/bats-core

Note, the `sstephenson/bats` repository is unmaintained, bats-core is what you want.

```
make test
```

### PRs Welcome

Feel free to send some PRs in, with tests
