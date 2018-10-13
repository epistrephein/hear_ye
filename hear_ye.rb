# frozen_string_literal: true

require 'bundler/setup'
require 'cgi'
require 'logger'
require 'open-uri'
require 'rss'
require 'time'
require 'yaml'

require_relative 'lib/mailgun'

BASE_URL = 'https://github.com/'
ATOM_URL = '/releases.atom'

# load and validate configuration
config = YAML.load_file(File.join(__dir__, 'config', 'config.yml'))
keys = %w[mailgun ignore repositories]

unless (keys & config.keys) == keys
  raise "Invalid config file, missing keys: #{(keys - config.keys).join(', ')}"
end

# load db
db_yml = File.join(__dir__, 'db', 'db.yml')
File.write(db_yml, [].to_yaml) unless File.file?(db_yml)
db = YAML.load_file(db_yml)

# initialize logger
logger = Logger.new($stdout)
logger.level = Logger::INFO

config['repositories'].each do |repository|
  # get rss feed
  begin
    rss = RSS::Parser.parse(open(BASE_URL + repository + ATOM_URL))
  rescue RSS::Error, OpenURI::HTTPError, Timeout::Error, Errno::ECONNRESET => e
    logger.error(repository) { "#{e.message} (#{e.class})" }
    next
  end

  rss.items.each do |item|
    id = item.id.content
    next if db.include?(id)

    # build repo infos
    date = item.updated.content
    user = item.link.href[%r{github.com/(.*?)/.*\z}, 1]
    repo = item.link.href[%r{github.com/.*?/(.*?)/.*\z}, 1]
    tag  = item.link.href[%r{github.com.*tag/(.*)\z}, 1]
    desc = item.content.content

    # skip ignored items and items older than a day (useful for first add)
    if tag =~ Regexp.union(config['ignore']) || date < (Time.now - 86_400)
      db << id
      File.write(db_yml, db.to_yaml)
      next
    end

    # log new item
    logger.info(repository) { tag }

    # build email html body
    body = <<~HTML
      <html>
        <h2><a href="#{URI.join(BASE_URL, item.link.href)}">#{user}/#{repo} #{tag}</a></h2>
        <p>#{date.rfc2822}</p>
        #{CGI.unescapeHTML(desc)}
      </html>
    HTML

    # send email via mailgun
    begin
      tries ||= 2
      mailgun(
        config['mailgun']['api_key'],
        config['mailgun']['domain'],
        config['mailgun']['from_name'],
        config['mailgun']['from_address'],
        config['mailgun']['to'],
        "#{user}/#{repo} #{tag}",
        body
      )
    rescue Net::HTTPClientError, Net::HTTPBadResponse, Net::ProtoServerError,
           Errno::ECONNRESET, Timeout::Error => e
      retry if (tries -= 1).positive?
      logger.error(repository) { "#{e.message} (#{e.class})" }
      next
    end

    # write db to file
    db << id
    File.write(db_yml, db.to_yaml)
  end
end
