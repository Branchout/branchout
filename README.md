# branchout

A tool for managing organisations with many repositories in a structured way

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

### MacOS

```
brew tap Branchout/homebrew-branchout
brew install branchout
```

### Otherwise

Download [branchout 1.4](https://github.com/Branchout/branchout/blob/v1.4/branchout) and add it to your path


### Initialise a project

You need repository to act as the root, 
* create it or clone it
* then ```run branchout init```

The default branchout name is the name of the root project

You can now add projects
```branchout add <project-name>```

They will show as not cloned until you ```branchout pull```

## Grokking the code and contributing

### Running the tests

The tests are written in bats https://github.com/sstephenson/bats

```make test```

### PRs Welcome

Feel free to send some PRs in, with tests
