directory = File.dirname(__FILE__)
$:.unshift(directory) unless $:.include?(directory) || $:.include?(File.expand_path(directory))

require 'date'
require 'time'
require 'rubygems'
gem 'libxml-ruby', '>= 0.8.3'
require 'xml'
require 'happymapper/libxml_ext/libxml_helper'

class Boolean; end

module HappyMapper
  
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
      create_accessor(attribute.name)
    end
    
    def attributes
      @attributes[to_s] || []
    end
    
    def element(name, type, options={})
      element = Element.new(name, type, options)
      @elements[to_s] ||= []
      @elements[to_s] << element
      create_accessor(element.name)
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
    
    def tag_name(new_tag_name)
      @tag_name = new_tag_name.to_s
    end
    
    def get_tag_name
      @tag_name ||= to_s.downcase
    end
    
    def create_getter(name)
      class_eval <<-EOS, __FILE__, __LINE__
        def #{name}
          @#{name}
        end
      EOS
    end
    
    def create_setter(name)
      class_eval <<-EOS, __FILE__, __LINE__
        def #{name}=(value)
          @#{name} = value
        end
      EOS
    end
    
    def create_accessor(name)
      create_getter(name)
      create_setter(name)
    end
    
    def parse(xml, o={})
      options = {
        :single => false,
        :use_default_namespace => false,
      }.merge(o)
      
      doc = xml.is_a?(LibXML::XML::Node) ? xml : xml.to_libxml_doc
      
      nodes = if options[:use_default_namespace]
        node = doc.respond_to?(:root) ? doc.root : doc
        namespace = "default_ns:"
        node.register_default_namespace(namespace.chop)
        node.find("#{namespace}#{get_tag_name}")
      else
        doc.find(get_tag_name)
      end
      
      collection = nodes.inject([]) do |acc, el|
        obj = new
        attributes.each { |attr| obj.send("#{attr.name}=", attr.from_xml_node(el)) }
        elements.each   { |elem| obj.send("#{elem.name}=", elem.from_xml_node(el, namespace)) }
        acc << obj
      end
      
      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil
      GC.start
      
      options[:single] ? collection.first : collection
    end
  end
  
  class Item
    attr_accessor :type, :xml_name, :options
    attr_reader :name
    
    Types = [String, Float, Time, Date, DateTime, Integer, Boolean]
    
    def initialize(name, type, o={})
      self.name, self.type, self.xml_name = name, type, o.delete(:xml_name) || name.to_s
      self.options = {:single => false, :deep => false}.merge(o)
      @xml_type = self.class.to_s.split('::').last.downcase
    end
    
    def name=(new_name)
      @name = new_name.to_s
    end
        
    def from_xml_node(node, namespace=nil)
      if primitive?
        typecast(value_from_xml_node(node, namespace))
      else
        use_default_namespace = !namespace.nil?
        type.parse(node, options.merge(:use_default_namespace => use_default_namespace))
      end
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
    
    private
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
      
      def value_from_xml_node(node, namespace=nil)        
        node.register_default_namespace(namespace.chop) if namespace
        
        if element?
          depth = options[:deep] ? '//' : ''
          result = node.find_first("#{depth}#{namespace}#{xml_name}")
          result ? result.content : nil
        else
          node[xml_name]
        end
      end
  end
  
  class Element < Item; end
  class Attribute < Item; end
end