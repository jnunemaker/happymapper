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
    
    def tag(new_tag_name)
      @tag_name = new_tag_name.to_s
    end
    
    def get_tag_name
      @tag_name ||= to_s.downcase
    end
    
    def parse(xml, o={})
      options = {
        :single => false,
        :use_default_namespace => false,
      }.merge(o)
      
      namespace = "default_ns:" if options[:use_default_namespace]
      doc = xml.is_a?(LibXML::XML::Node) ? xml : xml.to_libxml_doc
      
      nodes = if namespace
        node = doc.respond_to?(:root) ? doc.root : doc
        node.register_default_namespace(namespace.chop)
        node.find("#{namespace}#{get_tag_name}")
      else
        doc.find("//#{get_tag_name}")
      end

      nodes = if namespace
        node = doc.respond_to?(:root) ? doc.root : doc
        node.register_default_namespace(namespace.chop)
        node.find("#{namespace}#{get_tag_name}")
      else
        nested = '.' unless doc.respond_to?(:root)
        path = "#{nested}//#{get_tag_name}"
        doc.find(path)
      end

      collection = create_collection(nodes, namespace)
      
      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil
      GC.start
      
      options[:single] ? collection.first : collection
    end
    
    private
      def create_collection(nodes, namespace=nil)
        nodes.inject([]) do |acc, el|
          obj = new
          attributes.each { |attr| obj.send("#{normalize_name attr.name}=", attr.from_xml_node(el)) }
          elements.each   { |elem| obj.send("#{normalize_name elem.name}=", elem.from_xml_node(el, namespace)) }
          acc << obj
        end
      end
      
      def create_getter(name)
        name = normalize_name(name)

        class_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            @#{name}
          end
        EOS
      end

      def create_setter(name)
        name = normalize_name(name)

        class_eval <<-EOS, __FILE__, __LINE__
          def #{name}=(value)
            @#{name} = value
          end
        EOS
      end

      def create_accessor(name)
        name = normalize_name(name)

        create_getter(name)
        create_setter(name)
      end

      def normalize_name(name)
        name.gsub('-', '_')
      end
  end
end

require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
