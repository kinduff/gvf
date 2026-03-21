require "minitest/autorun"
require "tempfile"
require_relative "../lib/gvf/gemfile_updater"

class TestGemfileUpdater < Minitest::Test
  def update(gemfile_content, versions = {}, constraint: "minor")
    Tempfile.open("Gemfile") do |f|
      f.write(gemfile_content)
      f.flush
      GVF::GemfileUpdater.update(f.path, versions, constraint: constraint)
    end
  end

  # --- format_constraint ---

  def test_format_constraint_minor
    assert_equal "~> 7.1", GVF::GemfileUpdater.format_constraint("7.1.2", "minor")
  end

  def test_format_constraint_patch
    assert_equal "~> 7.1.2", GVF::GemfileUpdater.format_constraint("7.1.2", "patch")
  end

  def test_format_constraint_minor_two_part_version
    assert_equal "~> 7.1", GVF::GemfileUpdater.format_constraint("7.1", "minor")
  end

  # --- default (minor) constraint ---

  def test_pins_gem_with_no_version
    result, count = update(%(gem "rails"\n), {"rails" => "7.1.2"})
    assert_equal 1, count
    assert_includes result, 'gem "rails", "~> 7.1"'
  end

  def test_replaces_approximate_version
    result, count = update(%(gem "puma", "~> 5.0"\n), {"puma" => "5.6.7"})
    assert_equal 1, count
    assert_includes result, 'gem "puma", "~> 5.6"'
    refute_includes result, "5.0"
  end

  def test_replaces_range_constraints
    result, count = update(%(gem "pg", ">= 0.18", "< 2.0"\n), {"pg" => "1.5.4"})
    assert_equal 1, count
    assert_includes result, 'gem "pg", "~> 1.5"'
    refute_includes result, ">="
  end

  # --- patch constraint ---

  def test_patch_constraint
    result, count = update(%(gem "rails"\n), {"rails" => "7.1.2"}, constraint: "patch")
    assert_equal 1, count
    assert_includes result, 'gem "rails", "~> 7.1.2"'
  end

  def test_patch_constraint_replaces_existing
    result, _count = update(%(gem "puma", "~> 5.0"\n), {"puma" => "5.6.7"}, constraint: "patch")
    assert_includes result, 'gem "puma", "~> 5.6.7"'
    refute_includes result, "5.0"
  end

  # --- keyword options preserved ---

  def test_preserves_require_false
    result, count = update(%(gem "sidekiq", require: false\n), {"sidekiq" => "7.2.0"})
    assert_equal 1, count
    assert_includes result, 'gem "sidekiq", "~> 7.2", require: false'
  end

  def test_preserves_require_false_alongside_version_constraint
    result, count = update(%(gem "sidekiq", "~> 7.0", require: false\n), {"sidekiq" => "7.2.0"})
    assert_equal 1, count
    assert_includes result, 'gem "sidekiq", "~> 7.2", require: false'
  end

  def test_preserves_platform_symbol
    result, count = update(%(gem "nokogiri", platform: :ruby\n), {"nokogiri" => "1.15.0"})
    assert_equal 1, count
    assert_includes result, 'gem "nokogiri", "~> 1.15", platform: :ruby'
  end

  def test_preserves_platforms_array
    result, count = update(
      %(gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]\n),
      {"tzinfo-data" => "2.0.6"}
    )
    assert_equal 1, count
    assert_includes result, 'gem "tzinfo-data", "~> 2.0", platforms: [:mingw, :mswin, :x64_mingw, :jruby]'
  end

  def test_preserves_group_symbol
    result, count = update(%(gem "pry", group: :development\n), {"pry" => "0.14.2"})
    assert_equal 1, count
    assert_includes result, 'gem "pry", "~> 0.14", group: :development'
  end

  def test_preserves_group_array
    result, count = update(%(gem "pry", group: [:development, :test]\n), {"pry" => "0.14.2"})
    assert_equal 1, count
    assert_includes result, 'gem "pry", "~> 0.14", group: [:development, :test]'
  end

  def test_preserves_platform_array_alongside_version_constraint
    result, count = update(
      %(gem "tzinfo-data", ">= 1.0", platforms: [:mingw, :mswin]\n),
      {"tzinfo-data" => "2.0.6"}
    )
    assert_equal 1, count
    assert_includes result, 'gem "tzinfo-data", "~> 2.0", platforms: [:mingw, :mswin]'
    refute_includes result, ">= 1.0"
  end

  def test_preserves_multiple_keyword_options
    result, count = update(
      %(gem "devise", "~> 4.0", require: false, group: :development\n),
      {"devise" => "4.9.3"}
    )
    assert_equal 1, count
    assert_includes result, '"~> 4.9"'
    assert_includes result, "require: false"
    assert_includes result, "group: :development"
    refute_includes result, "4.0"
  end

  # --- misc ---

  def test_leaves_gem_unchanged_when_not_in_lockfile
    gemfile = %(gem "unknown_gem"\n)
    result, count = update(gemfile, {})
    assert_equal 0, count
    assert_equal gemfile, result
  end

  def test_handles_single_quoted_gem_names
    result, count = update(%(gem 'rails', '~> 7.0'\n), {"rails" => "7.1.2"})
    assert_equal 1, count
    assert_includes result, 'gem \'rails\', "~> 7.1"'
  end

  def test_handles_indented_gems
    gemfile = "group :production do\n  gem \"puma\", \"~> 5.0\"\nend\n"
    result, count = update(gemfile, {"puma" => "5.6.7"})
    assert_equal 1, count
    assert_includes result, 'gem "puma", "~> 5.6"'
  end

  def test_updates_multiple_gems
    gemfile = %(gem "rails"\ngem "puma", "~> 5.0"\n)
    result, count = update(gemfile, {"rails" => "7.1.2", "puma" => "5.6.7"})
    assert_equal 2, count
    assert_includes result, 'gem "rails", "~> 7.1"'
    assert_includes result, 'gem "puma", "~> 5.6"'
  end

  def test_preserves_comments
    gemfile = "# Web framework\ngem \"rails\"\n"
    result, _count = update(gemfile, {"rails" => "7.1.2"})
    assert_includes result, "# Web framework"
  end

  def test_does_not_alter_inline_comments
    result, _count = update(%(gem "rails" # main framework\n), {"rails" => "7.1.2"})
    assert_includes result, "# main framework"
  end
end
