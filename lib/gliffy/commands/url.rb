desc 'Get the URL for a diagram as an image image'
arg_name 'diagram_id'
command :url do |c|
  c.desc 'Open URL with configured :open_url command'
  c.switch [:o,:open]
  c.action do |global_options,options,args|
    raise UnknownArgumentException,"diagram id is required" if args.length == 0
    raise UnknownArgumentException,"Only one diagram id is supported" if args.length > 1
    url = $gliffy.get_diagram_as_url(args[0])
    if options[:o]
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
end
