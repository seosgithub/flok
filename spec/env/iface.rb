require 'json'

@driver = IO.popen("rake pipe:driver")
@kern = IO.popen("rake pipe:kern")
