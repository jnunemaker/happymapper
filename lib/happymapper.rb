$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'date'
require 'time'
require 'rubygems'
gem 'libxml-ruby', '>= 0.8.3'
require 'xml'

class Boolean; end

module HappyMapper
  
  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
    base.extend ClassMethods
  end
  
  module ClassMethods
    def attribute(name, type)
      attribute = Attribute.new(name, type)
      @attributes[to_s] ||= []
      @attributes[to_s] << attribute
      create_accessor(attribute.name)
    end
    
    def attributes
      @attributes[to_s] || []
    end
    
    def element(name, type)
      element = Element.new(name, type)
      @elements[to_s] ||= []
      @elements[to_s] << element
      create_accessor(element.name)
    end
    
    def elements
      @elements[to_s] || []
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
    
    def parse(xml)
      parser = XML::Parser.new
      parser.string = xml
      doc = parser.parse
      collection = []
      doc.find(get_tag_name).each do |el|
        obj = new
        # TODO: reading value from xml should move to Item
        attributes.each { |a| obj.send("#{a.name}=", a.typecast(el.attributes[a.xml_name])) }
        elements.each   { |e| obj.send("#{e.name}=", e.typecast(el.find(e.xml_name).first.content)) }
        collection << obj
      end
      collection
    end
  end
  
  class Item
    attr_accessor :type, :xml_name
    attr_reader :name
    
    def initialize(name, type, o={})
      self.name, self.type, self.xml_name = name, type, o.delete(:xml_name) || name.to_s
      @options = {}.merge(o)
      @xml_type = self.class.to_s.split('::').last.downcase
    end
    
    def name=(new_name)
      @name = new_name.to_s
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
    
    def element?
      @xml_type == 'element'
    end
    
    def attribute?
      @xml_type == 'attribute'
    end
  end
  
  class Element < Item; end
  class Attribute < Item; end
end