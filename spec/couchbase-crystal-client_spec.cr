require "./spec_helper"

describe Couchbase do
  # TODO: Write tests

  cluster = Couchbase::Cluster.connect("couchbase://127.0.0.1", username: "Administrator", password: "password")
end
