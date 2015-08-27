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
  temp = last_commit = store.transaction { store.fetch(:last_commit, 1) }

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

def post_message message
  puts "Sending message to Telegram."
  HTTParty.get "#{TELEGRAM_API}/sendMessage?chat_id=#{ENV['CHAT_ID']}&text=#{message}"
  puts "Notified them."
end

TELEGRAM_API = ENV["TELEGRAM_API"]

users = ['avinoth', 'hindupuravinash']

users.each do |user|
  puts "Checking commits of #{user}"
  check_commit user
end
puts "All done for the day."
