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



private


def get_cache(name)
  puts "Creating or Getting Cache...."
  ironcache = IronCache::Client.new
  ironcache.cache(name)
end


def load_schedule(cache)
  puts "Loading Cache Up...."
  i=0
  File.open('lists/insanity_schedule.txt', 'r') do |f|
    while line = f.gets
      cache.put(i.to_s, line)
      i+=1
    end
  end
end


