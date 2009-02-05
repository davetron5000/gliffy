desc 'Delete a diagram'
arg_name 'diagram_id [diagram_id]*'
command [:delete,:del,:rm] do |c|
  c.action do |global_options,options,args|
    raise UnknownArgumentException("diagram id is required") if args.length == 0;
    args.each do |diagram_id|
      $gliffy.delete_diagram(diagram_id)
    end
  end
end
