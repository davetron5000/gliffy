desc 'List all diagrams in the account'
usage <<eos
[-l]

  -l - show all information
eos
command :list, :aliases => [:ls] do |gliffy,args|
  diagrams = gliffy.get_diagrams
  options = parse_options(args)
  if options['l']
    max = diagrams.inject(0) { |max,diagram| diagram.name.length > max ? diagram.name.length : max }
    diagrams.sort.each do |diagram|
      printf "%8d %s %-#{max}s %-3d %s  %s %s\n",
        diagram.id,
        diagram.is_public? ? "P" : "-",
        diagram.name,
        diagram.num_versions,
        format_date(diagram.create_date),
        format_date(diagram.mod_date),
        diagram.owner_username
    end
  else
    printf_string = "%d %s\n"
    diagrams.sort.each { |diagram| printf printf_string,diagram.id,diagram.name }
  end
end

desc 'Delete a diagram'
usage 'diagram_id'
command :delete, :aliases => [:del,:rm] do |gliffy,args|
  gliffy.delete_diagram(args[0])
end

desc 'Get the URL for an image'
usage <<eos
[-o] diagram_id

  -o - open diagram's URL with configured :open_url command
eos
command :url do |gliffy,args|
  open = args[0] == '-o'
  args.shift if open
  url = gliffy.get_diagram_as_url(args[0])
  if open
    if CLIConfig.instance.config[:open_image]
      system(sprintf(CLIConfig.instance.config[:open_image],url))
    else
      puts "Nothing configured for #{:open_image.to_s} to open the image"
      puts url
    end
  else
    puts url
  end
end

desc 'Download a diagram as an image to a file'
usage <<eos 
[-v version_num] [-f filename] [-d download_dir] [-t image_type] diagram_id

   image_type can be :jpeg, :jpg, :png, :svg, or :xml
   if no filename specified, uses the diagram's name
   if -d and -f are specified, -d is ignored
eos
command :get do |gliffy,args|

  options = parse_options(args)
  diagram_id = args.shift

  version_number = options['v'].to_i if options['v']
  filename = options['f'] if options['f']
  type = options['t'].to_sym if options['t']
  type = :jpg if !type
  if !filename
    dir = options['d'] || '.'
    metadata = gliffy.get_diagram_metadata(diagram_id)
    filename = metadata.name.gsub(/[\s\/\-\+\$]/,'_')
    if version_number
      filename = "#{dir}/#{filename}_v#{version_number}.#{type.to_s}"
    else
      filename = "#{dir}/#{filename}.#{type.to_s}"
    end
  end

  get_options = { :mime_type => type, :file => filename }
  get_options[:version] = version_number if version_number
  gliffy.get_diagram_as_image(diagram_id,get_options)
  puts filename
end

desc 'Edit a diagram'
usage 'diagram_id'
command :edit do |gliffy,args|
  return_link = gliffy.get_diagram_as_url(args[0])
  link = gliffy.get_edit_diagram_link(args[0],return_link,"Done")
  if CLIConfig.instance.config[:open_url]
    system(sprintf(CLIConfig.instance.config[:open_url],link.full_url))
  else
    puts "Nothing configured for #{:open_url.to_s} to open the url"
    puts link.full_url
  end
end

desc 'Create a new diagram'
usage <<eos
[-e] diagram_name

  -e edit the diagram after creating it
eos
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
    command_string = "   %-6s   %s %s\n"
    puts 'usage: gliffy [global_options] command [command_options]'
    puts 'global_options:'
    Command::GLOBAL_FLAGS.keys.sort.each do |flag|
      printf command_string,flag,Command::GLOBAL_FLAGS[flag],''
    end
    puts
    puts 'command:'
    command_names = Command.commands.keys.sort { |a,b| a.to_s <=> b.to_s }
    command_names.each() do |name|
      command = Command.commands[name]
      if !Command.aliases[name]
        aliases = Array.new
        Command.aliases.keys.each() do |a| 
          aliases << a if Command.commands[a] == command 
        end
        alias_string = '(also: ' + aliases.join(',') + ')' if aliases.length > 0
        printf command_string,name.to_s, command.description,alias_string
      end
    end
  end
end
