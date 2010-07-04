def run(cmd)
  puts(cmd)
  system(cmd)
end

watch('.*') { |m| system('clear'); run "rake" }

# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all features ---\n\n"
  run "rake"
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }