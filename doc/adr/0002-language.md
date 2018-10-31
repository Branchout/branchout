# 2. language

Date: 2018-10-31

## Status

Accepted

Testing [3. testing](0003-testing.md)

## Context

A language should be universal, simple and easily testable

Options
* Shell
* Go
* Java
* JavaScript

There should be very few dependencies

## Decision

Shell

* No dependencies
* Installed pretty much everywhere developers are

## Consequences

Testing will be a learning curve - bats
Ensuring portability - shellcheck
Async is a little awkward - xargs
