//Support for the telepathy protocol
tel_idx = 0

//Global table linking telepointers to objects (like functions)
tel_table = {};

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

function tel_reg(e) {
  var tp = tels(1);
  tel_table[tp] = e;

  return tp;
}

function tel_reg_ptr(e, tp) {
  tel_table[tp] = e;
}

function tel_del(tp) {
  delete tel_table[tp];
}

function tel_deref(tp) {
  return tel_table[tp];
}

function tel_exists(tp) {
  return tp in tel_table;
}
