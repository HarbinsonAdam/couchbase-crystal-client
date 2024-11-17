struct CouchbaseQuery
  include JSON::Serializable

  property statement : String
  property args : JSON::Any?
  property txid : UUID?
  property scan_consistency : String?
  property durability_level : String?

  def initialize(@statement : String); end
  def initialize(@statement : String, @scan_consistency : String, @durability_level : String); end
  def initialize(@statement : String, @txid : UUID?); end
  def initialize(@statement : String, @args); end
  def initialize(@statement : String, @args, @txid : UUID?); end
end