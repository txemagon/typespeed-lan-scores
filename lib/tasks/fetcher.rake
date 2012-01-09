require File.expand_path('../../fetcher', __FILE__)

namespace :fetcher do

  desc "Erase the score file. Provide LAN_ENV for different than default."
  task :erase do
    environment = ENV["LAN_ENV"] || "default"
    Fetcher.new(environment, :erase).start
    puts "entries erased."
  end

  desc "Fetch entries without speeds. Provide LAN_ENV for different than default."
  task :get_raw_scores do
    environment = ENV["LAN_ENV"] || "default"
    puts Fetcher.new(environment).start.to_yaml
  end

  desc "Fetch entries and format them. Provide LAN_ENV for different than default."
  task :get_scores do
    environment = ENV["LAN_ENV"] || "default"
    Fetcher.new(environment).start.each do |language, users|
      puts language
      puts "="*10
      users.each do |user, field|
        puts "\n=#{user}="
        puts Fetcher.format(field).to_yaml
      end
      puts
    end
  end

end
