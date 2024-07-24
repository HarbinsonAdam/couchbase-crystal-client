class CouchbaseGetBucketClient
  property bucket_name : String

  HEADERS = HTTP::Headers{"Content-Type" => "application/json"}

  def initialize(bucket_name : String = "")
    bucket_name = bucket_name.insert(0, "/") unless bucket_name.empty?
    @bucket_name = bucket_name

    uri = URI.parse "#{Couchbase.settings.use_tls ? "https" : "http"}://#{Couchbase.settings.db_host}:#{Couchbase.settings.db_admin_port}"
    @client = HTTP::Client.new uri
    @client.basic_auth(Couchbase.settings.user, Couchbase.settings.password)
  end

  def perform
    res = @client.get(endpoint, HEADERS)
    return res
  end

  private def endpoint
    "/pools/default/buckets#{bucket_name}"
  end
end