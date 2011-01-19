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

MultiStreetAddress.parse(file_contents).each do |multi|
  
  puts "Street Address:"
  
  multi.street_address.each do |street|
    puts street
  end
  
  puts "City: #{multi.city}"
  puts "State/Province: #{multi.state_or_province}"
  puts "Zip: #{multi.zip}"
  puts "Country: #{multi.country}"
end