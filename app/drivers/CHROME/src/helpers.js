//Get a pseudo UUID
uuid_counter = 0;
UUID = function() {
  uuid_counter += 1;
  return uuid_counter;
}
