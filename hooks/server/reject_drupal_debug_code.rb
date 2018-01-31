#!/usr/bin/ruby
# -*- encoding : utf-8 -*-
#
# Reject push to a branch if Drupal debug functions are present.
#
sha_start = ARGV[1]
sha_end = ARGV[2]
DEFAULT_CHECKS = "dsm dpm dpr dprint-r db_queryd krumo krumo_add kpr kprint_r var_dump dd drupal_debug dpq dfb debug"
# HOOK PARAMS
# Provide default functions to check for or use the one provided
checks = ''
# END OF HOOK PARAMS
checks = DEFAULT_CHECKS if checks =~ /^\s*$/
diff_val = `git diff #{sha_start} #{sha_end}`
checks = checks.split(" ")
# Go through each line in the diff
diff_val.each_line do |line|
  if line.start_with? '+'
    checks.each do |check|
      regex = /\b#{check}\(*/i
      if regex.match(line)
        puts "Your code should not match /#{check}/\nThe diff in range #{sha_start} ... #{sha_end} fails this check"
        exit 1
      end
    end
  end
end
