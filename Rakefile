require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'

YARD::Rake::YardocTask.new

Rake::TestTask.new do |t|
  t.test_files = FileList['test/test_*.rb']
end

task :build => :test

task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].execute
end

desc "Create test pdf files"
task :make_test_pdf do
  text_to_pdf = 'enscript -B -f "Times-Roman6.0" %s --output=- | ps2pdf - > %s'

  Dir.chdir(File.join(File.dirname(__FILE__), 'test', 'data')) do
    Dir['*statement*.txt']. each do |name|
      name = name.sub(/\.txt$/, '')
      system(text_to_pdf % [name + '.txt', name + '.pdf'])
    end
  end
end
