# Palimpsest

by Evan Boyd Sosenko.

_No web framework, no problem: Palimpsest gives any custom or legacy project a modern workflow and toolset._


[![Gem Version](https://img.shields.io/gem/v/palimpsest.svg)](https://rubygems.org/gems/palimpsest)
[![MIT License](https://img.shields.io/github/license/razor-x/palimpsest.svg)](./LICENSE.txt)
[![Dependency Status](https://img.shields.io/gemnasium/razor-x/palimpsest.svg)](https://gemnasium.com/razor-x/palimpsest)
[![Build Status](https://img.shields.io/travis/razor-x/palimpsest.svg)](https://travis-ci.org/razor-x/palimpsest)
[![Coverage Status](https://img.shields.io/codecov/c/github/razor-x/palimpsest.svg)](https://codecov.io/github/razor-x/palimpsest)
[![Code Climate](https://img.shields.io/codeclimate/github/razor-x/palimpsest.svg)](https://codeclimate.com/github/razor-x/palimpsest)

## Description

Built flexible, simple, and customizable.
Palimpsest runs on top of any project and acts as a post processor for your code.
Features a [Sprockets](https://github.com/sstephenson/sprockets) asset pipeline.

### Usage

**Palimpsest should not be considered stable until version 1.0.0 is released.**

This README will focus on examples of how to get your project working with Palimpsest through `Palimpsest::Environment`.

Palimpsest's classes are independently useful outside of `Palimpsest::Environment`, and each is
[well documented for that purpose](http://rubydoc.info/github/razor-x/palimpsest/frames).

The first step is always

```ruby
require 'palimpsest'
```

#### Additional requirements

Some optional Palimpsest features depend on gems not required by Palimpsest itself.
Include these in your project's Gemfile if you plan to use them.

For example, to use the `image_compression` option, add to your Gemfile

```ruby
gem 'sprockets-image_compressor'
```

and to your project

```ruby
require 'sprockets-image_compressor'
```

or if you set `js_compressor: uglifier` you must add to your Gemfile

```ruby
gem 'uglifier'
```

and to your project

```ruby
require 'uglifier'
```

Similarly you must include gems for any sprockets engines you want to use.

### Creating and populating an environment

Create an environment with

```ruby
environment = Palimpsest::Environment.new
```
For most operations you will need to specify a `site` which can be any object which
responds to the methods `Palimpsest::Environment` assumes exists in some of its own methods.
A model class `Palimpsest::Site` is included which implements all possible expected methods.
Finally, the examples below assume default options for each class, but these can be overridden with `#options`.

```ruby
site = Palimpsest::Site.new
site.name = 'my_app'
environment.site = site
```

To populate the environment from a git repository,

```ruby
site.repository = '/path/to/project/repo'
environment.reference = 'my_feature' # if you want something other then 'master'
environment.populate
```
or to populate from a directory,

```ruby
site.source = '/path/to/project/source'
environment.populate from :source
```
Either way you will get a copy of your site in a new temporary working directory,

```ruby
environment.directory #=> '/tmp/palimpsest_my_app_120140605-26021-d7vlnv'
```

#### Working with the environment

If you project contains a file `palimpsest.yml`,
then its configuration is available with `environment.config`.

[**An example `palimpsest.yml`.**](http://rubydoc.info/github/razor-x/palimpsest/Palimpsest/Environment)

The configuration file tells Palimpsest how to behave when you ask it to manipulate the environment
and acts as a shortcut to working with the other Palimpsest classes directly.

If you made it this far, you can make Palimpsest do all sorts of magic to your code in the working directory.

For example, to search through you code for tags referencing assets,
process and save those assets with sprockets,
and replace the tags with references to the processed assets,

```ruby
environment.compile_assets
```
Check the [`Palimpsest::Environment` documentation](http://rubydoc.info/github/razor-x/palimpsest/Palimpsest/Environment)
for all available magic, and freely extend the class to add new magic applicable to your project.

#### Finishing with the environment

You can copy the current state of the environment to another directory with `Palimpsest::Environment#copy`.
By default, this will use `site.path` for the destination, or you can specify with

```ruby
environment.copy destination: '/path/to/out/dir'
```

To delete the working directory, use

```ruby
environment.cleanup
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'palimpsest'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install palimpsest
```

## Documentation

The primary documentation for Palimpsest is this README and the YARD source documentation.

YARD documentation for all gem versions is hosted on the
[Palimpsest gem page](https://rubygems.org/gems/palimpsest).
Also checkout
[Omniref's interactive documentation](https://www.omniref.com/ruby/gems/palimpsest).

## Development and Testing

### Source Code

The [Palimpsest source](https://github.com/razor-x/palimpsest)
is hosted on GitHub.
To clone the project run

```bash
$ git clone https://github.com/razor-x/palimpsest.git
```

### Rake

Run `rake -T` to see all Rake tasks.

```
rake all                   # Run all tasks
rake build                 # Build palimpsest-0.2.0.gem into the pkg directory
rake bump:current[tag]     # Show current gem version
rake bump:major[tag]       # Bump major part of gem version
rake bump:minor[tag]       # Bump minor part of gem version
rake bump:patch[tag]       # Bump patch part of gem version
rake bump:pre[tag]         # Bump pre part of gem version
rake bump:set              # Sets the version number using the VERSION environment variable
rake install               # Build and install palimpsest-0.2.0.gem into system gems
rake install:local         # Build and install palimpsest-0.2.0.gem into system gems without network access
rake release               # Create tag v0.2.0 and build and push palimpsest-0.2.0.gem to Rubygems
rake rubocop               # Run RuboCop
rake rubocop:auto_correct  # Auto-correct RuboCop offenses
rake spec                  # Run RSpec code examples
rake yard                  # Generate YARD Documentation
```

### Guard

Guard tasks have been separated into the following groups:

- `doc`
- `lint`
- `unit`

By default, Guard will generate documentation, lint, and run unit tests.

## Contributing

Please submit and comment on bug reports and feature requests.

To submit a patch:

1. Fork it (https://github.com/razor-x/palimpsest/fork).
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Make changes. Write and run tests.
4. Commit your changes (`git commit -am 'Add some feature'`).
5. Push to the branch (`git push origin my-new-feature`).
6. Create a new Pull Request.

## License

Palimpsest is licensed under the MIT license.

## Warranty

This software is provided "as is" and without any express or
implied warranties, including, without limitation, the implied
warranties of merchantibility and fitness for a particular
purpose.
