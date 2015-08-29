require 'httparty'
require 'json'
require 'open-uri'
require 'time'

def check_and_alert user
  github_url = "https://api.github.com/users/#{user}/events/public"
  puts "Checking if #{user} has pushed code for the day."
  resp = HTTParty.get(github_url)
  commits = JSON.parse(resp.body)
  pushed = false
  commits.each do |commit|
    if pushed
      break
    end
    if Time.parse(commit['created_at']).day < Time.now.day and !(pushed)
      message = "ALERT!!!!!! - Hey! @#{user}, You haven't pushed code today yet.. Gather up and do it NOW!!!"
      post_message(URI::encode(message))
      break
    end
    pushed = true
  end
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
  if Time.now.hour > 21
    check_and_alert user
  end
end
puts "All done for the day."
