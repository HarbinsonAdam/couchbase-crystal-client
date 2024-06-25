struct CouchbaseCollectionParameters
  include JSON::Serializable

  getter name : String

  def initialize(@name); end
  
  def to_query_params : String
    "name=#{name}"
  end
end