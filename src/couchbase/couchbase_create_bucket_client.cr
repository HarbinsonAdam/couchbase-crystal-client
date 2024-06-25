class CouchbaseCreateBucketClient
  property parameters : CouchbaseBucketParameters
  property bucket_name : String

  HEADERS = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}

  def initialize(@parameters : CouchbaseBucketParameters, bucket_name : String = "")
    bucket_name.insert(0, "/") unless bucket_name.empty?
    @bucket_name = bucket_name

    uri = URI.parse "#{Couchbase.settings.use_tls ? "https" : "http"}://#{Couchbase.settings.db_host}:#{Couchbase.settings.db_admin_port}"
    @client = HTTP::Client.new uri
    @client.basic_auth(Couchbase.settings.user, Couchbase.settings.password)
  end

  def perform
    pp parameters.to_query_params
    pp @client
    pp "sending to #{endpoint}"
    res = @client.post(endpoint, HEADERS, body: parameters.to_query_params)
    pp res
    return res
  end

  private def endpoint
    "/pools/default/buckets#{bucket_name}"
  end
end