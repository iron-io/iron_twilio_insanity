require 'sinatra'
require 'iron_cache'
require 'iron_worker_ng'
require 'twilio-ruby'
use Rack::Logger

helpers do
  def puts(msg)
    request.logger.info msg
  end
end

get '/' do
  erb :index
end

get '/start' do
  number = params[:number]
  cache = get_cache("insanity-#{number}")
  load_schedule(cache)
  cache.put("day", 0)

  config = YAML.load_file("config.yml")
  client = IronWorkerNG::Client.new(:token => config['iron']['token'], :project_id => config['iron']['project_id'])

  client.schedules.create('SendInsanity',
                          {
                            :number => number
                          },
                          {
                            :start_at => Time.now,
                            :run_times => 5,
                            :run_every => 60
                          })

  redirect '/done'
end

get '/done' do
  erb :done
end


get '/receive' do
  puts "-------------- RECEIVING REQUEST ---------------"
  puts "FROM: #{params[:From]}"
  puts "BODY: #{params[:Body]}"
  puts "------------------------------------------------"

  number = params[:From].reverse.chop.chop.reverse

  move_day_forward(number) if params[:Body].downcase == "done"
end


private

def move_day_forward(number)
  config = YAML.load_file("config.yml")
  twilio = Twilio::REST::Client.new config['twilio']['account_sid'], config['twilio']['auth_token']

  cache = get_cache("insanity-#{number}")
  cache.increment("day")

  message = "Great job today. As Shaun T would say \"#{shaunism.chomp}\""

  puts "Sending Shaunism"
  twilio.account.sms.messages.create(
    :from => config['app']['from'],
    :to => number,
    :body => message
  )
  puts "Congratulations! We've moved your workout forward one day!"
end


def shaunism
  all = []
  File.open('shaunisms.txt', 'r') do |f|
    while line = f.gets
      all << line.chomp
    end
  end
  all[rand(all.size)]
end


def get_cache(name)
  puts "Creating or Getting Cache...."
  ironcache = IronCache::Client.new
  ironcache.cache(name)
end


def load_schedule(cache)
  puts "Loading Cache Up...."
  i=0
  File.open('insanity_schedule.txt', 'r') do |f|
    while line = f.gets
      cache.put(i.to_s, line)
      i+=1
    end
  end
end


