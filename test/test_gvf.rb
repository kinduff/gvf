require "minitest/autorun"
require "tempfile"
require "tmpdir"
require_relative "../lib/gvf"

class TestGVF < Minitest::Test
  LOCKFILE = <<~LOCK
    GEM
      remote: https://rubygems.org/
      specs:
        rails (7.1.2)
        puma (5.6.7)

    PLATFORMS
      ruby

    DEPENDENCIES
      rails
      puma (~> 5.0)
  LOCK

  def with_files(gemfile_content, lockfile_content = LOCKFILE)
    Dir.mktmpdir do |dir|
      gemfile  = File.join(dir, "Gemfile")
      lockfile = File.join(dir, "Gemfile.lock")
      File.write(gemfile, gemfile_content)
      File.write(lockfile, lockfile_content)
      yield gemfile, lockfile
    end
  end

  # --- constraint option ---

  def test_default_constraint_is_minor
    with_files(%(gem "rails"\n)) do |gemfile, lockfile|
      GVF.run(gemfile_path: gemfile, lockfile_path: lockfile)
      assert_includes File.read(gemfile), '"~> 7.1"'
    end
  end

  def test_minor_constraint
    with_files(%(gem "rails"\n)) do |gemfile, lockfile|
      GVF.run(gemfile_path: gemfile, lockfile_path: lockfile, constraint: "minor")
      assert_includes File.read(gemfile), '"~> 7.1"'
    end
  end

  def test_patch_constraint
    with_files(%(gem "rails"\n)) do |gemfile, lockfile|
      GVF.run(gemfile_path: gemfile, lockfile_path: lockfile, constraint: "patch")
      assert_includes File.read(gemfile), '"~> 7.1.2"'
    end
  end

  def test_raises_on_invalid_constraint
    with_files(%(gem "rails"\n)) do |gemfile, lockfile|
      assert_raises(RuntimeError, /Invalid constraint/) do
        GVF.run(gemfile_path: gemfile, lockfile_path: lockfile, constraint: "exact")
      end
    end
  end

  # --- integration ---

  def test_updates_gemfile_and_returns_count
    with_files(%(gem "rails"\ngem "puma", "~> 5.0"\n)) do |gemfile, lockfile|
      count = GVF.run(gemfile_path: gemfile, lockfile_path: lockfile)
      assert_equal 2, count
      content = File.read(gemfile)
      assert_includes content, 'gem "rails", "~> 7.1"'
      assert_includes content, 'gem "puma", "~> 5.6"'
    end
  end

  def test_writes_changes_to_disk
    with_files(%(gem "rails"\n)) do |gemfile, lockfile|
      GVF.run(gemfile_path: gemfile, lockfile_path: lockfile)
      assert_includes File.read(gemfile), "~> 7.1"
    end
  end

  # --- error handling ---

  def test_raises_when_gemfile_missing
    Dir.mktmpdir do |dir|
      lockfile = File.join(dir, "Gemfile.lock")
      File.write(lockfile, LOCKFILE)
      assert_raises(RuntimeError, /Gemfile not found/) do
        GVF.run(gemfile_path: File.join(dir, "Gemfile"), lockfile_path: lockfile)
      end
    end
  end

  def test_raises_when_lockfile_missing
    Dir.mktmpdir do |dir|
      gemfile = File.join(dir, "Gemfile")
      File.write(gemfile, 'gem "rails"')
      assert_raises(RuntimeError, /Gemfile.lock not found/) do
        GVF.run(gemfile_path: gemfile, lockfile_path: File.join(dir, "Gemfile.lock"))
      end
    end
  end

  # --- version constant ---

  def test_version_is_defined
    assert_match(/\d+\.\d+\.\d+/, GVF::VERSION)
  end
end
