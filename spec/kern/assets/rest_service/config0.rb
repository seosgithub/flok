#Simple service config that uses built-in spec service to create a instance called 'spec'
service_instance :rest, :rest, {
  :base_url => "http://localhost:8080/"
}
