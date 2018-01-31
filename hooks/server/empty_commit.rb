#!/usr/bin/env ruby
#
# Reject a push to a branch if it has no changes in the commit (empty commit).
#
# ref = ARGV[0]
sha_start = ARGV[1]
sha_end = ARGV[2]
# HOOK PARAMS
# HOOK START, end of params block
text = `git log --numstat --pretty='format:' #{sha_start}..#{sha_end}`
changecount = text.to_s.split("\n").length
if changecount == 0
  puts "Rejecting empty commit"
  exit 1
end
