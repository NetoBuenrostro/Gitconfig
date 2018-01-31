#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#
# Reject a push to a branch if it has commits that do not match regexp
# By Default it searches for ticket reference: #1234
#
# ref = ARGV[0]
sha_start = ARGV[1]
sha_end = ARGV[2]
# HOOK PARAMS
regexp = '#\d+'
# HOOK START, end of params block
class RegexpValidator
  def initialize(exp)
    @str_exp = exp
    @exp = Regexp.new(exp)
    @commits = []
  end
  def check(sha, comment)
    unless comment.to_s =~ @exp
      @commits << sha
    end
  end
  def show_decision!
    unless @commits.empty?
      puts "You must have commit messages that match /#{@str_exp}/\nInvalid commits: #{@commits.join(', ')}"
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
range = "#{sha_start}..#{sha_end}"
range = sha_end if sha_start == '0' * 40 # new branch?
text = `git log --pretty='format:commit: %h%n%B' #{range}`
@validator = RegexpValidator.new(regexp)
Parser.new(text, @validator).parse
@validator.show_decision!
