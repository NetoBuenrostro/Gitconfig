#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#
# Reject a push to a branch if it has commits that do have invalid ticket statuses in references
#
# ref = ARGV[0]
sha_start = ARGV[1]
sha_end = ARGV[2]
# HOOK PARAMS
space = 'space-wiki-name'
api_key = 'user-api-key'
api_secret = 'user-api-secret'
# HOOK START, end of params block
require "net/https"
require "uri"
begin
  require "json"
rescue LoadError
  require 'rubygems'
  require 'json'
end
# Check referred tickets that are in open stage
class TicketValidator
  API_URL = "https://api.assembla.com"
  NUMBERS_RE = "(#[0-9]+(?:(?:[, &]*| ?and ?)#[0-9]+)*)"
  attr_accessor :space, :api_key, :api_secret
  def initialize(space, api_key, api_secret)
    @space = space
    @api_key = api_key
    @api_secret = api_secret
    @ticket_statuses = %w(re refs references see) # default statuses
    @messages = []
    init_http
    load_statuses
  end
  def check(sha, comment)
    commit_statuses = comment.to_s.scan(/([^\s:]+):?\s*#{NUMBERS_RE}/).collect {|el| el[0] }
    if commit_statuses.empty?
      @messages << "#{sha} - You must include a status in your commit message."
    else
      commit_statuses.each do |status|
        unless @ticket_statuses.include? status.downcase
          @messages << "#{sha} - invalid status #{status}."
        end
      end
    end
  end
  def load_statuses
    statuses = api_call "/v1/spaces/#{@space}/tickets/statuses.json"
    if statuses.is_a?(Hash) && statuses['error'] # no tickets tool
      $stderr.puts 'Error while loading ticket statuses: ' + statuses['error']
      exit 1
    end
    statuses.each do |status|
      @ticket_statuses << status["name"].downcase
    end
  end
  def api_call(uri)
    request = Net::HTTP::Get.new(
      uri,
      'Content-Type' => 'application/json',
      'X-Api-Key' => api_key,
      'X-Api-Secret' => api_secret
    )
    result = @http.request(request)
    JSON.parse(result.body)
  end
  def init_http
    uri = URI.parse(API_URL)
    @http = Net::HTTP.new(uri.host, uri.port)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  def show_decision!
    unless @messages.empty?
      puts "You have invalid ticket references."
      puts @messages.join("\n")
      puts "Valid statuses are #{@ticket_statuses.join(', ')}"
      exit 1
    end
  end
end
class Parser
  def initialize(text, validator)
    @text = text
    @validator = validator
  end
  def parse
    commit = nil
    comment = nil
    @text.to_s.split("\n").each do |line|
      if line =~ /^commit: ([a-z0-9]+)$/i
        new_commit = $1
        if comment
          @validator.check(commit, comment)
          comment = nil
        end
        commit = new_commit
      else
        comment = comment.to_s + line + "\n"
      end
    end
    # Check last commit
    @validator.check(commit, comment) if comment
  end
end
text = `git log --pretty='format:commit: %h%n%B' #{sha_start}..#{sha_end}`
validator = TicketValidator.new(space, api_key, api_secret)
Parser.new(text, validator).parse
validator.show_decision!
