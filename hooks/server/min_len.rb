#!/usr/bin/env ruby
#
# Reject a push to a branch if it has commits smaller than min_len characters
#
# ref = ARGV[0]
sha_start = ARGV[1]
sha_end = ARGV[2]
# HOOK PARAMS
min_len = '50'
# HOOK START, end of params block
class MinLenValidator
  def initialize(min_len)
    @min_len = min_len.to_i
    @commits = []
  end
  def check(sha, comment)
    unless comment.to_s.length >= @min_len
      @commits << sha
    end
  end
  def show_decision!
    unless @commits.empty?
      puts "You must have commit messages that are >= #{@min_len} characters\nInvalid commits: #{@commits.join(', ')}"
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
min_len = 50 if min_len.to_i <= 0
text = `git log --pretty='format:commit: %h%n%B' #{sha_start}..#{sha_end}`
@validator = MinLenValidator.new(min_len)
Parser.new(text, @validator).parse
@validator.show_decision!
