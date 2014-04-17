require 'json'
require 'nori'

class HashTree
  #*************************************************************************************
  # CONSTRUCTOR
  #*************************************************************************************
  def initialize(hash={})
    hash = {} unless hash.is_a? Hash

    @hash = hash
  end


  #*************************************************************************************
  # PUBLIC CLASS METHODS
  #*************************************************************************************
  def self.from_json(json_data)
    return nil if json_data.to_s.empty?

    parsed_data = JSON.parse(json_data)

    tree = self.new(parsed_data)
    tree.replace_values!(nil, '')

    return tree
  end

  def self.from_json_path(json_path)
    from_json File.read(json_path)
  end

  def self.from_xml(xml_data)
    return nil if xml_data.to_s.empty?
    
    parser = Nori.new
    tree = self.new(parser.parse(xml_data))
    tree.replace_values!(nil, '')

    return tree
  end

  def self.from_xml_path(xml_path)
    from_xml File.read(xml_path)
  end

  def self.from_yml_path(yml_path)
    yml_data = YAML.load_file(yml_path)

    tree = self.new(yml_data)

    return tree
  end


  #*************************************************************************************
  # PUBLIC METHODS
  #*************************************************************************************
  def checksum
    Digest::MD5.hexdigest(@hash.to_json.scan(/\S/).sort.join)
  end

  def children(name)
    if @hash[name] and @hash[name][name.chop]
      return [@hash[name][name.chop]].flatten
    else
      return []
    end
  end

  def clone_tree
    HashTree.new(Marshal.load(Marshal.dump(@hash)))
  end

  # Remove all key with a nil value
  def compact!
    @hash = compact
  end

  def each(options={}, &block)
    options = { :hash => @hash, :key_path => [], :scope => nil }.merge(options)

    options[:hash].each do |key, value|
      key_path = [options[:key_path], key].flatten
      key_path_string = key_path.join('.')

      if in_scope?(key_path_string, options[:scope])
        if (options[:scope] and options[:scope] == key_path_string)
          yield options[:hash], key, value, key_path_string
        else
          cast(value, Array).each do |item|
            if item.is_a? Hash
              each(:hash => item, :key_path => key_path, :scope => options[:scope], &block)
            else
              yield options[:hash], key, item, key_path_string
            end
          end
        end
      end
    end
  end

  # Takes a path (keys separated by dots) and yield an hash of the parents of all level (ascendants) up to the root, along with the value of the path.
  def each_node(path, options={}, &block)
    options = { :hash => @hash, :key_path => [], :parents => {} }.merge(options)
    return unless path && !path.empty?

    all_keys = path.split('.')
    keys = all_keys[options[:key_path].size..-1]
    key = keys.shift
    key_path = [options[:key_path], key].flatten
    key_path_string = key_path.join('.')
    value = options[:hash][key]

    if value
      parents = options[:parents].merge(Hash[key_path_string, options[:hash]])

      # Go no further?
      if (key_path == all_keys)
        yield parents, value
      else
        if value.kind_of? Array
          value.each do |item|
            if item.kind_of? Hash
              each_node(path, {:hash => item, :key_path => key_path, :parents => parents}, &block)
            end
          end
        elsif value.kind_of? Hash
          each_node(path, {:hash => value, :key_path => key_path, :parents => parents}, &block)
        end
      end
    end
  end

  def empty?
    @hash.empty?
  end

  def exists?(path='', hash=nil)
    hash = @hash unless hash

    path_parts = path.split('.')

    hash.each do |key, value|
      value_for_loop = (value.is_a? Array) ? value : [value]

      if path_parts[0] == key
        return true if path_parts.length == 1

        value_for_loop.each do |item|
          if item.is_a?(Hash)
            return true if exists?(path_parts[1..-1].join('.'), item)
          end
        end

      end
    end

    return false
  end

  def get(path='', options={})
    options = { :default => '', :force => nil }.merge(options)

    if not path.empty?
      data = []
      self.each(:scope => path) { |parent, k, v| data << cast(v, options[:force]) }
      data = (data.length <= 1 ? data.first : data)
    else
      data = @hash
    end

    return (data == nil ? options[:default] : data)
  end

  def keys_to_s!(options={})
    options = { :hash => nil }.merge(options)

    options[:hash] = @hash unless options[:hash]

    options[:hash].keys_to_s!

    options[:hash].each do |key, value|
      value_for_loop = (value.is_a? Array) ? value : [value]
      value_for_loop.each { |item| keys_to_s!(:hash => item) if item.is_a? Hash }
    end
  end

  def id
    #override the id method of all object
    get('id')
  end

  def insert(path, content)
    current_value = get(path)

    if current_value.is_a? Array
      if content.is_a? Array
        current_value = current_value.concat(content)
      else
        current_value << content
      end
    end

    set(path, current_value)
  end

  def inspect(options={})
    options = { :hash => nil, :position => 0, :raw => true }.merge(options)

    options[:hash] = @hash unless options[:hash]

    return options[:hash].inspect if options[:raw]

    content = ""

    options[:hash].each do |key, value|
      convert_to_array(value).each do |item|
        content << "\n" + ('   ' * options[:position]) + "#{key} : "
        content << (item.is_a?(Hash) ? inspect(:hash => item, :position => options[:position]+1) : value.inspect)
      end
    end

    return content
  end

  def merge(other_hash)
    @hash = merge_children(@hash, other_hash)
  end

  def remove(path, options={})
    options = { :if => nil, :remove_leaf => true, :unless => nil }.merge(options)

    set(path, nil, options) if exists?(path)
  end

  def rename_key!(path, new_name, hash=nil)
    hash = @hash unless hash

    path_parts = path.split('.')

    renamed_keys = {}

    hash.each do |key, value|
      if path_parts[0] == key
        if path_parts.length == 1
          renamed_keys[new_name] = hash.delete path_parts[0]
        else
          convert_to_array(value).each { |i| rename_key!(path_parts[1..-1].join('.'), new_name, i) if i.is_a? Hash }
        end
      end
    end

    hash.merge! renamed_keys if not renamed_keys.empty?
  end

  def replace_values!(old_value, new_value, hash=nil)
    hash = @hash unless hash

    hash.each do |key, value|
      if value.is_a? Array
        value.each do |item|
          if item.is_a?(Hash)
            item = replace_values!(old_value, new_value, item)
          else
            item = new_value if item == old_value
          end
        end
      elsif value.is_a? Hash
        value = replace_values!(old_value, new_value, value)
      elsif value == old_value
        value = new_value
      end

      hash[key] = value
    end

    return hash
  end

  def set(path, value, options={})
    options = { :accept_nil => true, :if => nil, :remove_leaf => false, :unless => nil }.merge(options)

    set_children(@hash, path, value, options) if options[:accept_nil] or value
  end

  def slash(path)
    if exists?(path)
      slashed_tree = get(path)
      slashed_tree = slashed_tree.first if slashed_tree.is_a? Array and slashed_tree.length == 1 and slashed_tree.first.is_a? Hash
    else
      slashed_tree = @hash
    end

    return HashTree.new(slashed_tree)
  end

  def slash!(path)
    @hash = slash(path).get
  end

  def to_json
    @hash.to_json
  end

  def to_yaml
    self.keys_to_s!

    return @hash.ya2yaml
  end

  #*************************************************************************************
  # PRIVATE METHODS
  #*************************************************************************************
  private

  def compact(hash=nil)
    hash = @hash unless hash

    hash.each do |key, value|
      if value.is_a? Array
        hash[key] = compact_array value
      elsif value.is_a? Hash
        hash[key] = compact value
      end
    end

    hash = compact_simple_hash(hash)

    return (hash.empty? ? nil : hash)
  end

  def compact_array(array)
    array.each { |item| item = compact(item) if item.is_a? Hash }
    array.compact!

    return (array.empty? ? nil : array)
  end

  def compact_simple_hash(hash)
    hash.delete_if { |k,v| not v }
  end

  def cast(value, type)
    case type.to_s
      when 'Array' then convert_to_array value
      when 'HashTree' then convert_to_hash_tree value
      when 'String' then value.to_s
      else value
    end
  end

  def check_conditions(hash, conditions, comparaison = :if)
    if conditions
      conditions.each do |value, equal|
        compare_values = hash
        equal = [equal] unless equal.is_a? Array

        path_value = value.split('.')
        path_value.delete_at(0)

        count = 0
        path_value.each do |p|
          if compare_values.is_a? Array
            values = []
            compare_values.each { |v| values << v[p] }
            compare_values = values
          elsif compare_values.is_a? Hash and compare_values[p] != nil
            compare_values = compare_values[p]
          else
            compare_values = nil
            break
          end
          count += 1
        end

        if compare_values.is_a? Array
          found = 0

          compare_values.each { |v| found += 1 if equal.include?(v) }

          if comparaison == :if and found == 0
            return false
          elsif comparaison == :unless and found > 0
            return false
          end
        else
          return false if comparaison == :if and not equal.include?(compare_values)
          return false if comparaison == :unless and equal.include?(compare_values)
        end
      end
    end

    return true
  end

  def check_mixed_conditions(hash, if_conditions, unless_conditions)
    valid = true

    valid = check_conditions(hash, if_conditions, :if) if if_conditions
    valid = check_conditions(hash, unless_conditions, :unless) if valid and unless_conditions

    return valid
  end

  def convert_to_array(value)
    value.is_a?(Array) ? value : [value]
  end

  def convert_to_hash_tree(value)
    if value.is_a? HashTree
      value
    elsif value.is_a? Array
      value.map{ |v| HashTree.new(v) }
    else
      HashTree.new(value)
    end
  end

  def in_scope?(target, scope)
    not scope or "^#{scope}".include? "^#{target}"
  end

  def merge_children(hash, other_hash)
    other_hash = other_hash.get if other_hash.is_a? HashTree

    if other_hash
      other_hash.each do |key, value|
        value = merge_children(hash[key], other_hash[key]) if hash[key] and value.is_a? Hash

        hash[key] = value
      end
    end

    return hash
  end

  def set_children(root, path, value, options={})
    path = path.split('.')

    selection = path[0]

    setted = false

    if path.length > 1
      children = path.drop(1).join('.')

      root[selection] = {} if not root[selection] or (not root[selection].is_a? Hash and not root[selection].is_a? Array)

      if root[selection].is_a? Array
        root[selection].each_with_index do |item, index|
          set_children_node(root[selection][index], path, children, value, options) if item.is_a? Hash
        end
      else
        set_children_node(root[selection], path, children, value, options)
      end
    else
      root[selection] = value if check_mixed_conditions(root, options[:if], options[:unless])
    end
  end

  def set_children_node(hash, path, children, value, options)
    if options[:remove_leaf] and path.length == 2
      if hash[children].is_a? Array
        hash[children].delete_if{ |i| check_mixed_conditions(i, options[:if], options[:unless]) }
        hash.delete(children) if hash[children].empty?
      else
        hash.delete(children) if check_mixed_conditions(hash[children], options[:if], options[:unless])
      end
    else
      set_children(hash, children, value, options)
    end
  end

  def method_missing(m, *args, &block)
    if exists?(m.to_s)
      return get(m.to_s)
    else
      return nil
      #raise "DIG : The method #{m} doesn't exist in HashTree"
    end
  end
end
