#!/usr/bin/ruby #fetcher.rb 
#require 'rubygems'

require 'thread'
require 'net/ssh'
require 'yaml'
require 'erb'

class Fetcher

  SCORE         = 0
  TOTAL_COUNT   = 1
  WORDS_WRITTEN = 2 
  ENTER_OFFSET  = 2
  PLAYER        = 3
  WORDLIST      = 4

  RANK = %w{ninguno marsopa abuela humano administrador_de_sistemas torpon infante cadete cervantes secretaria tipografo  }
  LEVEL = %w{ninguno perdedor mediocre casi_bueno normal bueno muy_bueno profesional 3l33t deidad computadora}
 
  def initialize(environment="default", cmd=:fetch)
    @net_env = environment
    @config  = YAML::load(File.open(File.expand_path("../config.yml", __FILE__)))[@net_env]
    @hosts   = eval(@config["hosts"])
    @highscores = Hash.new { |hash, key| hash[key] = Hash.new }
    commands =  { :fetch => "cat #{@config["file"]}", 
                  :erase => "echo '#{@config["password"]}' | sudo -S rm #{@config["file"]}; echo '#{@config["password"]}' | sudo -S touch #{@config["file"]}; echo '#{@config["password"]}' | sudo -S chmod 666 #{@config["file"]}" }
    @cmd = commands[cmd]
    @mutex  = Mutex.new
  end

  def start
    pool = []
   @hosts.each do |host|
     pool << Thread.new do
       begin
         open_session(host) unless @config["excluded_hosts"].include? host
       rescue
         puts "#{host} is currently unreachable."
         # Uncomment the following line to permanently remove fallen computers
         #@config["excluded_hosts"] << host 
       end
     end
   end
   pool.each { |thread| thread.join }
   @highscores
  end

  def open_session(host)
    Net::SSH.start("#{@config["lan"]}.#{host}",  @config["username"], :password => @config["password"]) do |session|
      output = session.exec!(@cmd) || ""
        output.each_line do |l|
          field = l.split "\t"
          field[-1] = Time.at(field[-1].to_i)
          @mutex.synchronize do
            last_score = @highscores[field[WORDLIST]][field[PLAYER]][0].to_i if @highscores[field[WORDLIST]] and @highscores[field[WORDLIST]][field[PLAYER]]
            @highscores[field[WORDLIST]][field[PLAYER]] = field unless last_score and last_score > field[0].to_i
        end
      end
    end
  end

  def self.format(field)
    duration = field[-2].to_f / 100
    score = field[SCORE].to_i
    cps = (score + field[ENTER_OFFSET].to_i) / duration
    tcps = (field[TOTAL_COUNT].to_i + field[ENTER_OFFSET].to_i) / duration
    wpm = field[WORDS_WRITTEN].to_i / duration * 60
    typoratio =  1 - cps / tcps
    if (field[TOTAL_COUNT].to_i < 1)
      level = 0
    else
      level = field[TOTAL_COUNT].to_i / 100 + 1
    end
    level = 10 if level > 10
    {
      :score => score,
      :cps   => cps.round(2),
      :tcps  => tcps.round(2),
      :wpm   => (cps * 12).to_i, # wpm.round(2),
      :ratio => (typoratio * 100).round(2),
      :typoratio => typorank(typoratio * 100).gsub("_", " ").capitalize,
      :level => LEVEL[level].gsub("_", " ").capitalize
    }
  end

  private

  def self.typorank(typoratio)
    if (typoratio < 0)
      typorankki = 0;
    elsif (typoratio == 0)
      typorankki = 1;
    elsif (typoratio < 2)
      typorankki = 2;
    elsif (typoratio < 4)
      typorankki = 3;
    elsif (typoratio < 6)
      typorankki = 4;
    elsif (typoratio < 8)
      typorankki = 5;
    elsif (typoratio < 11)
      typorankki = 6;
    elsif (typoratio < 15)
      typorankki = 7;
    elsif (typoratio < 20)
      typorankki = 8;
    elsif (typoratio < 30)
      typorankki = 9;
    elsif (typoratio < 50)
      typorankki = 10;
    else
      typorankki = 11;
    end
    "#{typorankki}.- #{RANK[typorankki]}"
  end
end

