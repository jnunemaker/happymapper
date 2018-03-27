require 'spec_helper'

module ToXML

  class Address
    include HappyMapper

    tag 'address'

    attribute :location, String
    attribute :precipitation, Float
    attribute :last_update, Time
    attribute :mayor_elected, Date
    attribute :last_earthquake, DateTime
    attribute :revision, Integer
    attribute :domestic, Boolean

    element :street, String
    element :postcode, String
    element :city, String

    element :housenumber, String

    #
    # to_xml will default to the attr_accessor method and not the attribute,
    # allowing for that to be overwritten
    #
    def housenumber
      "[#{@housenumber}]"
    end

    #
    # Write a empty element even if this is not specified
    #
    element :description, String, :state_when_nil => true

    #
    # Perform the on_save operation when saving
    #
    has_one :date_created, Time, :on_save => lambda {|time| DateTime.parse(time).strftime("%T %D") if time }

    #
    # Write multiple elements and call on_save when saving
    #
    has_many :dates_updated, Time, :on_save => lambda {|times|
      times.compact.map {|time| DateTime.parse(time).strftime("%T %D") } if times }

    #
    # Class composition
    #
    element :country, 'Country', :tag => 'country'

    def initialize(parameters)
      parameters.each_pair do |property,value|
        send("#{property}=",value) if respond_to?("#{property}=")
      end
    end

  end

  #
  # Country is composed above the in Address class. Here is a demonstration
  # of how to_xml will handle class composition as well as utilizing the tag
  # value.
  #
  class Country
    include HappyMapper

    attribute :code, String, :tag => 'countryCode'
    has_one :name, String, :tag => 'countryName'

    def initialize(parameters)
      parameters.each_pair do |property,value|
        send("#{property}=",value) if respond_to?("#{property}=")
      end
    end

  end

  describe "#to_xml" do

    context "Address" do

      before(:all) do
        address = Address.new('street' => 'Mockingbird Lane',
        'location' => 'Home',
        'housenumber' => '1313',
        'postcode' => '98103',
        'city' => 'Seattle',
        'country' => Country.new(:name => 'USA', :code => 'us'),
        'date_created' => '2011-01-01 15:00:00',
        'precipitation' => 58.3,
        'last_update' =>  Time.new(1993, 02, 24, 12, 0, 0, "+09:00"),
        'mayor_elected' => Date.new(2001, 2, 3) ,
        'last_earthquake' => DateTime.new(2001, -11, -26, -20, -55, -54, '+7'),
        'revision' => 42,
        'domestic' => true)

        address.dates_updated = ["2011-01-01 16:01:00","2011-01-02 11:30:01"]

        @address_xml = XML::Parser.string(address.to_xml).parse.root
      end

      { 'street' => 'Mockingbird Lane',
        'postcode' => '98103',
        'city' => 'Seattle' }.each_pair do |property,value|

        it "should have the element '#{property}' with the value '#{value}'" do
          expect(@address_xml.find("#{property}").first.child.to_s).to eq value
        end

      end

      it "should use the result of #housenumber method (not the @housenumber)" do
        expect(@address_xml.find("housenumber").first.child.to_s).to eq "[1313]"
      end

      it "should add an empty description element" do
        expect(@address_xml.find('description').first.child.to_s).to eq ""
      end

      it "should call #on_save when saving the time to convert the time" do
        expect(@address_xml.find('date_created').first.child.to_s).to eq "15:00:00 01/01/11"
      end

      it "should handle multiple elements for 'has_many'" do
        dates_updated = @address_xml.find('dates_updated')
        expect(dates_updated.length).to eq 2
        expect(dates_updated.first.child.to_s).to eq "16:01:00 01/01/11"
        expect(dates_updated.last.child.to_s).to eq "11:30:01 01/02/11"
      end

      it "should write the country code" do
        expect(@address_xml.find('country/@countryCode').first.child.to_s).to eq "us"
      end

      it "should write the country name" do
        expect(@address_xml.find('country/countryName').first.child.to_s).to eq "USA"
      end

      it "should have the attribute 'location' with the value 'Home'" do
        expect(@address_xml.find('@location').first.child.to_s).to eq 'Home'
      end

      it "should have the attribute 'precipitation' with the value '58.3'" do
        expect(@address_xml.find('@precipitation').first.child.to_s).to eq '58.3'
      end

      it "should have the attribute 'last_update' with the value '1993-02-24 12:00:00 +0900'" do
        expect(@address_xml.find('@last_update').first.child.to_s).to eq "1993-02-24 12:00:00 +0900"
      end

      it "should have the attribute 'mayor_elected' with the value '2001-02-03'" do
        expect(@address_xml.find('@mayor_elected').first.child.to_s).to eq '2001-02-03'
      end

      it "should have the attribute 'last_earthquake' with the value ''" do
        expect(@address_xml.find('@last_earthquake').first.child.to_s).to eq '2001-02-03T04:05:06+07:00'
      end

      it "should have the attribute 'revision' with the value '42'" do
        expect(@address_xml.find('@revision').first.child.to_s).to eq '42'
      end

      it "should have the attribute 'domestic' with the value 'true'" do
        expect(@address_xml.find('@domestic').first.child.to_s).to eq 'true'
      end

    end

  end

end
