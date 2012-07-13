require 'cgi'
require 'yaml'
require 'iron_cache'
require 'twilio-ruby'


parsed = CGI::parse(payload)
from = parsed["From"][0]
body = parsed["Body"][0]


puts "-------------- RECEIVING REQUEST ---------------"
puts "PAYLOAD: #{payload}"
puts "Parsed Payload: #{parsed}"
puts "FROM: #{from}"
puts "BODY: #{body}"
puts "------------------------------------------------"

number = from.reverse.chop.chop.reverse


def shaunism
  all = []
  File.open('shaunisms.txt', 'r') do |f|
    while line = f.gets
      all << line.chomp
    end
  end
  all[rand(all.size)]
end



def move_day_forward(number)
  puts "Moving Day Forward"

  config = YAML.load_file("config.yml")
  twilio = Twilio::REST::Client.new config['twilio']['account_sid'], config['twilio']['auth_token']

  puts "Creating or Getting Cache...."
  ironcache = IronCache::Client.new(:project_id => config['iron']['project_id'], :token => config['iron']['token'])
  cache = ironcache.cache("insanity-#{number}")

  puts "Incrementing Day Cache"
  cache.increment("day")

  puts "Sending Shaunism"
  message = "Great job today. As Shaun T would say \"#{shaunism.chomp}\""
  twilio.account.sms.messages.create(
    :from => config['app']['from'],
    :to => number,
    :body => message
  )
end



move_day_forward(number) if body.downcase == "done"


