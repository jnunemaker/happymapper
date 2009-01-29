module HappyMapper
  class Item
    attr_accessor :name, :type, :tag, :options, :namespace
    
    Types = [String, Float, Time, Date, DateTime, Integer, Boolean]
    
    # options:
    #   :deep   =>  Boolean False to only parse element's children, True to include
    #               grandchildren and all others down the chain (// in expath)
    #   :single =>  Boolean False if object should be collection, True for single object
    def initialize(name, type, o={})
      self.name = name.to_s
      self.type = type
      self.tag = o.delete(:tag) || name.to_s
      self.options = {
        :single => false, 
        :deep   => false,
      }.merge(o)
      
      @xml_type = self.class.to_s.split('::').last.downcase
    end
        
    def from_xml_node(node)
      if primitive?
        value_from_xml_node(node) do |value_before_type_cast|
          typecast(value_before_type_cast)
        end
      else
        type.parse(node, options)
      end
    end
    
    def xpath
      xpath  = ''
      xpath += './/' if options[:deep]
      xpath += namespace if namespace
      xpath += tag
      # puts "xpath: #{xpath}"
      xpath
    end
    
    def primitive?
      Types.include?(type)
    end
    
    def element?
      @xml_type == 'element'
    end
    
    def attribute?
      !element?
    end
    
    def method_name
      @method_name ||= name.tr('-', '_')
    end
    
    def typecast(value)
      return value if value.kind_of?(type) || value.nil?
      begin        
        if    type == String    then value.to_s
        elsif type == Float     then value.to_f
        elsif type == Time      then Time.parse(value.to_s)
        elsif type == Date      then Date.parse(value.to_s)
        elsif type == DateTime  then DateTime.parse(value.to_s)
        elsif type == Boolean   then ['true', 't', '1'].include?(value.to_s.downcase)
        elsif type == Integer
          # ganked from datamapper
          value_to_i = value.to_i
          if value_to_i == 0 && value != '0'
            value_to_s = value.to_s
            begin
              Integer(value_to_s =~ /^(\d+)/ ? $1 : value_to_s)
            rescue ArgumentError
              nil
            end
          else
            value_to_i
          end
        else
          value
        end
      rescue
        value
      end
    end
    
    private
      def value_from_xml_node(node)
        if element?
          result = node.find_first(xpath)
          # puts "vfxn: #{xpath} #{result.inspect}"
          if result
            value = yield(result.content)
            if options[:attributes].is_a?(Hash)
              result.attributes.each do |xml_attribute|
                if attribute_options = options[:attributes][xml_attribute.name.to_sym]
                  attribute_value = Attribute.new(xml_attribute.name.to_sym, *attribute_options).from_xml_node(result)
                  result.instance_eval <<-EOV
                    def value.#{xml_attribute.name}
                      #{attribute_value.inspect}
                    end
                  EOV
                end
              end
            end
            value
          else
            nil
          end
        else
          yield(node[tag])
        end
      end
  end
end