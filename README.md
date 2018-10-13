# Hear Ye

Send email notification using Mailgun when a GitHub repo tags a new release.

## Usage

Copy `config/config.example.yml` to `config/config.yml` and customize it with your
Mailgun credentials and watched repos.

Run `bundle install` to install the required gems.

To setup a cron script for regular checks use the installed `whenever` gem.  
Copy `config/schedule.example.rb` to `config/schedule.rb` and customize the interval,
then run `whenever --update-crontab`.
