//Get a pseudo UUID
flok.uuid_counter = 0;
flok.UUID = function() {
  flok.uuid_counter += 1;
  return flok.uuid_counter;
}
