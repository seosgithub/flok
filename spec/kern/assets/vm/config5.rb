#Simple service config that uses built-in spec service to create a instance called 'spec'
service_instance :vm, :vm, {
  :pagers => [
    {
      :name => "pg_spec0",
      :namespace => "spec0",
      :options => {
        "hello" => "world"
      }
    },
    {
      :name => "pg_spec1",
      :namespace => "spec1",
      :options => {
        "foo" => "bar"
      }
    }

  ]
}
