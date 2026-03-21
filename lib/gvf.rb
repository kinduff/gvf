require "bundler"
require_relative "gvf/gemfile_updater"

module GVF
  VERSION = "0.1.0"

  def self.run(gemfile_path: "Gemfile", lockfile_path: "Gemfile.lock", constraint: "minor")
    raise "Gemfile not found: #{gemfile_path}" unless File.exist?(gemfile_path)
    raise "Gemfile.lock not found: #{lockfile_path}" unless File.exist?(lockfile_path)
    raise "Invalid constraint '#{constraint}': must be 'minor' or 'patch'" unless %w[minor patch].include?(constraint)

    parser = Bundler::LockfileParser.new(File.read(lockfile_path))
    versions = parser.specs.each_with_object({}) { |spec, h| h[spec.name] = spec.version.to_s }

    updated, count = GemfileUpdater.update(gemfile_path, versions, constraint: constraint)

    File.write(gemfile_path, updated)
    count
  end
end
