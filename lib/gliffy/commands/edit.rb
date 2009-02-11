desc 'Edit a diagram'
arg_name 'diagram_id'
command :edit do |c|

  c.action do |global_options,options,args|

    raise(UnknownArgumentException,'You must specify one diagram id') if args.length != 1

    return_link = $gliffy.get_diagram_as_url(args[0])
    link = $gliffy.get_edit_diagram_link(args[0],return_link,"Done")
    if Gliffy::CLIConfig.instance.config[:open_url]
      system(sprintf(Gliffy::CLIConfig.instance.config[:open_url],link.full_url))
    else
      puts "Nothing configured for #{:open_url.to_s} to open the url"
      puts link.full_url
    end
  end
end

