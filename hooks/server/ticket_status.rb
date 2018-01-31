#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#
# Reject a push to a branch if it has commits that do refer a ticket in open state
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
  attr_accessor :space, :api_key, :api_secret
  def initialize(space, api_key, api_secret)
    @space = space
    @api_key = api_key
    @api_secret = api_secret
    @ticket_statuses = []
    @tickets = {}
    init_http
    load_statuses
  end
  def check(sha, comment)
    comment.to_s.scan(/#\d+/).each do |t|
      ticket = t.tr('#', '')
      # Do not check it twice
      next if @tickets[ticket]
      ticket_data = api_call "/v1/spaces/#{space}/tickets/#{ticket}.json"
      if ticket_data['error']
        error = ticket_data['error']
      elsif !@ticket_statuses.include?(ticket_data['status'].downcase)
        error = "Ticket #{t} is not open!"
      end
      @tickets[ticket] = error ? { error: error, sha: sha } : :ok
    end
  end
  def load_statuses
    statuses = api_call "/v1/spaces/#{@space}/tickets/statuses.json"
    statuses.each do |status|
      @ticket_statuses << status["name"].downcase if status["state"] == 1 # open
    end
  end
  def api_call(uri)
    request = Net::HTTP::Get.new(
      uri,
      'Content-Type' => 'application/json',
      'X-Api-Key' => @api_key,
      'X-Api-Secret' => @api_secret
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
    @tickets.reject! {|_, value| value == :ok }
    unless @tickets.empty?
      puts "You have references to tickets in closed state"
      @tickets.each do |ticket, details|
        puts "\t#{details[:sha]} - ##{ticket} #{details[:error]}"
      end
      puts "Valid statuses: #{@ticket_statuses.join(', ')}"
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
