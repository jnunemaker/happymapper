require 'spec_helper'
require 'pp'
require 'uri'
require 'support/models'

describe HappyMapper do
  describe "being included into another class" do
    let(:klass) do
      Class.new do
        include HappyMapper

        def self.to_s
          'Foo'
        end
      end
    end

    it "should set attributes to an array" do
      expect(klass.attributes).to eq []
    end

    it "should set @elements to a hash" do
      expect(klass.elements).to eq []
    end

    it "should allow adding an attribute" do
      expect {
        klass.attribute :name, String
      }.to change(klass, :attributes)
    end

    it "should allow adding an attribute containing a dash" do
      expect {
        klass.attribute :'bar-baz', String
      }.to change(klass, :attributes)
    end

    it "should be able to get all attributes in array" do
      klass.attribute :name, String
      expect(klass.attributes.size).to eq 1
    end

    it "should allow adding an element" do
      expect {
        klass.element :name, String
      }.to change(klass, :elements)
    end

    it "should allow adding an element containing a dash" do
      expect {
        klass.element :'bar-baz', String
      }.to change(klass, :elements)
    end

    it "should be able to get all elements in array" do
      klass.element(:name, String)
      expect(klass.elements.size).to eq 1
    end

    it "should allow has one association" do
      klass.has_one(:user, User)
      element = klass.elements.first
      expect(element.name).to eq 'user'
      expect(element.type).to eq User
      expect(element.options[:single]).to eq true
    end

    it "should allow has many association" do
      klass.has_many(:users, User)
      element = klass.elements.first
      expect(element.name).to eq 'users'
      expect(element.type).to eq User
      expect(element.options[:single]).to eq false
    end

    it "has after_parse callbacks" do
      call1 = lambda { |doc| puts doc.inspect }
      call2 = lambda { |doc| puts doc.inspect }
      klass.after_parse(&call1)
      klass.after_parse(&call2)
      expect(klass.after_parse_callbacks).to eq [call1, call2]
    end

    it "should default tag name to lowercase class" do
      expect(klass.tag_name).to eq 'foo'
    end

    it "should default tag name of class in modules to the last constant lowercase" do
      module Bar; class Baz; include HappyMapper; end; end
      expect(Bar::Baz.tag_name).to eq 'baz'
    end

    it "should allow setting tag name" do
      klass.tag('FooBar')
      expect(klass.tag_name).to eq 'FooBar'
    end

    it "should allow setting a namespace" do
      klass.namespace(namespace = "foo")
      expect(klass.namespace).to eq namespace
    end

    it "should provide #parse" do
      expect(klass).to respond_to(:parse)
    end
  end

  describe "#attributes" do
    it "should only return attributes for the current class" do
      expect(Post.attributes.size).to eq 7
      expect(Status.attributes.size).to eq 0
    end
  end

  describe "#elements" do
    it "should only return elements for the current class" do
      expect(Post.elements.size).to eq 0
      expect(Status.elements.size).to eq 10
    end
  end

  describe "running after_parse callbacks" do
    it "works" do
      user = Status.parse(fixture_file('statuses.xml')).first.user
      expect(user.after_parse_called).to eq true
      expect(user.after_parse2_called).to eq true
    end
  end

  it "should parse xml attributes into ruby objects" do
    posts = Post.parse(fixture_file('posts.xml'))
    expect(posts.size).to eq 20

    first = posts.first
    expect(first.href).to eq 'http://roxml.rubyforge.org/'
    expect(first.hash).to eq '19bba2ab667be03a19f67fb67dc56917'
    expect(first.description).to eq 'ROXML - Ruby Object to XML Mapping Library'
    expect(first.tag).to eq 'ruby xml gems mapping'
    expect(first.time).to eq Time.utc(2008, 8, 9, 5, 24, 20)
    expect(first.others).to eq 56
    expect(first.extended).to eq 'ROXML is a Ruby library designed to make it easier for Ruby developers to work with XML. Using simple annotations, it enables Ruby classes to be custom-mapped to XML. ROXML takes care of the marshalling and unmarshalling of mapped attributes so that developers can focus on building first-class Ruby classes.'
  end

  it "should parse xml elements to ruby objects" do
    statuses = Status.parse(fixture_file('statuses.xml'))
    expect(statuses.size).to eq 20

    first = statuses.first
    expect(first.id).to eq 882281424
    expect(first.created_at).to eq Time.utc(2008, 8, 9, 5, 38, 12)
    expect(first.source).to eq 'web'
    expect(first.truncated).to eq false
    expect(first.in_reply_to_status_id).to eq 1234
    expect(first.in_reply_to_user_id).to eq 12345
    expect(first.favorited).to eq false
    expect(first.user.id).to eq 4243
    expect(first.user.name).to eq 'John Nunemaker'
    expect(first.user.screen_name).to eq 'jnunemaker'
    expect(first.user.location).to eq 'Mishawaka, IN, US'
    expect(first.user.description).to eq 'Loves his wife, ruby, notre dame football and iu basketball'
    expect(first.user.profile_image_url).to eq 'http://s3.amazonaws.com/twitter_production/profile_images/53781608/Photo_75_normal.jpg'
    expect(first.user.url).to eq 'http://addictedtonew.com'
    expect(first.user.protected).to eq false
    expect(first.user.followers_count).to eq 486
  end

  it "should parse xml containing the desired element as root node" do
    address = Address.parse(fixture_file('address.xml'), :single => true)
    expect(address.street).to eq 'Milchstrasse'
    expect(address.postcode).to eq '26131'
    expect(address.housenumber).to eq '23'
    expect(address.city).to eq 'Oldenburg'
    expect(address.country).to eq 'Germany'
  end

  it "should parse xml containing a has many relationship with primitive types" do
    address = MultiStreetAddress.parse(fixture_file('multi_street_address.xml'), :single => true)
    expect(address).to_not eq nil
    expect(address.street_address.first).to eq "123 Smith Dr"
    expect(address.street_address.last).to eq "Apt 31"
  end

  it "should parse xml with default namespace (amazon)" do
    file_contents = fixture_file('pita.xml')
    items = PITA::Items.parse(file_contents, :single => true)
    expect(items.total_results).to eq 22
    expect(items.total_pages).to eq 3

    first  = items.items[0]
    second = items.items[1]
    expect(first.asin).to eq '0321480791'
    expect(first.point).to eq '38.5351715088 -121.7948684692'
    expect(first.detail_page_url).to be_a(URI)
    expect(first.detail_page_url.to_s).to eq 'http://www.amazon.com/gp/redirect.html%3FASIN=0321480791%26tag=ws%26lcode=xm2%26cID=2025%26ccmID=165953%26location=/o/ASIN/0321480791%253FSubscriptionId=dontbeaswoosh'
    expect(first.manufacturer).to eq 'Addison-Wesley Professional'
    expect(first.product_group).to eq '<ProductGroup>Book</ProductGroup>'
    expect(second.asin).to eq '047022388X'
    expect(second.manufacturer).to eq 'Wrox'
  end

  it "should parse xml that has attributes of elements" do
    items = CurrentWeather.parse(fixture_file('current_weather.xml'))
    first = items[0]
    expect(first.temperature).to eq 51
    expect(first.feels_like).to eq 51
    expect(first.current_condition).to eq 'Sunny'
    expect(first.current_condition.icon).to eq 'http://deskwx.weatherbug.com/images/Forecast/icons/cond007.gif'
  end

  it "should parse xml with nested elements" do
    radars = Radar.parse(fixture_file('radar.xml'))
    first = radars[0]
    expect(first.places.size).to eq 1
    expect(first.places[0].name).to eq 'Store'

    second = radars[1]
    expect(second.places.size).to eq 0

    third = radars[2]
    expect(third.places.size).to eq 2
    expect(third.places[0].name).to eq 'Work'
    expect(third.places[1].name).to eq 'Home'
  end

  it "should parse xml that has elements with dashes" do
    commit = GitHub::Commit.parse(fixture_file('commit.xml'))
    expect(commit.message).to eq "move commands.rb and helpers.rb into commands/ dir"
    expect(commit.url).to eq "http://github.com/defunkt/github-gem/commit/c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b"
    expect(commit.id).to eq "c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b"
    expect(commit.committed_date).to eq Date.parse("2008-03-02T16:45:41-08:00")
    expect(commit.tree).to eq "28a1a1ca3e663d35ba8bf07d3f1781af71359b76"
  end

  it "should parse xml with no namespace" do
    product = Product.parse(fixture_file('product_no_namespace.xml'), :single => true)
    expect(product.title).to eq "A Title"
    expect(product.feature_bullets.bug).to eq 'This is a bug'
    expect(product.feature_bullets.features.size).to eq 2
    expect(product.feature_bullets.features[0].name).to eq 'This is feature text 1'
    expect(product.feature_bullets.features[1].name).to eq 'This is feature text 2'
  end

  it "should parse xml with default namespace" do
    product = Product.parse(fixture_file('product_default_namespace.xml'), :single => true)
    expect(product.title).to eq "A Title"
    expect(product.feature_bullets.bug).to eq 'This is a bug'
    expect(product.feature_bullets.features.size).to eq 2
    expect(product.feature_bullets.features[0].name).to eq 'This is feature text 1'
    expect(product.feature_bullets.features[1].name).to eq 'This is feature text 2'
  end

  it "should parse xml with single namespace" do
    product = Product.parse(fixture_file('product_single_namespace.xml'), :single => true)
    expect(product.title).to eq "A Title"
    expect(product.feature_bullets.bug).to eq 'This is a bug'
    expect(product.feature_bullets.features.size).to eq 2
    expect(product.feature_bullets.features[0].name).to eq 'This is feature text 1'
    expect(product.feature_bullets.features[1].name).to eq 'This is feature text 2'
  end

  it "should parse xml with multiple namespaces" do
    track = FedEx::TrackReply.parse(fixture_file('multiple_namespaces.xml'))
    expect(track.highest_severity).to eq 'SUCCESS'
    expect(track.more_data).to eq false

    notification = track.notifications.first
    expect(notification.code).to eq 0
    expect(notification.localized_message).to eq 'Request was successfully processed.'
    expect(notification.message).to eq 'Request was successfully processed.'
    expect(notification.severity).to eq 'SUCCESS'
    expect(notification.source).to eq 'trck'

    detail = track.trackdetails.first
    expect(detail.carrier_code).to eq 'FDXG'
    expect(detail.est_delivery).to eq '2009-01-02T00:00:00'
    expect(detail.service_info).to eq 'Ground-Package Returns Program-Domestic'
    expect(detail.status_code).to eq 'OD'
    expect(detail.status_desc).to eq 'On FedEx vehicle for delivery'
    expect(detail.tracking_number).to eq '9611018034267800045212'
    expect(detail.weight.units).to eq 'LB'
    expect(detail.weight.value).to eq 2

    events = detail.events
    expect(events.size).to eq 10

    first_event = events[0]
    expect(first_event.eventdescription).to eq 'On FedEx vehicle for delivery'
    expect(first_event.eventtype).to eq 'OD'
    expect(first_event.timestamp).to eq '2009-01-02T06:00:00'
    expect(first_event.address.city).to eq 'WICHITA'
    expect(first_event.address.countrycode).to eq 'US'
    expect(first_event.address.residential).to eq false
    expect(first_event.address.state).to eq 'KS'
    expect(first_event.address.zip).to eq '67226'

    last_event = events[-1]
    expect(last_event.eventdescription).to eq 'In FedEx possession'
    expect(last_event.eventtype).to eq 'IP'
    expect(last_event.timestamp).to eq '2008-12-27T09:40:00'
    expect(last_event.address.city).to eq 'LONGWOOD'
    expect(last_event.address.countrycode).to eq 'US'
    expect(last_event.address.residential).to eq false
    expect(last_event.address.state).to eq 'FL'
    expect(last_event.address.zip).to eq '327506398'
    expect(track.tran_detail.cust_tran_id).to eq '20090102-111321'
  end

  it "should be able to parse from a node's content " do
    notes = Backpack::Note.parse(fixture_file('notes.xml'))
    expect(notes.size).to eq 2

    note = notes[0]
    expect(note.id).to eq 1132
    expect(note.title).to eq 'My world!'
    expect(note.body).to include("It's a pretty place")

    note = notes[1]
    expect(note.id).to eq 1133
    expect(note.title).to eq 'Your world!'
    expect(note.body).to include("Also pretty")
  end

  it "should be able to parse google analytics api xml" do
    data = Analytics::Feed.parse(fixture_file('analytics.xml'))
    expect(data.id).to eq 'http://www.google.com/analytics/feeds/accounts/nunemaker@gmail.com'
    expect(data.entries.size).to eq 4

    entry = data.entries[0]
    expect(entry.title).to eq 'addictedtonew.com'
    expect(entry.properties.size).to eq 4

    property = entry.properties[0]
    expect(property.name).to eq 'ga:accountId'
    expect(property.value).to eq '85301'
  end

  it "should allow instantiating with a string" do
    module StringFoo
      class Bar
        include HappyMapper
        has_many :things, 'StringFoo::Thing'
      end

      class Thing
        include HappyMapper
      end
    end
  end

  xit "should parse family search xml" do
    tree = FamilySearch::FamilyTree.parse(fixture_file('family_tree.xml'))
    expect(tree.version).to eq '1.0.20071213.942'
    expect(tree.status_message).to eq 'OK'
    expect(tree.status_code).to eq '200'
    # expect(tree.people.size).to eq 1
    # expect(tree.people.first.version).to eq '1199378491000'
    # expect(tree.people.first.modified).to eq Time.utc(2008, 1, 3, 16, 41, 31) # 2008-01-03T09:41:31-07:00
    # expect(tree.people.first.id).to eq 'KWQS-BBQ'
  end

  it "should support :xpath option" do
    message_box = Intrade::Messages.parse(fixture_file('intrade.xml'))
    expect(message_box.timestamp).to eq Time.at(1329416249)
    expect(message_box.error_message).to eq "Ok"

    # default xpath would default to './/msg', which would include
    # nested nodes which are also named "msg", so xpath is
    # explicitly supplied as option :xpath => './msg'
    expect(message_box.messages.length).to eq 2
    expect(message_box.messages[0].message_id).to eq 123456
    expect(message_box.messages[1].message_id).to eq 123460
  end

  describe 'nested elements with namespaces' do
    module Namespaces
      class Info
        include HappyMapper
        namespace 'http://schemas.google.com/analytics/2009'
        element :category, String
      end

      class Alert
        include HappyMapper
        namespace 'http://schemas.google.com/analytics/2009'

        element :identifier, String
        element :severity, String, :namespace => false
        has_one :info, Info
      end
      class Distribution
        include HappyMapper

        tag 'EDXLDistribution'
        has_one :alert, Alert
      end
    end

    def mapping
      @mapping ||= Namespaces::Distribution.parse(fixture_file('nested_namespaces.xml'))
    end

    it "should parse elements with inline namespace" do
      expect { mapping }.to_not raise_error
    end

    it "should map elements with inline namespace" do
      expect(mapping.alert.identifier).to eq 'CDC-2006-183'
    end

    it "should map sub elements of with nested namespace" do
      expect(mapping.alert.info.category).to eq 'Health'
    end

    it "should map elements without a namespace" do
      expect(mapping.alert.severity).to eq 'Severe'
    end
  end

end
