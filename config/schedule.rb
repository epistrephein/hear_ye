job_type :ruby, 'cd :path && bundle exec ruby :task :output'

env :PATH, ENV['PATH']

set :chronic_options, hours24: true
set :output, error: File.join(Dir.pwd, 'log', 'errors.log')

every 1.hour do
  ruby 'hear_ye.rb'
end
