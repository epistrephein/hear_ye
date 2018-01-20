job_type :ruby, 'cd :path && bundle exec ruby :task :output'

env :PATH, ENV['PATH']

set :chronic_options, hours24: true
set :output,
    standard: File.join(Dir.pwd, 'log', 'stdout.log'),
    error:    File.join(Dir.pwd, 'log', 'stderr.log')

every 15.minutes do
  ruby 'hear_ye.rb'
end
