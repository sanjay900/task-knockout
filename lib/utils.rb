module Utils
  def self.commandify(str)
    str.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-').gsub(/^-/, '').gsub(/-$/, '')
  end
  def self.print_data(data, options)
    if options[:format] == 'json'
      puts data.to_json
    elsif options[:format] == 'yaml'
      puts data.to_yaml
    elsif options[:format] == 'kv'
      to_kv(data).each do |k, v|
        puts "#{k}: #{v}"
      end
    elsif options[:format] == 'tp'
      tp data
    end
  end

  def self.to_kv(data)
    to_kv_items(nil, data).flatten.reduce({}){|o, i| o.merge i}
  end

  def self.to_kv_items(root, data)
    if data.respond_to? :each
      if data.respond_to? :has_key?
        join_char = if root && root[-1] != ']'
                      '.'
                    end
        data.map do |k, v|
          to_kv_items([root, k].select{ |p| p }.join(join_char), v)
        end
      else
        data.each_with_index.map do |v, i|
          to_kv_items("#{root}[#{i}]", v)
        end
      end
    else
      [{root => data}]
    end
  end
end