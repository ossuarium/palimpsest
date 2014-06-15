# Palimpsest

by Evan Boyd Sosenko.

_No web framework, no problem: Palimpsest gives any custom or legacy project a modern workflow and toolset._

Built flexible, simple, and customizable.
Palimpsest runs on top of any project and acts as a post processor for your code.
Features a [Sprockets](https://github.com/sstephenson/sprockets) asset pipeline
and easy integration with [Kit](https://github.com/razor-x/kit).

[![Gem Version](http://img.shields.io/gem/v/palimpsest.svg?style=flat)](https://rubygems.org/gems/palimpsest)
[![MIT License](http://img.shields.io/badge/license-MIT-red.svg?style=flat)](./LICENSE.txt)
[![Dependency Status](http://img.shields.io/gemnasium/razor-x/palimpsest.svg?style=flat)](https://gemnasium.com/razor-x/palimpsest)
[![Build Status](http://img.shields.io/travis/razor-x/palimpsest.svg?style=flat)](https://travis-ci.org/razor-x/palimpsest)
[![Coverage Status](http://img.shields.io/coveralls/razor-x/palimpsest.svg?style=flat)](https://coveralls.io/r/razor-x/palimpsest)
[![Code Climate](http://img.shields.io/codeclimate/github/razor-x/palimpsest.svg?style=flat)](https://codeclimate.com/github/razor-x/palimpsest)

## Installation

Add this line to your application's Gemfile:

````ruby
gem 'palimpsest'
````

And then execute:

````bash
$ bundle
````

Or install it yourself as:

````bash
$ gem install palimpsest
````

## Documentation

The primary documentation for Palimpsest is this README and the YARD source documentation.

YARD documentation for all gem versions is hosted on the
[Palimpsest gem page](https://rubygems.org/gems/palimpsest).
Documentation for the latest commits is hosted on
[the RubyDoc.info project page](http://rubydoc.info/github/razor-x/palimpsest/frames).

## Usage

**Palimpsest should not be considered stable until version 1.0.0 is released.**

This README will focus on examples of how to get your project working with Palimpsest through `Palimpsest::Environment`.

Palimpsest's classes are independently useful outside of `Palimpsest::Environment`, and each is
[well documented for that purpose](http://rubydoc.info/github/razor-x/palimpsest/frames).

The first step is always

````ruby
require 'palimpsest'
````
### Additional requirements

Some optional Palimpsest features depend on gems not required by Palimpsest itself.
Include these in your project's Gemfile if you plan to use them.

For example, to use the `image_compression` option, add to your Gemfile

````ruby
gem 'sprockets-image_compressor'
````

and to your project

````ruby
require 'sprockets-image_compressor'
````

or if you set `js_compressor: uglifier` you must add to your Gemfile

````ruby
gem 'uglifier'
````

and to your project

````ruby
require 'uglifier'
````

Similarly you must include gems for any sprockets engines you want to use.

### Creating and populating an environment

Create an environment with

````ruby
environment = Palimpsest::Environment.new
````
For most operations you will need to specify a `site` which can be any object which
responds to the methods `Palimpsest::Environment` assumes exists in some of its own methods.
A model class `Palimpsest::Site` is included which implements all possible expected methods.
Finally, the examples below assume default options for each class, but these can be overridden with `#options`.

````ruby
site = Palimpsest::Site.new
site.name = 'my_app'
environment.site = site
````

To populate the environment from a git repo,

````ruby
site.repo = Grit::Repo.new '/path/to/project/repo'
environment.treeish = 'my_feature' # if you want something other then 'master'
environment.populate
````
or to populate from a directory,

````ruby
site.source = '/path/to/project/source'
environment.populate from :source
````
Either way you will get a copy of your site in a new temporary working directory,

````ruby
environment.directory #=> '/tmp/palimpsest_my_app_120140605-26021-d7vlnv'
````

### Working with the environment

If you project contains a file `palimpsest.yml`,
then its configuration is available with `environment.config`.

[**An example `palimpsest.yml`.**](http://rubydoc.info/github/razor-x/palimpsest/Palimpsest/Environment)

The configuration file tells Palimpsest how to behave when you ask it to manipulate the environment
and acts as a shortcut to working with the other Palimpsest classes directly.

If you made it this far, you can make Palimpsest do all sorts of magic to your code in the working directory.

For example, to search through you code for tags referencing assets,
process and save those assets with sprockets,
and replace the tags with references to the processed assets,

````ruby
environment.compile_assets
````
Check the [`Palimpsest::Environment` documentation](http://rubydoc.info/github/razor-x/palimpsest/Palimpsest/Environment)
for all available magic, and freely extend the class to add new magic applicable to your project.

### Finishing with the environment

You can copy the current state of the environment to another directory with `Palimpsest::Environment#copy`.
By default, this will use `site.path` for the destination, or you can specify with

````ruby
environment.copy destination: '/path/to/out/dir'
````

To delete the working directory, use

````ruby
environment.cleanup
````

## Source Repository

The [Palimpsest source](https://github.com/razor-x/palimpsest)
is hosted on GitHub.
To clone the project run

````bash
$ git clone https://github.com/razor-x/palimpsest.git
````

## Contributing

Please submit and comment on bug reports and feature requests.

To submit a patch:

1. Fork it (https://github.com/razor-x/palimpsest/fork).
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create a new Pull Request.

## License

Palimpsest is licensed under the MIT license.

## Warranty

This software is provided "as is" and without any express or
implied warranties, including, without limitation, the implied
warranties of merchantibility and fitness for a particular
purpose.
