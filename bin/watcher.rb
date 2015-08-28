require 'httparty'
require 'json'
require 'pstore'
require 'open-uri'
require 'time'

def check_commit user
  github_url = "https://api.github.com/users/#{user}/events/public"
  puts "Checking if there's a new commit."
  store = PStore.new("commits.pstore")
  resp = HTTParty.get(github_url)
  commits = JSON.parse(resp.body)
  temp = last_commit = store.transaction { store.fetch(:last_commit, (Time.now - 10*60*60).to_s) }

  commits.each do |commit|
    if Time.parse(last_commit) >= Time.parse(commit['created_at'])
      puts "No Commits to process. Exiting for #{user}"
      break
    end
    puts "#{user} pushed a code. sending message."
    if commit['type'] == 'PushEvent'
      message = "#{user} has pushed #{commit['payload']['commits'].length} new commits to #{commit['repo']['name']} at #{commit['created_at']}."
    else
      next
    end
    post_message(URI::encode(message))
    temp = commit['created_at']
  end

  store.transaction do
    store[:last_commit] = temp
  end
end

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
  HTTParty.get "#{TELEGRAM_API}/sendMessage?chat_id=#{ENV['CHAT_ID'] || -10058239}&text=#{message}"
  puts "Notified them."
end

TELEGRAM_API = ENV["TELEGRAM_API"] || "https://api.telegram.org/bot135445428:AAEdueEnG7AijSpSGSDEkn58Tfyb9m4cBFA"

users = ['avinoth', 'hindupuravinash']

users.each do |user|
  puts "Checking commits of #{user}"
  check_commit user
  if Time.now.hour == 23
    check_and_alert user
  end
end
puts "All done for the day."
