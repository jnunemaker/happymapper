class Post
  include HappyMapper
  
  attribute :href, String
  attribute :hash, String
  attribute :description, String
  attribute :tag, String
  attribute :time, DateTime
  attribute :others, Integer
  attribute :extended, String
end