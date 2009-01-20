require File.dirname(__FILE__) + '/spec_helper.rb'

class Place
  include HappyMapper

  element :name, String
end

class Radar
  include HappyMapper
  has_many :places, Place
end

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
	has_one :user, User
end

class CurrentWeather
  include HappyMapper
  tag 'aws:ob'
  element :temperature, Integer, :tag => 'aws:temp'
  element :feels_like, Integer, :tag => 'aws:feels-like'
  element :current_condition, String, :tag => 'aws:current-condition', :attributes => {:icon => String}
end

class Address
  include HappyMapper
  
  element :street, String
  element :postcode, String
  element :housenumber, String
  element :city, String
  element :country, String
end

module PITA
  class Item
    include HappyMapper
    
    tag 'Item' # if you put class in module you need tag
    element :asin, String, :tag => 'ASIN'
    element :detail_page_url, String, :tag => 'DetailPageURL'
    element :manufacturer, String, :tag => 'Manufacturer', :deep => true
  end

  class Items
    include HappyMapper
    
    tag 'Items' # if you put class in module you need tag
    element :total_results, Integer, :tag => 'TotalResults'
    element :total_pages, Integer, :tag => 'TotalPages'
    has_many :items, Item
  end
end

module GitHub
  class Commit
    include HappyMapper

    tag "commit"

    element :url, String
    element :tree, String
    element :message, String
    element :id, String
    element :'committed-date', Date
  end
end

describe HappyMapper do
  
  describe "being included into another class" do
    before do
      Foo.instance_variable_set("@attributes", {})
      Foo.instance_variable_set("@elements", {})
    end
    class Foo; include HappyMapper end
    
    it "should set attributes to an array" do
      Foo.attributes.should == []
    end
    
    it "should set @elements to a hash" do
      Foo.elements.should == []
    end
    
    it "should allow adding an attribute" do
      lambda {
        Foo.attribute :name, String
      }.should change(Foo, :attributes)
    end
    
    it "should allow adding an attribute containing a dash" do
      lambda {
        Foo.attribute :'bar-baz', String
      }.should change(Foo, :attributes)
    end

    it "should be able to get all attributes in array" do
      Foo.attribute :name, String
      Foo.attributes.size.should == 1
    end
    
    it "should allow adding an element" do
      lambda {
        Foo.element :name, String
      }.should change(Foo, :elements)
    end

    it "should allow adding an element containing a dash" do
      lambda {
        Foo.element :'bar-baz', String
      }.should change(Foo, :elements)

    end
    
    it "should be able to get all elements in array" do
      Foo.element(:name, String)
      Foo.elements.size.should == 1
    end
    
    it "should allow has one association" do
      Foo.has_one(:user, User)
      element = Foo.elements.first
      element.name.should == 'user'
      element.type.should == User
      element.options[:single] = true
    end
    
    it "should allow has many association" do
      Foo.has_many(:users, User)
      element = Foo.elements.first
      element.name.should == 'users'
      element.type.should == User
      element.options[:single] = false
    end
    
    it "should default tag name to class" do
      Foo.get_tag_name.should == 'foo'
    end
    
    it "should allow setting tag name" do
      Foo.tag('FooBar')
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
  
  describe "#parse (with xml attributes mapping to ruby attributes)" do
    before do
      @posts = Post.parse(File.read(File.dirname(__FILE__) + '/fixtures/posts.xml'))
    end
    
    it "should get the correct number of elements" do
      @posts.size.should == 20
    end
    
    it "should properly create objects" do
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
  
  describe "#parse (with xml elements mapping to ruby attributes)" do
    before do
      @statuses = Status.parse(File.read(File.dirname(__FILE__) + '/fixtures/statuses.xml'))
    end
    
    it "should get the correct number of elements" do
      @statuses.size.should == 20
    end
    
    it "should properly create objects" do
      first = @statuses.first
      first.id.should == 882281424
      first.created_at.should == Time.utc(2008, 8, 9, 5, 38, 12)
      first.source.should == 'web'
      first.truncated.should be_false
      first.in_reply_to_status_id.should == 1234
      first.in_reply_to_user_id.should == 12345
      first.favorited.should be_false
      first.user.id.should == 4243
      first.user.name.should == 'John Nunemaker'
      first.user.screen_name.should == 'jnunemaker'
      first.user.location.should == 'Mishawaka, IN, US'
      first.user.description.should == 'Loves his wife, ruby, notre dame football and iu basketball'
      first.user.profile_image_url.should == 'http://s3.amazonaws.com/twitter_production/profile_images/53781608/Photo_75_normal.jpg'
      first.user.url.should == 'http://addictedtonew.com'
      first.user.protected.should be_false
      first.user.followers_count.should == 486
    end
  end

  describe "#parse (with xml containing the desired element as root node)" do
    before do
      file_contents = File.read(File.dirname(__FILE__) + '/fixtures/address.xml')
      @address = Address.parse(file_contents, :single => true)
    end

    it "should properly create objects" do
      @address.street.should == 'Milchstrasse'
      @address.postcode.should == '26131'
      @address.housenumber.should == '23'
      @address.city.should == 'Oldenburg'
      @address.country.should == 'Germany'
    end
  end
  
  # TODO: someone please get xml with namespaces working, kthxbai
  describe "#parse (with xml that has namespace)" do
    before do
      file_contents = File.read(File.dirname(__FILE__) + '/fixtures/pita.xml')
      @items = PITA::Items.parse(file_contents, :single => true, :use_default_namespace => true)
    end
    
    it "should properly create objects" do
      @items.total_results.should == 22
      @items.total_pages.should == 3
      first  = @items.items[0]
      second = @items.items[1]
      first.asin.should == '0321480791'
      first.detail_page_url.should == 'http://www.amazon.com/gp/redirect.html%3FASIN=0321480791%26tag=ws%26lcode=xm2%26cID=2025%26ccmID=165953%26location=/o/ASIN/0321480791%253FSubscriptionId=dontbeaswoosh'
      first.manufacturer.should == 'Addison-Wesley Professional'
      second.asin.should == '047022388X'
      second.manufacturer.should == 'Wrox'
    end
  end

  describe "#parse (with xml that has attributes of elements)" do
    before do
      file_contents = File.read(File.dirname(__FILE__) + '/fixtures/current_weather.xml')
      @items = CurrentWeather.parse(file_contents)
    end
    
    it "should properly create objects" do
      @first = @items[0]
      @first.temperature.should == 51
      @first.feels_like.should == 51
      @first.current_condition.should == 'Sunny'
      @first.current_condition.icon.should == 'http://deskwx.weatherbug.com/images/Forecast/icons/cond007.gif'
    end
  end

  describe "#parse (with xml that has nested elements)" do
    before do
      file_contents = File.read(File.dirname(__FILE__) + '/fixtures/radar.xml')
      @radars = Radar.parse(file_contents)
    end

    it "should properly create objects" do
      @first = @radars[0]
      @first.places.size.should == 1
      @first.places[0].name.should == 'Store'
      @second = @radars[1]
      @second.places.size.should == 0
      @third = @radars[2]
      @third.places.size.should == 2
      @third.places[0].name.should == 'Work'
      @third.places[1].name.should == 'Home'
    end
  end

  describe "#parse (with xml that has elements with dashes in them)" do
    before do
      file_contents = File.read(File.dirname(__FILE__) + '/fixtures/commit.xml')
      @commit = GitHub::Commit.parse(file_contents).first
    end

    it "should properly create objects" do
      @commit.message.should == "move commands.rb and helpers.rb into commands/ dir"
      @commit.url.should == "http://github.com/defunkt/github-gem/commit/c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b"
      @commit.id.should == "c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b"
      @commit.committed_date.should == Date.parse("2008-03-02T16:45:41-08:00")
      @commit.tree.should == "28a1a1ca3e663d35ba8bf07d3f1781af71359b76"
    end

  end
end
