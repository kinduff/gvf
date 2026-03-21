module GVF
  module GemfileUpdater
    # Returns [updated_content, count_of_changes]
    def self.update(gemfile_path, versions, constraint: "minor")
      content = File.read(gemfile_path)
      count = 0

      updated = content.gsub(/^([ \t]*gem[ \t]+['"]([^'"]+)['"])([^#\n]*)/) do
        indent_and_name = $1
        name = $2
        rest = $3

        version = versions[name]
        unless version
          next $&  # no match in lockfile, leave unchanged
        end

        # Strip version constraint strings (e.g. "~> 1.0", ">= 0.18", "< 2.0")
        # and keep everything else (require:, group:, platforms:, etc.)
        options = rest.gsub(/,?[ \t]*["'][ \t]*(?:~>|>=|<=|!=|[><]=?|=)[ \t]*\d[^'"]*["']/, "")

        count += 1
        "#{indent_and_name}, \"#{format_constraint(version, constraint)}\"#{options}"
      end

      [updated, count]
    end

    def self.format_constraint(version, constraint)
      parts = version.split(".")
      case constraint
      when "minor" then "~> #{parts[0..1].join(".")}"
      when "patch" then "~> #{parts[0..2].join(".")}"
      end
    end
  end
end
