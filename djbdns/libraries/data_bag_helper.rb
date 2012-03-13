module DataBagHelper

  # args:: attribute names
  # Returns hash of requested attributes
  def bag_or_node_args(*args)
    Hash[*args.flatten.map{|k| [k.to_sym,bag_or_node(k.to_sym)]}.flatten]
  end

  # key:: attribute key
  # bag:: optional data bag
  # Returns value from data bag for provided key and falls back to 
  # node attributes if no value is found within data bag
  # TODO: Rescue is just a hack to get around chef throwing an error
  #   when trying to access non-existent keys
  def bag_or_node(key, bag=nil)
    bag ||= retrieve_data_bag
    begin
      val = bag[key.to_s] if bag
    rescue NoMethodError
      val = nil
    end
    val || node[:djbdns][key]
  end

  # Returns configuration data bag
  def retrieve_data_bag
    unless(@_cached_bag)
      if(data_bag_encrypted?)
        @_cached_bag = Chef::EncryptedDataBagItem.load(
          'djbdns', data_bag_name, data_bag_secret
        )
      else
        @_cached_bag = search(:djbdns, "id:#{data_bag_name}").first
      end
    end
    @_cached_bag
  end

  # Returns data bag entry name based on node attributes or
  # defaults to using node name prefixed with 'config_'
  def data_bag_name
    if(node[:djbdns][:config_bag])
      if(node[:djbdns][:config_bag].respond_to?(:has_key?))
        name = node[:djbdns][:config_bag][:name].to_s
      else
        name = node[:djbdns][:config_bag].to_s
      end
    end
    name.to_s.empty? ? "config_#{node.name}" : name
  end

  # Checks node attributes to determine if data bag is encrypted
  def data_bag_encrypted?
    if(node[:djbdns][:config_bag].respond_to?(:has_key?))
      !!node[:djbdns][:config_bag][:encrypted]
    else
      false
    end
  end

  # Returns data bag secret if data bag is encrypted
  def data_bag_secret
    if(data_bag_encrypted?)
      secret = node[:djbdns][:config_bag][:secret]
      if(File.exists?(secret))
        Chef::EncryptedDataBagItem.load_secret(secret)
      else
        secret
      end
    end
  end
end

Chef::Recipe.send(:include, DataBagHelper)
