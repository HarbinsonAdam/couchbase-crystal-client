class CouchbaseCreateCollectionClient
  property parameters : CouchbaseCollectionParameters

  HEADERS = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}

  def initialize(@parameters : CouchbaseCollectionParameters)
    uri = URI.parse "#{Couchbase.settings.use_tls ? "https" : "http"}://#{Couchbase.settings.db_host}:#{Couchbase.settings.db_admin_port}"
    @client = HTTP::Client.new uri
    @client.basic_auth(Couchbase.settings.user, Couchbase.settings.password)
  end

  def perform
    res = @client.post(endpoint, HEADERS, body: parameters.to_query_params)
  end

  private def endpoint
    "/pools/default/buckets/#{Couchbase.settings.bucket_name}/scopes/#{Couchbase.settings.scope_name}/collections"
  end
end