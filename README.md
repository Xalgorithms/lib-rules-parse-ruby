[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Build Status](https://travis-ci.org/Xalgorithms/xa-rules.svg?branch=master)](https://travis-ci.org/Xalgorithms/xa-rules)

# About

[Rule execution in
Interlibr](https://github.com/Xalgorithms/general-documentation/blob/master/docs/xalgo.md)
is made up of three stages: compilation,
[execution](https://github.com/Xalgorithms/rules-interpreter) and
revision. This library implements the compilation stage. Its role is
to read source rules in Xalgo format and compile this to an *internal
JSON format* that is (eventually) stored in MongoDB. This library
**merely implements the parsing** of the rules using a PEG parser. It
is designed to be integrated with a [larger
service](https://github.com/Xalgorithms/xadf-revisions) that stores
and manages rule packages.

# Status

This library parses the complete specification for
[Xalgo](https://github.com/Xalgorithms/general-documentation/blob/master/docs/xalgo.md)
and can therefore be seen as a *completed work*. Eventually, [for
project harmony
purposes](https://github.com/Xalgorithms/general-documentation/blob/master/docs/why-scala.md)
this library will be ported to Scala and this implementation retired.

# Getting started

### Smoke Test

After cloning the repository you will need a working Ruby
environment. We recommend using
[rbenv](https://github.com/rbenv/rbenv) and
[ruby-build](https://github.com/rbenv/ruby-build). When you have those
packages installed, you should install the version of Ruby required by
this library (currently: **2.4.2**) and the bundler gem:

```
$ rbenv install 2.4.2
$ gem install bundler

```

The library is self-bootstrapping, so you can simply use bundler to
install all of the dependancies and run the unit tests to verify your
installation:

```
$ bundle install
$ bundle exec rspec
```

Both of these commands should complete successfully **if the build
status badge above is indicating that the latest build is
successful**. If yur encounter an error, please log an issue in this
project (include the output of the failure).

### Compiling Rules to JSON

This project includes a command-line tool to create *internal JSON*
that represents the *compiled* rule. To run this tool, use:

```
$ bundle exec ruby cli.rb <path to .rule> <path to output .rule.json>
```

For example:

```
$ bundle exec ruby cli.rb test-runs/map/map.rule test-runs/map/map.rule.json
```

This compiles a test rule from the [interpreter
project](https://github.com/Xalgorithms/rules-interpreter) in order
use the JSON to validate the interpreter. If you encounter and errors
while running a compilation, log an issue (with the error output) in
this project.
