//Support for the telepathy protocol
tel_idx = 0

//This function creates N telepathic pointers and returns the starting index
//of the first pointer returned.  Successive pointers are just increments
//of the base value by one. Should be used as much as possible as it
//reduces the communication overhead (by allowing pipelining on futures), 
//and prevents native pointers from entering the system (which allows more
//interesting abstractions like slaves)
function tels(n) {
  var o = tel_idx;
  tel_idx += n;
  return o;
}
