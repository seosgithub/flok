![flok: The eventful application framework](https://raw.githubusercontent.com/sotownsend/flok/master/logo.png)

[![Gem Version](https://badge.fury.io/rb/iarrogant.svg)](http://badge.fury.io/rb/flok)
[![Build Status](https://travis-ci.org/sotownsend/flok.svg)](https://travis-ci.org/sotownsend/flok)
[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/sotownsend/flok/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/sotownsend/flok/blob/master/LICENSE)

# What is this?

A work in progress

# Architecture
Flok's architecture is a non-pre-emptive (realtime) event-driven tickless monolithic meta-kernel divided into several parts.
```
#(a) <Platform specific drivers for handling generic/custom interrupts and generic/custom IO>
#---------^|------------------------------------
#---------||------------------------------------
#=========|v====================================          <--------------------- Abstraction barrier
#(b) <Standard driver interface> <Custom driver interfaces>                         
#---------^|------------------------------------
#---------||------------------------------------
#---------|v------------------------------------
#(c) <Generic kernel systems (ui, pipes, etc)> <Your Kernel 'tasks'>
```

* (a) - Drivers are written in any languages and must implement (b) the standard driver interface.
* (b) - All driver communication must pass directly through this layer
* (c) - This layer handles all generic activity like setting up pipes between tasks, etc.

# Project layout
 * app/ - All actual pieces of the kernel code sit here.
   * app/drivers - Parts of (a) and (b)
     * app/drivers/interfaces - Generic interfaces that are suggested to be implemented.
     * app/drivers/$PLATFORM - Platform specific way to implement the interface. See *platform drivers* for information.

# Platform Drivers
Each platform has it's own set of drivers. You do not have to implement *all* the drivers on a platform and you may create your own drivers to suite your own needs.  Platform drivers sit in `app/drivers/$PLATFORM` and *must* contain at least the following files.

 * app/drivers/$PLATFORM/Rakefile - You must at least have the tasks `test` and `build`.  Note that if you're writing custom drivers in your own project folder, this does not apply to you. Also, you must observe the rules in the platform's README.md
 * app/drivers/$PLATFORM/README.md - A description of this platform driver, how to extend it with custom drivers, and how it is deployed correctly.

During compliation all platform drivers must respect enviorenmental variables. For example, for $BUILD_PATH you can read this in your Rakefile via `ENV['BUILD_PATH']`.
  * $BUILD_PATH    - The absolute file path (not including the filename) of where to put build files.
  * $BUILD_JS_NAME - The filename of the javascript file to output to the $BUILD_PATH.
Your build path may contain additional files as you see fit.  These files will be available in the user's project in `./products/$PLATFORM/xxxxx` with the exception of the javascript outputfile which will be merged at the beginning of the complete source.

# Compilation
Flok does not rely on ruby for the final produced `application.js` file.  The output file is pure javascript and written in javascript (not transcoded).  Ruby only serves as a compilation assistant.

# Task
The task is the base unit in flok, similar to a rack module except that rack is a stack and flok is a party.  Based on concepts borrowed from XNU®, FreeBSD®, and GNU HURD®; tasks are combined in flok to produce behavior by many tasks inter-cooperating.  Efficiency has been provided through virtualizing the task communication so that no message passing takes place inside flok and all modules are combined into an efficient monolithic module.

### Task Facilities
Tasks are able to
 - send and receive events from a global or internal source.
 - set interval and timeout timers.
 - store temporary data in it's own heap '$__'

### Default modules
This flok project contains the 'micro-task-kernel', the 'ui', and the 'operations' modules.

## Requirements

- Mac OS X 10.9+ (Untested)
- Ruby 2.1 or Higher

## Communication

- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

Run `sudo gem install flok`

---

## FAQ

### When should I use flok?

Todo

### What's Fittr?

Fittr is a SaaS company that focuses on providing personalized workouts and health information to individuals and corporations through phenomenal interfaces and algorithmic data-collection and processing.

* * *

### Creator

- [Seo Townsend](http://github.com/sotownsend) ([@seotownsend](https://twitter.com/seotownsend))

## License

flok is released under the MIT license. See LICENSE for details.
