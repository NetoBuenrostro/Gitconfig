#!/usr/bin/env ruby
#
#Reject a push to a branch if file was changed without changing its version
#
ref = ARGV[0]
sha_start = ARGV[1]
sha_end = ARGV[2]
#HOOK PARAMS
file_path = "/path/to/file"
file_title = "WEB SERVICE"
regex_to_find_version = "WebServiceVersion=(\d+\.\d*)"
#HOOK START, end of params block
fileToPush=%x[git show #{sha_end}:#{file_path}]
originFile=%x[git show #{sha_start}:#{file_path}]
regex_to_find_version = Regexp.new(regex_to_find_version)
if originFile != fileToPush
  puts "\n"
  puts " ===================================================================================================="
  puts "|| #{file_title} WAS CHANGED"
  puts "|| INSPECTING #{file_title} VERSION"
  unless regex_to_find_version.match(fileToPush)
    puts "|| ERROR! PUSHING TO #{ref} BRANCH WAS TERMINATED: #{file_title} VERSION WAS NOT FOUND"
    puts " ===================================================================================================="
    puts "\n"
    exit 1
  end
  fileToPush.slice(regex_to_find_version)
  versionToPush = Regexp.last_match[1]
  puts "|| #{file_title} VERSION TO PUSH IS #{versionToPush}"
  originFile.slice(regex_to_find_version)
  if Regexp.last_match
    originVersion = Regexp.last_match[1]
    puts "|| #{file_title} VERSION IN ORIGIN REPOSITORY IS #{originVersion}"
  else
    originVersion = 0.0
    puts "|| THERE IS NO #{file_title} VERSION IN ORIGIN REPOSITORY"
  end
  if versionToPush.to_f <= originVersion.to_f
    puts "|| ERROR! PUSHING TO #{ref} BRANCH WAS TERMINATED: YOU DID NOT UPDATE #{file_title} VERSION!"
    puts " ===================================================================================================="
    puts "\n"
    exit 1
  end
end
puts "|| Everything is fine. Pushing..."
puts " ===================================================================================================="
puts "\n"
