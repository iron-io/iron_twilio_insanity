
Setup:

sudo bundle install (iron_worker_ng has the iron_worker command line interface)
fill in values in config file
fill in values in workers/iron.json
cd workers
iron_worker upload send_insanity
iron_worker upload twilio_webhook

To Run:

ruby web.rb
browse to http://localhost:4567/
enter your number



https://worker-aws-us-east-1.iron.io/2/projects/{PROJECT_ID}/tasks/webhook?code_name=TwilioWebhook&oauth={TOKEN}
