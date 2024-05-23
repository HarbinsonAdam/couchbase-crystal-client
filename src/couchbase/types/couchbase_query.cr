struct CouchbaseQuery
  include JSON::Serializable

  property statement : String
  property args : JSON::Any?

  def initialize(@statement : String); end
  def initialize(@statement : String, @args); end
end