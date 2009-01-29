dir = File.dirname(__FILE__)
$:.unshift(dir) unless $:.include?(dir) || $:.include?(File.expand_path(dir))

require 'date'
require 'time'
require 'rubygems'

gem 'libxml-ruby', '>= 0.9.7'
require 'xml'
require 'libxml_ext/libxml_helper'


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

    # Options:
    #   :root => Boolean, true means this is xml root
    def tag(new_tag_name, o={})
      options = {:root => false}.merge(o)
      @root = options.delete(:root)
      @tag_name = new_tag_name.to_s
    end
    
    def get_tag_name
      @tag_name ||= begin
        to_s.split('::')[-1].downcase
      end
    end
        
    def is_root?
      @root
    end
    
    def parse(xml, o={})      
      xpath, collection, options = '', [], {:single => false}.merge(o)

      # reset the namespace if it was set to the default
      # this is necessary when using the same object mapping instance for
      # docs w/ and w/o default namespaces
      @namespace = nil if @namespace == DEFAULT_NS

      if xml.is_a?(XML::Node)
        node = xml
      elsif xml.is_a?(XML::Document)
        node = xml.root
      else
        node = xml.to_libxml_doc.root
      end

      # This is the entry point into the parsing pipeline, so the default
      # namespace prefix registered here will propagate down
      namespaces = node.namespaces
      if namespaces && namespaces.default
        namespaces.default_prefix = DEFAULT_NS
        @namespace ||= DEFAULT_NS
      end

      xpath += is_root? ? '/' : './/'
      xpath += "#{namespace}:" if namespace
      xpath += get_tag_name
      # puts "parse: #{xpath}"
      
      nodes = node.find(xpath)
      nodes.each do |n|
        obj = new
        
        attributes.each do |attr| 
          obj.send("#{attr.method_name}=", 
                    attr.from_xml_node(n))
        end
        
        elements.each do |elem|
          elem.namespace ||= namespace
          obj.send("#{elem.method_name}=", 
                    elem.from_xml_node(n))
        end
        collection << obj
      end

      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil
      GC.start

      options[:single] || is_root? ? collection.first : collection
    end
  end
end

require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
