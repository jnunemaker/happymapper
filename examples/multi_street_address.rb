dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'happymapper')

file_contents = File.read(dir + '/../spec/fixtures/multi_street_address.xml')

class MultiStreetAddress
  include HappyMapper
  
  # allow primitive type to be collection
  has_many :street_address, String, :tag => "streetaddress"
  element :city, String
  element :state_or_providence, String, :tag => "stateOfProvidence"
  element :zip, String
  element :country, String
end