desc 'Create a new diagram'
arg_name 'new_diagram_name'
command [:new,:create] do |c|
  c.desc 'use the given diagram_id as a template'
  c.default_value nil
  c.flag [:t,:template]

  c.desc 'don\'t edit the new diagram'
  c.switch [:n,:"no-edit"]

  c.action do |global_options,options,args|

    raise(UnknownArgumentException,'You must specify the diagram name') if args.length != 1

    template_id = options[:t]

    diagram = $gliffy.create_diagram(args[0],template_id)
    if options[:n]
      puts "Diagram #{diagram.name} created with id #{diagram.id}"
    else
      GLI.run(['edit',diagram.id.to_s])
    end
  end
end

