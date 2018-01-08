# Hear Ye

Send email notification using Mailgun when a GitHub repo tags a new release.

## Usage

Copy `config/config.example.yml` to `config/config.yml` and customize it with your Mailgun credentials and watched repos, then run `bundle install` to install required gems.

To setup a cron script for regular checks use the installed `whenever` gem.  
Customize the interval in `config/schedule.rb`, then run `whenever --update-crontab`.
