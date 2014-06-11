# Palimpsest ChangeLog

## HEAD

- Added persistent files.
- Use `palimpsest.yml` not `palimpsest_config.yml`
- Keys in `palimpsest.yml` can be given as strings or symbols.
- New `Repo` class handles caching and extracting repos.
- New `Utils` module handles copy operations.
- Refactored to use `Repo` and `Utils`.

## 0.2.0

- Added Environment#remove_excludes.
- Environment#config can be overridden.

## 0.1.0

- Lots of documentation and improvements.
- New classes: Site, Component, External.
- Environment support for new classes.

## 0.0.1

Initial release.

- Populating working environment from git repo or directory.
- Flexible asset pipeline with sprockets.
  * `Palimpsest::Assets` class can be used standalone.
  * Environment automatically compiles assets referenced in source files.
