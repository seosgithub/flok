//Will return an array with two equal (but not pointing to the same object) pages like [page_a, page_b]
//The first page is the original page, the second page you should modify for the tests for comparison.
//The 'entries' will automatically be put in an array and have an _id and _sig attached to them. The _id field
//will go from 0, 1, 2, 3, etc. and the _sig will be set to 'sig'.
function gen_pages(type, head, next, entries) {

  //Add _id and _sig field (only _sig for hash)
  if (Array.isArray(entries)) {
    for (var i = 0; i < entries.length; ++i) {
      entries[i]._sig = 'sig';
      entries[i]._id = "id"+i;
    }
  } else if (typeof entries === 'object'){
    var keys = Object.keys(entries);
    for (var i = 0; i < keys.length; ++i) {
      entries[keys[i]]._sig = "sig"+i;
    }
  } else {
    throw "gen_pages got entries that was not an object or array. Type was: " + typeof entries;
  }

  page_a = {
    _head: head,
    _type: type,
    _next: next,
    _id: "id",
    _hash: "__not_used__",
    entries: JSON.parse(JSON.stringify(entries))
  }

  page_b = {
    _head: head,
    _type: type,
    _next: next,
    _id: "id",
    _hash: "__not_used__",
    entries: JSON.parse(JSON.stringify(entries))
  }

  return [page_a, page_b];
}

//Simple function that passes both pages to vm_diff
function diff_them(pages) {
  return vm_diff(pages[0], pages[1]);
}

function diff_them_reverse(pages) {
  return vm_diff(pages[1], pages[0]);
}

//Testing modified entry///////////////////////////////////////////////////
//Changing one element (array)
mod0 = gen_pages("array", null, null, [
    {"value": 'a'},
]);
mod0[1].entries[0].value = 'b';
mod0[1].entries[0]._sig = 'sig_new';

//Changing one element (hash)
hmod0 = gen_pages("hash", null, null, {
    "id0": {"value": 'a'},
});
hmod0[1].entries["id0"].value = 'b';
hmod0[1].entries["id0"]._sig = 'sig_new';

//Changing one element when two are present (array)
mod1 = gen_pages("array", null, null, [
    {"value": 'a'},
    {"value": 'b'}
]);
mod1[1].entries[1].value = 'c';
mod1[1].entries[1]._sig = 'sig_new';

//Changing one element when two are present (hash)
hmod1 = gen_pages("hash", null, null, {
    "id0": {"value": 'a'},
    "id1": {"value": 'b'}
});
hmod1[1].entries["id1"].value = 'c';
hmod1[1].entries["id1"]._sig = 'sig_new';

//Changing both elements when two are present (array)
mod2 = gen_pages("array", null, null, [
    {"value": 'a'},
    {"value": 'b'}
]);
mod2[1].entries[0].value = 'b';
mod2[1].entries[0]._sig = 'sig_new';

mod2[1].entries[1].value = 'c';
mod2[1].entries[1]._sig = 'sig_new';

//Changing both elements when two are present (hash)
hmod2 = gen_pages("hash", null, null, {
    "id0": {"value": 'a'},
    "id1": {"value": 'b'}
});
hmod2[1].entries["id0"].value = 'b';
hmod2[1].entries["id0"]._sig = 'sig_new';

hmod2[1].entries["id1"].value = 'c';
hmod2[1].entries["id1"]._sig = 'sig_new';
///////////////////////////////////////////////////////////////////////////

//Testing deleted entry (backwards insert)////////////////////////////////
//Deleting one element
dmod0 = gen_pages("array", null, null, [
    {"value": 'a'},
]);
dmod0[1].entries.splice(0, 1);

//Deleting one element when two are present
dmod1 = gen_pages("array", null, null, [
    {"value": 'a'},
    {"value": 'b'}
]);
dmod1[1].entries.splice(1, 1);

//Deleting both elements when two are present
dmod2 = gen_pages("array", null, null, [
    {"value": 'a'},
    {"value": 'b'}
]);
dmod2[1].entries.splice(0, 1);
dmod2[1].entries.splice(0, 1);

//Deleting one element (hash)
hdmod0 = gen_pages("hash", null, null, {
    "id0": {"value": 'a'},
});
delete hdmod0[1].entries["id0"];

//Deleting one element when two are present (hash)
hdmod1 = gen_pages("hash", null, null, {
    "id0": {"value": 'a'},
    "id1": {"value": 'b'}
});
delete hdmod1[1].entries["id1"];

//Deleting both elements when two are present (hash)
hdmod2 = gen_pages("hash", null, null, {
    "id0": {"value": 'a'},
    "id1": {"value": 'b'}
});
delete hdmod2[1].entries["id0"];
delete hdmod2[1].entries["id1"];
///////////////////////////////////////////////////////////////////////////
