# frozen_string_literal: true

require 'net/http'
require 'net/https'

def mailgun(api_key, domain, from_name, from_address, to, subject, message)
  url = URI.parse("https://api.mailgun.net/v3/#{domain}/messages")
  req = Net::HTTP::Post.new(url.path)

  req.basic_auth('api', api_key)
  req.set_form_data(
    from: "#{from_name} <#{from_address}>",
    to: to,
    subject: subject,
    html: message
  )

  res = Net::HTTP.new(url.host, url.port)
  res.use_ssl = true
  res.verify_mode = OpenSSL::SSL::VERIFY_PEER
  response = res.start { |http| http.request(req) }

  raise response.code_type unless response.code_type == Net::HTTPOK
end
