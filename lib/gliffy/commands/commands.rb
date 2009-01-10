desc 'List all diagrams in the account'
usage 
command :list, :aliases => [:ls] do |gliffy,args|
  diagrams = gliffy.get_diagrams
  diagrams.sort.each { |diagram| printf "#%7d %s\n",diagram.id,diagram.name }
end

desc 'Delete a diagram'
usage 'diagram_id'
command :delete, :aliases => [:del,:rm] do |gliffy,args|
  gliffy.delete_diagram(args[0])
end

desc 'Get the URL for an image'
usage '[-o] diagram_id'
command :url do |gliffy,args|
  open = args[0] == '-o'
  args.shift if open
  url = gliffy.get_diagram_as_url(args[0])
  if open
    system "open \"#{url}\""
  else
    puts url
  end
end

desc 'Download a diagram as an image to a file'
usage 'diagram_id [filename]'
command :get do |gliffy,args|
  filename = "#{args[0]}.jpg"
  filename = args[1] if args[1]
  gliffy.get_diagram_as_image(args[0],:mime_type => :jpeg, :file => filename)
  puts filename
end

desc 'Edit a diagram'
usage 'diagram_id'
command :edit do |gliffy,args|
  return_link = gliffy.get_diagram_as_url(args[0])
  link = gliffy.get_edit_diagram_link(args[0],return_link,"Done")
  system "open \"#{link.full_url}\""
end

desc 'Create a new diagram'
usage '[-e] diagram_name'
command :new do |gliffy,args|
  edit = args[0] == '-e'
  args.shift if edit
  diagram = gliffy.create_diagram(args[0])
  if edit
    Gliffy::Command.commands[:edit].run [diagram.id]
  else
    puts "#{diagram.name} created with id #{diagram.id}"
  end
end

desc 'Show commands'
offline true
usage 'command'
command :help do |args|
  if args[0]
    command = Command.commands[args[0].to_sym]
    if command
      printf "%s - %s\n",args[0],command.description
      printf "usage: %s %s\n",args[0],command.usage
    else
      puts "No such command #{args[0]}"
    end
  else
    command_string = "%6s - %s\n"
    puts 'usage: gl [global_options] command [command_options]'
    puts 'global_options:'
    Command::GLOBAL_FLAGS.keys.sort.each do |flag|
      printf command_string,flag,Command::GLOBAL_FLAGS[flag]
    end
    puts
    puts 'command:'
    command_names = Command.commands.keys.sort { |a,b| a.to_s <=> b.to_s }
    command_names.each() do |name|
      command = Command.commands[name]
      printf command_string,name.to_s, command.description
    end
  end
end
