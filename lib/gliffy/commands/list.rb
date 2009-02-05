desc 'List all diagrams in the account'
command [:list,:ls] do |c|
 
  c.desc 'List long form'
  c.switch :l

  c.action do |global_options,options,args|
    diagrams = $gliffy.get_diagrams
    if options[:l]
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
end

