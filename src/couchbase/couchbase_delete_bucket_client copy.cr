class CouchbaseDeleteBucketClient
  property bucket_name : String

  def initialize(@bucket_name : String = "")
    uri = URI.parse "#{Couchbase.settings.use_tls ? "https" : "http"}://#{Couchbase.settings.db_host}:#{Couchbase.settings.db_admin_port}"
    @client = HTTP::Client.new uri
    @client.basic_auth(Couchbase.settings.user, Couchbase.settings.password)
  end

  def perform
    res = @client.delete(endpoint)
  end

  private def endpoint
    "/pools/default/buckets/#{bucket_name}"
  end
end