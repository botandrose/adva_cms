if ENV["COVERAGE"]
  require "coverage"
  require "json"
  require "fileutils"
  begin
    Coverage.start(lines: true)
  rescue ArgumentError
    Coverage.start
  end

  at_exit do
    begin
      result = Coverage.result
      project_root = File.expand_path("..", __dir__)
      filtered = result.select { |path, _|
        path.start_with?(project_root) && (path.include?("/app/") || path.include?("/lib/")) && !path.include?("/vendor/")
      }
      files = {}
      filtered.each do |path, value|
        lines = value.is_a?(Hash) ? (value[:lines] || value["lines"]) : value
        files[path] = { "lines" => Array(lines) }
      end
      coverage_dir = File.join(project_root, "coverage")
      FileUtils.mkdir_p(coverage_dir)
      out_file = File.join(coverage_dir, "coverage.json")
      if File.exist?(out_file)
        prev = JSON.parse(File.read(out_file)) rescue { "files" => {} }
        prev_files = prev["files"] || {}
        files.each do |path, data|
          if prev_lines = prev_files.dig(path, "lines")
            cur = data["lines"].dup
            max = [cur.length, prev_lines.length].max
            merged = Array.new(max) do |i|
              a = cur[i]
              b = prev_lines[i]
              if a.nil? && b.nil?
                nil
              elsif a.nil?
                b
              elsif b.nil?
                a
              else
                a.to_i + b.to_i
              end
            end
            files[path]["lines"] = merged
          end
        end
        (prev_files.keys - files.keys).each { |path| files[path] = prev_files[path] }
      end
      covered = 0
      total = 0
      files.each_value do |data|
        arr = Array(data["lines"])
        arr.each do |v|
          next if v.nil?
          total += 1
          covered += 1 if v.to_i > 0
        end
      end
      percent = total.zero? ? 0.0 : (covered.to_f * 100.0 / total)
      payload = { "files" => files, "summary" => { "covered_lines" => covered, "total_lines" => total, "percent" => percent } }
      File.write(out_file, JSON.pretty_generate(payload))
      File.write(File.join(coverage_dir, "summary.txt"), sprintf("Coverage: %.2f%% (%d/%d)\n", percent, covered, total))
    rescue => e
      warn "Coverage write failed: #{e.class}: #{e.message}"
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |m|
    m.syntax = :expect
    m.verify_partial_doubles = true
  end

  config.filter_rails_from_backtrace! if config.respond_to?(:filter_rails_from_backtrace!)
end
