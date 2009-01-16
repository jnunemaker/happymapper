require 'rubygems'
gem 'happymapper', '0.1.2'
require 'happymapper'
require 'pp'
require 'xml'



$XML_NO_NS = <<-EOF
<products>
  <product>
    <title> A Title</title>
    <features_bullets>
      <feature>This is feature text 1</feature>
      <feature>This is feature text 2</feature>
      <bug>This is a bug</bug>
    </features_bullets>
  </product>
</products>
EOF


$XML_DEFAULT_NS = <<-EOF
<products xmlns="http://bigco.com">
  <product>
    <title> A Title</title>
    <features_bullets>
      <feature>This is feature text 1</feature>
      <feature>This is feature text 2</feature>
      <bug>This is a bug</bug>
    </features_bullets>
  </product>
</products>
EOF

$XML_EXTRA_NS = <<-EOF
<products xmlns:juju="http://bigco.com">
  <product>
    <title> A Title</title>
    <features_bullets>
      <feature>This is feature text 1</feature>
      <feature>This is feature text 2</feature>
      <bug>This is a bug</bug>
    </features_bullets>
  </product>
</products>
EOF

$XML_BROKEN = <<-EOF
<?xml version='1.0'?>

<feed xmlns:ga="http://bigco.com" xmlns:opensearch="http://bigco.com">
 <opensearch:totalresults>4</opensearch:totalresults>
  <opensearch:startindex>1</opensearch:startindex>
   <opensearch:itemsperpage>4</opensearch:itemsperpage> 
   <entry> 
    <ga:accountid>12345</ga:accountid> 
    <ga:accountname>Pride and Prejudice</ga:accountname> 
    <ga:profileid>4321</ga:profileid> 
    <ga:webpropertyid>UA-12345-1</ga:webpropertyid> 
    <ga:tableid>ga:4321</ga:tableid> </entry> 
  <entry> 
    <ga:accountid>12345</ga:accountid> 
    <ga:accountname>Pride and Prejudice</ga:accountname> 
    <ga:profileid>5555</ga:profileid> 
    <ga:webpropertyid>UA-12345-2</ga:webpropertyid> 
    <ga:tableid>ga:5555</ga:tableid> </entry> 
  <entry> 
    <ga:accountid>54321</ga:accountid> 
    <ga:accountname>Jane Austen</ga:accountname> 
    <ga:profileid>2222</ga:profileid> 
    <ga:webpropertyid>UA-54321-1</ga:webpropertyid> 
    <ga:tableid>ga:2222</ga:tableid> </entry> 
  <entry> 
    <ga:accountid>54321</ga:accountid> 
    <ga:accountname>Jane Austen</ga:accountname> 
    <ga:profileid>3333</ga:profileid> 
    <ga:webpropertyid>UA-54321-2</ga:webpropertyid> 
    <ga:tableid>ga:3333</ga:tableid> 
  </entry>
</feed>
EOF


### HappyMapper Product classes
class Feature
  include HappyMapper

  element :name, String, :tag => '.'
end

class FeatureBullet
  include HappyMapper

  tag 'features_bullets'
  has_many :features, Feature
  element :bug, String
end

class Product
  include HappyMapper

  element :title, String
  has_one :features_bullets, FeatureBullet
end

### HappyMapper FedEx classes
module FedEx
  class Address
    include HappyMapper
    
    tag 'Address'
    element :city, String, :tag => 'City'
    element :state, String, :tag => 'StateOrProvinceCode'
    element :zip, String, :tag => 'PostalCode'
    element :countrycode, String, :tag => 'CountryCode'
    element :residential, Boolean, :tag => 'Residential'
  end
  
  class Event
    include HappyMapper
    
    tag 'Events'
    element :timestamp, String, :tag => 'Timestamp'
    element :eventtype, String, :tag => 'EventType'
    element :eventdescription, String, :tag => 'EventDescription'
    has_one :address, Address
  end
  
  class PackageWeight
    include HappyMapper
    
    tag 'PackageWeight'
    element :units, String, :tag => 'Units'
    element :value, Integer, :tag => 'Value'
  end
  
  class TrackDetails
    include HappyMapper
    
    tag 'TrackDetails'
    element   :tracking_number, String, :tag => 'TrackingNumber'
    element   :status_code, String, :tag => 'StatusCode'
    element   :status_desc, String, :tag => 'StatusDescription'
    element   :carrier_code, String, :tag => 'CarrierCode'
    element   :service_info, String, :tag => 'ServiceInfo'
    has_one   :weight, PackageWeight, :tag => 'PackageWeight'
    element   :est_delivery,  String, :tag => 'EstimatedDeliveryTimestamp'
    has_many  :events, Event
  end 
    
  class Notification
    include HappyMapper
    
    tag 'Notifications'
    element :severity, String, :tag => 'Severity'
    element :source, String, :tag => 'Source'
    element :code, Integer, :tag => 'Code'
    element :message, String, :tag => 'Message'
    element :localized_message, String, :tag => 'LocalizedMessage'
  end
  
  class TransactionDetail
    include HappyMapper
    
    tag 'TransactionDetail'
    element :cust_tran_id, String, :tag => 'CustomerTransactionId'
  end
  
  class TrackReply
    include HappyMapper
  
    tag 'TrackReply'
    element   :highest_severity, String, :tag => 'HighestSeverity'
    has_many  :notifications, Notification, :tag => 'Notifications'
    has_one   :tran_detail, TransactionDetail, :tab => 'TransactionDetail'
    element   :more_data, Boolean, :tag => 'MoreData'
    has_many  :trackdetails, TrackDetails, :tag => 'TrackDetails'
  end
end

# quick load when running under IRB so you can play with LibXML finds, etc
# only if you read from a file or non-DATA, irb doesn't support DATA, I guess
def loadit
  parser = XML::Parser.new
  # parser.file = 'some file name.txt'
  parser.string = DATA.read
  $DOC = parser.parse
end

# quick load/parse when under IRB
# only if you read from a file or non-DATA, irb doesn't support DATA, I guess
def parseit
  $XML = DATA.read
  $TRK = FedEx::TrackReply.parse($XML, :use_slash => '/')
end



if $0 == __FILE__
  parseit
  pp $TRK
  puts "************************ No namespace in XML tests"
  pp Product.parse($XML_NO_NS)
  pp Product.parse($XML_NO_NS, :use_slash => '/', :use_default_namespace => true)
  puts "************************ Default namespace in XML tests"
  pp Product.parse($XML_DEFAULT_NS)
  pp Product.parse($XML_DEFAULT_NS, :use_slash => '/')
  puts "************************ Extra (unused) namespace in XML tests"
  pp Product.parse($XML_EXTRA_NS)
  pp Product.parse($XML_EXTRA_NS, :use_slash => '/')

end

__END__
<?xml version='1.0' encoding='UTF-8'?>


    <v2:TrackReply xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:v2='http://fedex.com/ws/track/v2'>
      <v2:HighestSeverity>SUCCESS</v2:HighestSeverity>
      <v2:Notifications>
        <v2:Severity>SUCCESS</v2:Severity>
        <v2:Source>trck</v2:Source>
        <v2:Code>0</v2:Code>
        <v2:Message>Request was successfully processed.</v2:Message>
        <v2:LocalizedMessage>Request was successfully processed.</v2:LocalizedMessage>
      </v2:Notifications>
      <ns:TransactionDetail xmlns:ns='http://fedex.com/ws/track/v2'>
    <ns:CustomerTransactionId>20090102-111321</ns:CustomerTransactionId>
  </ns:TransactionDetail>
      <ns:Version xmlns:ns='http://fedex.com/ws/track/v2'>
    <ns:ServiceId>trck</ns:ServiceId>
    <ns:Major>2</ns:Major>
    <ns:Intermediate>0</ns:Intermediate>
    <ns:Minor>0</ns:Minor>
  </ns:Version>
      <v2:DuplicateWaybill>false</v2:DuplicateWaybill>
      <v2:MoreData>false</v2:MoreData>
      <v2:TrackDetails>
        <v2:TrackingNumber>9611018034267800045212</v2:TrackingNumber>
        <v2:TrackingNumberUniqueIdentifier>120081227094248461000~034267800045212</v2:TrackingNumberUniqueIdentifier>
        <v2:StatusCode>OD</v2:StatusCode>
        <v2:StatusDescription>On FedEx vehicle for delivery</v2:StatusDescription>
        <v2:CarrierCode>FDXG</v2:CarrierCode>
        <v2:ServiceInfo>Ground-Package Returns Program-Domestic</v2:ServiceInfo>
        <v2:PackageWeight>
          <v2:Units>LB</v2:Units>
          <v2:Value>2.6</v2:Value>
        </v2:PackageWeight>
        <v2:Packaging>Package</v2:Packaging>
        <v2:PackageSequenceNumber>1</v2:PackageSequenceNumber>
        <v2:PackageCount>1</v2:PackageCount>
        <v2:OriginLocationAddress>
          <v2:City>SANFORD</v2:City>
          <v2:StateOrProvinceCode>FL</v2:StateOrProvinceCode>
          <v2:CountryCode>US</v2:CountryCode>
          <v2:Residential>false</v2:Residential>
        </v2:OriginLocationAddress>
        <v2:ShipTimestamp>2008-12-29T00:00:00</v2:ShipTimestamp>
        <v2:EstimatedDeliveryTimestamp>2009-01-02T00:00:00</v2:EstimatedDeliveryTimestamp>
        <v2:SignatureProofOfDeliveryAvailable>false</v2:SignatureProofOfDeliveryAvailable>
        <v2:ProofOfDeliveryNotificationsAvailable>true</v2:ProofOfDeliveryNotificationsAvailable>
        <v2:ExceptionNotificationsAvailable>true</v2:ExceptionNotificationsAvailable>
        <v2:Events>
          <v2:Timestamp>2009-01-02T06:00:00</v2:Timestamp>
          <v2:EventType>OD</v2:EventType>
          <v2:EventDescription>On FedEx vehicle for delivery</v2:EventDescription>
          <v2:Address>
            <v2:City>WICHITA</v2:City>
            <v2:StateOrProvinceCode>KS</v2:StateOrProvinceCode>
            <v2:PostalCode>67226</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
        <v2:Events>
          <v2:Timestamp>2009-01-02T01:17:32</v2:Timestamp>
          <v2:EventType>AR</v2:EventType>
          <v2:EventDescription>At local FedEx facility</v2:EventDescription>
          <v2:Address>
            <v2:City>WICHITA</v2:City>
            <v2:StateOrProvinceCode>KS</v2:StateOrProvinceCode>
            <v2:PostalCode>67226</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
        <v2:Events>
          <v2:Timestamp>2009-01-01T21:49:49</v2:Timestamp>
          <v2:EventType>DP</v2:EventType>
          <v2:EventDescription>Departed FedEx location</v2:EventDescription>
          <v2:Address>
            <v2:City>LENEXA</v2:City>
            <v2:StateOrProvinceCode>KS</v2:StateOrProvinceCode>
            <v2:PostalCode>66227</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
        <v2:Events>
          <v2:Timestamp>2008-12-31T16:19:00</v2:Timestamp>
          <v2:EventType>AR</v2:EventType>
          <v2:EventDescription>Arrived at FedEx location</v2:EventDescription>
          <v2:Address>
            <v2:City>LENEXA</v2:City>
            <v2:StateOrProvinceCode>KS</v2:StateOrProvinceCode>
            <v2:PostalCode>66227</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
        <v2:Events>
          <v2:Timestamp>2008-12-30T11:01:23</v2:Timestamp>
          <v2:EventType>DP</v2:EventType>
          <v2:EventDescription>Departed FedEx location</v2:EventDescription>
          <v2:Address>
            <v2:City>ORLANDO</v2:City>
            <v2:StateOrProvinceCode>FL</v2:StateOrProvinceCode>
            <v2:PostalCode>32809</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
        <v2:Events>
          <v2:Timestamp>2008-12-30T05:00:00</v2:Timestamp>
          <v2:EventType>AR</v2:EventType>
          <v2:EventDescription>Arrived at FedEx location</v2:EventDescription>
          <v2:Address>
            <v2:City>ORLANDO</v2:City>
            <v2:StateOrProvinceCode>FL</v2:StateOrProvinceCode>
            <v2:PostalCode>32809</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
        <v2:Events>
          <v2:Timestamp>2008-12-30T03:16:33</v2:Timestamp>
          <v2:EventType>DP</v2:EventType>
          <v2:EventDescription>Left FedEx origin facility</v2:EventDescription>
          <v2:Address>
            <v2:City>SANFORD</v2:City>
            <v2:StateOrProvinceCode>FL</v2:StateOrProvinceCode>
            <v2:PostalCode>32771</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
        <v2:Events>
          <v2:Timestamp>2008-12-29T22:46:00</v2:Timestamp>
          <v2:EventType>AR</v2:EventType>
          <v2:EventDescription>Arrived at FedEx location</v2:EventDescription>
          <v2:Address>
            <v2:City>SANFORD</v2:City>
            <v2:StateOrProvinceCode>FL</v2:StateOrProvinceCode>
            <v2:PostalCode>32771</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
        <v2:Events>
          <v2:Timestamp>2008-12-29T17:12:00</v2:Timestamp>
          <v2:EventType>PU</v2:EventType>
          <v2:EventDescription>Picked up</v2:EventDescription>
          <v2:Address>
            <v2:City>SANFORD</v2:City>
            <v2:StateOrProvinceCode>FL</v2:StateOrProvinceCode>
            <v2:PostalCode>32771</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
        <v2:Events>
          <v2:Timestamp>2008-12-27T09:40:00</v2:Timestamp>
          <v2:EventType>IP</v2:EventType>
          <v2:EventDescription>In FedEx possession</v2:EventDescription>
          <v2:StatusExceptionCode>084</v2:StatusExceptionCode>
          <v2:StatusExceptionDescription>Tendered at FedEx location</v2:StatusExceptionDescription>
          <v2:Address>
            <v2:City>LONGWOOD</v2:City>
            <v2:StateOrProvinceCode>FL</v2:StateOrProvinceCode>
            <v2:PostalCode>327506398</v2:PostalCode>
            <v2:CountryCode>US</v2:CountryCode>
            <v2:Residential>false</v2:Residential>
          </v2:Address>
        </v2:Events>
      </v2:TrackDetails>
    </v2:TrackReply>
