# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "yard"
require "yard/doctest/rake"

task :docs do
  Rake::Task["docs:yard"].invoke
  Rake::Task["docs:yard:doctest"].invoke
end

namespace :docs do
  YARD::Rake::YardocTask.new do |t|
    t.files = ["lib/**/*.rb"]
    t.options = []
    t.stats_options = ["--list-undoc"]
  end

  task :fswatch do
    sh 'fswatch -0 lib | while read -d "" e; do rake docs:yard; done'
  end

  YARD::Doctest::RakeTask.new do |task|
    task.doctest_opts = %w[-v]
    task.pattern = Dir.glob("lib/**/*.rb")
  end
end

desc "Test example code in user-docs (aka pages)"
task :byexample do
  system "#{__dir__}/bin/byexample"
end

task :default do
  Rake::Task["spec"].invoke
  Rake::Task["docs:yard:doctest"].invoke
end
