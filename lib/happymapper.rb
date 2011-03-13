require 'rubygems'
require 'date'
require 'time'
require 'xml'

class Boolean; end

module HappyMapper

  DEFAULT_NS = "happymapper"

  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
    base.instance_variable_set("@registered_namespaces", {})
    
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

    def after_parse_callbacks
      @after_parse_callbacks ||= []
    end

    def after_parse(&block)
      after_parse_callbacks.push(block)
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
    
    def register_namespace(namespace, ns)
      @registered_namespaces.merge!(namespace => ns)
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

        obj.class.after_parse_callbacks.each { |callback| callback.call(obj) }

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

  #
  # Create an xml representation of the specified class based on defined
  # HappyMapper elements and attributes. The method is defined in a way
  # that it can be called recursively by classes that are also HappyMapper
  # classes, allowg for the composition of classes.
  #
  def to_xml(node = nil, default_namespace = nil)

    
    #
    # If to_xml has been called without a Node (and namespace) that
    # means we are going to return an xml document. When it has been called 
    # with a Node instance that means this method is being called recursively
    # and will return the node with elements defined here attached.
    #
    unless node
      write_out_to_xml = true
      node = XML::Node.new(self.class.tag_name)
    end

    #
    # Create a tag that uses the tag name of the class that has no contents
    # but has the specified namespace or uses the default namespace
    #
    child_node = XML::Node.new(self.class.tag_name)
    
    #
    # For all the registered namespaces, add them to node
    #
    if self.class.instance_variable_get('@registered_namespaces')

      root_node = node

      while root_node.parent?
        root_node = root_node.parent
      end
      
      self.class.instance_variable_get('@registered_namespaces').each_pair do |prefix,href|
        XML::Namespace.new(child_node,prefix,href)
        XML::Namespace.new(root_node,prefix,href) unless root_node.namespaces.find_by_prefix(prefix)
      end
    end

    #
    # When there is a defined namespace or one passed to the #to_xml method
    # then create and set that namespace as the default namespace for the node
    #
    tag_namespace = child_node.namespaces.find_by_prefix(self.class.namespace) || default_namespace
    
    if tag_namespace
      child_node.namespaces.namespace = tag_namespace
      #XML::Namespace.new(child_node,tag_namespace,self.class.instance_variable_get('@registered_namespaces')[tag_namespace])
      #child_node.namespaces.default_prefix = tag_namespace
    end


    #
    # Add all the attribute tags to the child node with their namespace or the
    # the default namespace.
    #
    self.class.attributes.each do |attribute|
      attribute_namespace = child_node.namespaces.find_by_prefix(attribute.options[:namespace]) || default_namespace
      # TODO: we need saving attribute functionality as well that is similar to elements
      child_node[ "#{attribute_namespace ? "#{attribute_namespace.prefix}:" : ""}#{attribute.tag}" ] = send(attribute.method_name)
    end

    self.class.elements.each do |element|

      tag = element.tag || element.name

      value = send(element.name)

      #
      # If the element defines an on_save lambda/proc then we will call that
      # operation on the specified value. This allows for operations to be 
      # performed to convert the value to a specific value to be saved to the xml.
      #
      if element.options[:on_save]
        value = element.options[:on_save].call(value)
      end

      #
      # Normally a nil value would be ignored, however if specified then
      # an empty element will be written to the xml
      #
      if value.nil? && element.options[:state_when_nil]
        item_namespace = child_node.namespaces.find_by_prefix(element.options[:namespace]) || child_node.namespaces.find_by_prefix(self.class.namespace) || default_namespace
        
        child_node << XML::Node.new(tag,nil,item_namespace)
      end

      #
      # To allow for us to treat both groups of items and singular items
      # equally we wrap the value and treat it as an array.
      #
      if value.nil?
        values = []
      elsif value.respond_to?(:to_ary) && !element.options[:single]
        values = value.to_ary
      else
        values = [value]
      end


      values.each do |item|

        if item.is_a?(HappyMapper)

          #
          # Other items are convertable to xml through the xml builder
          # process should have their contents retrieved and attached
          # to the builder structure
          #
          item.to_xml(child_node,child_node.namespaces.find_by_prefix(element.options[:namespace]))

        elsif item

          item_namespace = child_node.namespaces.find_by_prefix(element.options[:namespace]) || child_node.namespaces.find_by_prefix(self.class.namespace) || default_namespace
          
          #
          # When a value exists we should append the value for the tag
          #
          child_node << XML::Node.new(tag,item.to_s,item_namespace)

        else
          
          item_namespace = child_node.namespaces.find_by_prefix(element.options[:namespace]) || child_node.namespaces.find_by_prefix(self.class.namespace) || default_namespace
          
          #
          # Normally a nil value would be ignored, however if specified then
          # an empty element will be written to the xml
          #
          child_node << XML.Node.new(tag,nil,item_namespace) if element.options[:state_when_nil]

        end

      end

    end



    if write_out_to_xml
      document = XML::Document.new
      document.root = child_node
      document.to_s
    else
      node << child_node
    end


  end


end

require File.dirname(__FILE__) + '/happymapper/item'
require File.dirname(__FILE__) + '/happymapper/attribute'
require File.dirname(__FILE__) + '/happymapper/element'
