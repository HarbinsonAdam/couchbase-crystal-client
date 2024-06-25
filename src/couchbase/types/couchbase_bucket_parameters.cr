struct CouchbaseBucketParameters
  include JSON::Serializable

  getter name : String
  getter ram_quota : Int32

  def initialize(@name, @ram_quota); end
  
  def to_query_params : String
    "name=#{name}&ramQuota=#{ram_quota}"
  end
end