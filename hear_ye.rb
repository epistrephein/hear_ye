require 'bundler/setup'
require 'cgi'
require 'logger'
require 'open-uri'
require 'rss'
require 'time'
require 'yaml'

require_relative 'mailgun'

BASE_URL = 'https://github.com/'
ATOM_URL = '/releases.atom'

# load configuration
config = YAML.load_file(File.join(__dir__, 'config', 'config.yml'))

# load db
db_yml = File.join(__dir__, 'db', 'db.yml')
File.write(db_yml, [].to_yaml) unless File.file?(db_yml)
db = YAML.load_file(db_yml)

# initialize logger
logger = Logger.new($stdout)
logger.level = Logger::INFO

config['repositories'].each do |repository|
  # get rss feed
  rss = RSS::Parser.parse(open(BASE_URL + repository + ATOM_URL))
  rss.items.each do |item|
    id = item.id.content
    next if db.include?(id)

    date = item.updated.content

    # skip items older than a day (useful for first add)
    if date < (Time.now - 86_400)
      db << id
      File.write(db_yml, db.to_yaml)
      next
    end

    user = item.link.href[/\A\/(.*?)\/.*\Z/, 1]
    repo = item.link.href[/\A\/.*?\/(.*?)\/.*\Z/, 1]
    tag  = item.link.href[/\A.*tag\/(.*)\Z/, 1]
    desc = item.content.content

    # log new item
    logger.info('NEW') { "#{user}/#{repo} #{tag}" }

    # build html body
    body = <<~HTML
      <html>
        <h2><a href="https://github.com#{rss.items[1].link.href}">#{user}/#{repo} #{tag}</a></h2>
        <p>#{date.rfc2822}</p>
        <br>
        #{CGI.unescapeHTML(desc)}
      </html>
    HTML

    # send email
    mailgun(
      config['mailgun']['api_key'],
      config['mailgun']['domain'],
      config['mailgun']['from_name'],
      config['mailgun']['from_address'],
      config['mailgun']['to'],
      "#{user}/#{repo} #{tag}",
      body
    )

    # write db to file
    db << id
    File.write(db_yml, db.to_yaml)
  end
end
