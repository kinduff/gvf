# gvf - gemfile version fixer

Reads your `Gemfile.lock` and updates the versions in your `Gemfile` to match.

## Install

```
gem install gvf
```

## Usage

```
gvf [options] [Gemfile [Gemfile.lock]]
```

Options:

```
-c, --version-constraint   minor (default) or patch
-v, --version              print version
-h, --help                 show help
```

## Example

You go from this:

```ruby
source "https://gem.coop"

gem "rails", "~> 8.1.2"

gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
```

To this:

```ruby
source "https://gem.coop"

gem "rails", "~> 8.1"

gem "propshaft", "~> 1.3"
gem "pg", "~> 1.6"
gem "puma", "~> 7.2"
gem "importmap-rails", "~> 2.2"
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
```
