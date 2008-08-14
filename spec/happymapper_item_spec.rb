require File.dirname(__FILE__) + '/spec_helper.rb'

describe HappyMapper::Item do
  
  describe "new instance" do
    before do
      @attr = HappyMapper::Item.new(:foo, String, :xml_name => 'foobar')
    end
    
    it "should accept a name" do
      @attr.name.should == 'foo'
    end
    
    it 'should accept a type' do
      @attr.type.should == String
    end
    
    it 'should accept :xml_name as an option' do
      @attr.xml_name.should == 'foobar'
    end
    
    it 'should provide #name' do
      @attr.should respond_to(:name)
    end
    
    it 'should provide #type' do
      @attr.should respond_to(:type)
    end
  end
  
  describe "typecasting" do
    it "should work with Strings" do
      attribute = HappyMapper::Item.new(:foo, String)
      [21, '21'].each do |a|
        attribute.typecast(a).should == '21'
      end
    end
    
    it "should work with Integers" do
      attribute = HappyMapper::Item.new(:foo, Integer)
      [21, 21.0, '21'].each do |a|
        attribute.typecast(a).should == 21
      end
    end
    
    it "should work with Floats" do
      attribute = HappyMapper::Item.new(:foo, Float)
      [21, 21.0, '21'].each do |a|
        attribute.typecast(a).should == 21.0
      end
    end
    
    it "should work with Times" do
      attribute = HappyMapper::Item.new(:foo, Time)
      attribute.typecast('2000-01-01 01:01:01.123456').should == Time.local(2000, 1, 1, 1, 1, 1, 123456)
    end
    
    it "should work with Dates" do
      attribute = HappyMapper::Item.new(:foo, Date)
      attribute.typecast('2000-01-01').should == Date.new(2000, 1, 1)
    end
    
    it "should work with DateTimes" do
      attribute = HappyMapper::Item.new(:foo, DateTime)
      attribute.typecast('2000-01-01 00:00:00').should == DateTime.new(2000, 1, 1, 0, 0, 0)
    end
    
    it "should work with Boolean" do
      attribute = HappyMapper::Item.new(:foo, Boolean)
      attribute.typecast('false').should == false
    end
  end
end