service :test do
  global %{
    function <%= @name %>_function(x) {
      <%= @name %>_function_args = x;
    }
  }
end
