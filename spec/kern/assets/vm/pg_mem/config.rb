#Simple service config that uses built-in spec service to create a instance called 'spec'
service_instance :vm, :vm, {
  :pagers => [
    {
      :name => "pg_mem0",
      :namespace => "local",
      :options => {}
    }
  ]
}
