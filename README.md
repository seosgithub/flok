![flok: The mobile application framework](https://raw.githubusercontent.com/sotownsend/flok/master/logo.png)

[![Gem Version](https://badge.fury.io/rb/iarrogant.svg)](http://badge.fury.io/rb/flok)
[![Build Status](https://travis-ci.org/sotownsend/flok.svg)](https://travis-ci.org/sotownsend/flok)
[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/sotownsend/flok/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/sotownsend/flok/blob/master/LICENSE)

# What is this?

A work in progress

# Flok Modules
A concept borrowed from [Rails engines](http://guides.rubyonrails.org/engines.html), Flok modules both serve as your project files, all library modules, and gemified instances.  That is, a project you create is automatically modular and can be imported in another flok module/project.

# Compilation
Flok does not rely on ruby for the final produced `application.js` file.  The output file is pure javascript and written in javascript (not transcoded).  Ruby only serves as a compilation assistant.  

# Task
The task is the base unit in flok, similar to a rack module except that rack is a stack and flok is a party.  Based on concepts borrowed from XNU®, FreeBSD®, and GNU HURD®; tasks are combined in flok to produce behavior by many tasks inter-cooperating.  Efficiency has been provided through virtualizing the task communication so that no message passing takes place inside flok and all modules are combined into an efficient monolithic module.

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
