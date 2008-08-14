require File.dirname(__FILE__) + '/spec_helper.rb'

class Post
  include HappyMapper
  
  attribute :href, String
  attribute :hash, String
  attribute :description, String
  attribute :tag, String
  attribute :time, Time
  attribute :others, Integer
  attribute :extended, String
end

class User
  include HappyMapper
  
  element :id, Integer
  element :name, String
  element :screen_name, String
  element :location, String
  element :description, String
  element :profile_image_url, String
  element :url, String
  element :protected, Boolean
  element :followers_count, Integer
end

class Status
  include HappyMapper
  
  element :id, Integer
  element :text, String
	element :created_at, Time
	element :source, String
	element :truncated, Boolean
	element :in_reply_to_status_id, Integer
	element :in_reply_to_user_id, Integer
	element :favorited, Boolean
	element :user, User
end

describe HappyMapper do
  
  describe "being included into another class" do
    class Foo; include HappyMapper end
    
    it "should set @attributes to a hash" do
      Foo.instance_variable_get("@attributes").should == {}
    end
    
    it "should set @elements to a hash" do
      Foo.instance_variable_get("@elements").should == {}
    end
    
    it "should provide #attribute" do
      Foo.should respond_to(:attribute)
    end
    
    it "should provide #attributes" do
      Foo.should respond_to(:attributes)
    end
    
    it "should provide #element" do
      Foo.should respond_to(:element)
    end
    
    it "should provide #elements" do
      Foo.should respond_to(:elements)
    end
    
    it "should default tag_name to class" do
      Foo.get_tag_name.should == 'foo'
    end
    
    it "should allow setting tag_name" do
      Foo.tag_name('FooBar')
      Foo.get_tag_name.should == 'FooBar'
    end
    
    it "should provide #parse" do
      Foo.should respond_to(:parse)
    end
  end
  
  describe "#attributes" do
    it "should only return attributes for the current class" do
      Post.attributes.size.should == 7
      Status.attributes.size.should == 0
    end
  end
  
  describe "#elements" do
    it "should only return elements for the current class" do
      Post.elements.size.should == 0
      Status.elements.size.should == 9
    end
  end
  
  describe "#parse (with attribute heavy xml)" do
    before do
      @posts = Post.parse(File.read(File.dirname(__FILE__) + '/fixtures/posts.xml'))
    end
    
    it "should get the correct number of elements" do
      @posts.size.should == 20
    end
    
    it "should properly assign attributes" do
      first = @posts.first
      first.href.should == 'http://roxml.rubyforge.org/'
      first.hash.should == '19bba2ab667be03a19f67fb67dc56917'
      first.description.should == 'ROXML - Ruby Object to XML Mapping Library'
      first.tag.should == 'ruby xml gems mapping'
      first.time.should == Time.utc(2008, 8, 9, 5, 24, 20)
      first.others.should == 56
      first.extended.should == 'ROXML is a Ruby library designed to make it easier for Ruby developers to work with XML. Using simple annotations, it enables Ruby classes to be custom-mapped to XML. ROXML takes care of the marshalling and unmarshalling of mapped attributes so that developers can focus on building first-class Ruby classes.'
    end
  end
  
  describe "#parse (with element heavy xml)" do
    before do
      @statuses = Status.parse(File.read(File.dirname(__FILE__) + '/fixtures/statuses.xml'))
    end
    
    it "should get the correct number of elements" do
      @statuses.size.should == 20
    end
    
    it "should properly assign attributes" do
      first = @statuses.first
      first.id.should == 882281424
      first.created_at.should == Time.mktime(2008, 8, 9, 1, 38, 12)
      first.source.should == 'web'
      first.truncated.should == false
      first.in_reply_to_status_id.should == 1234
      first.in_reply_to_user_id.should == 12345
      first.favorited.should == false
      first.user.id.should == 4243
      first.user.name.should == 'John Nunemaker'
      first.user.screen_name.should == 'jnunemaker'
      first.user.location.should == 'Mishawaka, IN, US'
      first.user.description.should == 'Loves his wife, ruby, notre dame football and iu basketball'
      first.user.profile_image_url.should == 'http://s3.amazonaws.com/twitter_production/profile_images/53781608/Photo_75_normal.jpg'
      first.user.url.should == 'http://addictedtonew.com'
      first.user.protected.should == false
      first.user.followers_count.should == 486
    end
  end
end