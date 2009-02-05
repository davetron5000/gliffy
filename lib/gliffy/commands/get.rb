desc 'Download a diagram as an image to a file'
arg_name 'diagram_id [diagram_id]*'
command :get do |c|

  c.desc 'Get a specific version number'
  c.arg_name 'version_number'
  c.default_value nil
  c.flag [:v,:version]

  c.desc 'Specify the filename'
  c.arg_name 'filename'
  c.default_value nil
  c.flag [:f,:filename]

  c.desc 'Specify the image type (one of jpeg, jpg, png, svg, xml)'
  c.arg_name 'type'
  c.default_value 'jpg'
  c.flag [:t,:type,:"image-type"]

  c.action do |global_options,options,args|

    raise(UnknownArgumentException,'You must specify a diagram id') if args.length == 0
    raise(MissingArgumentException,'You may not specify a filename when getting multiple diagrams') if args.length > 1 and options[:f]
    args.each do |diagram_id|

      version_number = options[:v]
      filename = options[:f]
      type = options[:t].to_sym
      if !filename
        dir = options['d'] || '.'
        metadata = $gliffy.get_diagram_metadata(diagram_id)
        filename = metadata.name.gsub(/[\s\/\-\+\$]/,'_')
        if version_number
          filename = "#{dir}/#{filename}_v#{version_number}.#{type.to_s}"
        else
          filename = "#{dir}/#{filename}.#{type.to_s}"
        end
      end

      get_options = { :mime_type => type, :file => filename }
      get_options[:version] = version_number if version_number
      $gliffy.get_diagram_as_image(diagram_id,get_options)
      puts filename
    end
  end
end
