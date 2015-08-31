require 'httparty'
require 'json'
require 'open-uri'
require 'time'

def check_and_alert user
  github_url = "https://api.github.com/users/#{user}/events/public"
  puts "Checking if #{user} has pushed code for the day."
  resp = HTTParty.get(github_url)
  commits = JSON.parse(resp.body)
  deployed_code = {}
  commits.each do |commit|
    if (Time.parse(commit['created_at']) + 330 * 60).day < Time.now.day
      break
    else
      deployed_code[commit['repo']['name']] = (deployed_code[commit['repo']['name']] || 0) + 1
    end
  end
  if deployed_code.size < 1
    message = "ALERT!!!!!! - Hey! @#{user}, You haven't pushed code today yet.. Gather up and do it NOW!!!"
  else
    message = "Summary: #{user} has committed #{deployed_code.values.inject(:+)} commits today. Breakup :- \n "
    message += deployed_code.keys.map{|k| "#{k}: #{deployed_code[k]}"}.join("\n")
  end
  post_message URI::encode(message)
end


def post_message message
  puts "Sending message to Telegram."
  HTTParty.get "#{TELEGRAM_API}/sendMessage?chat_id=#{ENV['CHAT_ID']}&text=#{message}"
  puts "Notified them."
end

TELEGRAM_API = ENV["TELEGRAM_API"]

users = ['avinoth', 'hindupuravinash']

users.each do |user|
  puts "Checking commits of #{user}"
  # check_commit user
  if Time.now.hour > 22
    check_and_alert user
  end
end
puts "All done for the day."
