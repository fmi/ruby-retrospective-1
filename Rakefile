require 'yaml'

desc 'Checks everything'
task :check do
  Rake::Task['tasks:01'].invoke
  Rake::Task['tasks:02'].invoke
  Rake::Task['tasks:03'].invoke
end

desc 'Starts watchr'
task :watch do
  system 'watchr watchr.rb'
end

namespace :tasks do
  task('01') { Rake::Task['tasks:run'].execute('01') }
  task('02') { Rake::Task['tasks:run'].execute('02') }
  task('03') { Rake::Task['tasks:run'].execute('03') }

  task :run, :task_id do |t, arg|
    index = arg
    Rake::Task['tasks:skeptic'].execute index
    Rake::Task['tasks:spec'].execute index
  end

  task :spec, :task_id do |t, arg|
    index = arg
    system("rspec --require ./solutions/#{index}.rb --fail-fast --color specs/#{index}_spec.rb") or exit(1)
  end

  task :skeptic, :task_id do |t, arg|
    index = arg.to_i
    opts = YAML.load_file('skeptic.yml')[index]
      .map { |key, value| [key, (value == true ? nil : value)].compact }
      .map { |key, value| "--#{key.tr('_', '-')} #{value}".strip }
      .join(' ')

    system("skeptic #{opts} solutions/0#{index}.rb") or exit(1)
  end
end
