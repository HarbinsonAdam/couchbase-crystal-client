struct CouchbaseScopeResponse
  include JSON::Serializable

  getter uid : String
  getter scopes : Array(CouchbaseScope)
end

struct CouchbaseScope
  include JSON::Serializable

  getter name : String
  getter uid : String
  getter collections : Array(CouchbaseCollection)
end

struct CouchbaseCollection
  include JSON::Serializable

  getter name : String
  getter uid : String
  getter maxTTL : Int32
  getter history : Bool?
end