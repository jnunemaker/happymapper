require 'date'
require 'time'
require 'xml'

class Boolean; end

module HappyMapper

  DEFAULT_NS = "happymapper"

  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
    base.extend ClassMethods
  end
  
  module ClassMethods
    def attribute(name, type, options={})
      attribute = Attribute.new(name, type, options)
      @attributes[to_s] ||= []
      @attributes[to_s] << attribute
      attr_accessor attribute.method_name.intern
    end
    
    def attributes
      @attributes[to_s] || []
    end
    
    def element(name, type, options={})
      element = Element.new(name, type, options)
      @elements[to_s] ||= []
      @elements[to_s] << element
      attr_accessor element.method_name.intern
    end

    def content(name)
      @content = name
      attr_accessor name
    end
    
    def elements
      @elements[to_s] || []
    end
    
    def has_one(name, type, options={})
      element name, type, {:single => true}.merge(options)
    end
    
    def has_many(name, type, options={})
      element name, type, {:single => false}.merge(options)
    end

    # Specify a namespace if a node and all its children are all namespaced
    # elements. This is simpler than passing the :namespace option to each
    # defined element.
    def namespace(namespace = nil)
      @namespace = namespace if namespace
      @namespace
    end

    def tag(new_tag_name)
      @tag_name = new_tag_name.to_s
    end
    
    def tag_name
      @tag_name ||= to_s.split('::')[-1].downcase
    end
        
    def parse(xml, options = {})
      if xml.is_a?(XML::Node)
        node = xml
      else
        if xml.is_a?(XML::Document)
          node = xml.root
        else
          node = XML::Parser.string(xml).parse.root
        end

        root = node.name == tag_name
      end

      namespace = @namespace || (node.namespaces && node.namespaces.default)
      namespace = "#{DEFAULT_NS}:#{namespace}" if namespace

      xpath = root ? '/' : './/'
      xpath += "#{DEFAULT_NS}:" if namespace
      xpath += tag_name
      
      nodes = node.find(xpath, Array(namespace))
      collection = nodes.collect do |n|
        obj = new
        
        attributes.each do |attr| 
          obj.send("#{attr.method_name}=", 
                    attr.from_xml_node(n, namespace))
        end
        
        elements.each do |elem|
          obj.send("#{elem.method_name}=", 
                    elem.from_xml_node(n, namespace))
        end

        obj.send("#{@content}=", n.content) if @content
        
        obj
      end

      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil

      if options[:single] || root
        collection.first
      else
        collection
      end
    end
  end
end

require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
