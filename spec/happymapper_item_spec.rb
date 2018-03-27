require 'spec_helper'

module Foo
  class Bar; end
end

describe HappyMapper::Item do

  describe "new instance" do
    let(:item) { HappyMapper::Item.new(:foo, String, :tag => 'foobar') }

    it "should accept a name" do
      expect(item.name).to eq 'foo'
    end

    it 'should accept a type' do
      expect(item.type).to eq String
    end

    it 'should accept :tag as an option' do
      expect(item.tag).to eq 'foobar'
    end

    it "should have a method_name" do
      expect(item.method_name).to eq 'foo'
    end
  end

  describe "#constant" do
    it "should just use type if constant" do
      item = HappyMapper::Item.new(:foo, String)
      expect(item.constant).to eq String
    end

    it "should convert string type to constant" do
      item = HappyMapper::Item.new(:foo, 'String')
      expect(item.constant).to eq String
    end

    it "should convert string with :: to constant" do
      item = HappyMapper::Item.new(:foo, 'Foo::Bar')
      expect(item.constant).to eq Foo::Bar
    end
  end

  describe "#method_name" do
    it "should convert dashes to underscores" do
      item = HappyMapper::Item.new(:'foo-bar', String, :tag => 'foobar')
      expect(item.method_name).to eq 'foo_bar'
    end
  end

  describe "#xpath" do
    it "should default to tag" do
      item = HappyMapper::Item.new(:foo, String, :tag => 'foobar')
      expect(item.xpath).to eq 'foobar'
    end

    it "should prepend with .// if options[:deep] true" do
      item = HappyMapper::Item.new(:foo, String, :tag => 'foobar', :deep => true)
      expect(item.xpath).to eq './/foobar'
    end

    it "should prepend namespace if namespace exists" do
      item = HappyMapper::Item.new(:foo, String, :tag => 'foobar')
      item.namespace = 'http://example.com'
      expect(item.xpath).to eq 'happymapper:foobar'
    end
  end

  describe "typecasting" do
    it "should work with Strings" do
      item = HappyMapper::Item.new(:foo, String)
      [21, '21'].each do |a|
        expect(item.typecast(a)).to eq '21'
      end
    end

    it "should work with Integers" do
      item = HappyMapper::Item.new(:foo, Integer)
      [21, 21.0, '21'].each do |a|
        expect(item.typecast(a)).to eq 21
      end
    end

    it "should work with Floats" do
      item = HappyMapper::Item.new(:foo, Float)
      [21, 21.0, '21'].each do |a|
        expect(item.typecast(a)).to eq 21.0
      end
    end

    it "should work with Times" do
      item = HappyMapper::Item.new(:foo, Time)
      expect(item.typecast('2000-01-01 01:01:01.123456')).to eq Time.local(2000, 1, 1, 1, 1, 1, 123456)
    end

    it "should work with Dates" do
      item = HappyMapper::Item.new(:foo, Date)
      expect(item.typecast('2000-01-01')).to eq Date.new(2000, 1, 1)
    end

    it "should work with DateTimes" do
      item = HappyMapper::Item.new(:foo, DateTime)
      expect(item.typecast('2000-01-01 00:00:00')).to eq DateTime.new(2000, 1, 1, 0, 0, 0)
    end

    it "should work with Boolean" do
      item = HappyMapper::Item.new(:foo, Boolean)
      expect(item.typecast('false')).to eq false
    end
  end
end
