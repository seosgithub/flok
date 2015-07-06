//Will return an array with two equal (but not pointing to the same object) pages like [page_a, page_b]
//The first page is the original page, the second page you should modify for the tests for comparison.
//The 'entries' will automatically be put in an array and have an _id and _sig attached to them. The _id field
//will go from 0, 1, 2, 3, etc. and the _sig will be set to 'sig'.
var sig = 0;
function gen_page(head, next, entries) {
  for (var i = 0; i < entries.length; ++i) {
    entries[i]._sig = 'sig' + sig;
    entries[i]._id = "id"+i;
    sig += 1;
  }

  page_a = {
    _head: head,
    _next: next,
    _id: "id",
    _hash: "__not_used__",
    entries: JSON.parse(JSON.stringify(entries))
  }

  return page_a;
}

//vm_base
/////////////////////////////////////////////////////////////////
//base[unbased, no-changes]
var base_unbased_nochanges = gen_page(null, null, []);

//base[unbased, changes]
var base_unbased_changes = gen_page(null, null, []);
var a1 = gen_page(null, null, [
    {"value": "4"}
]);
base_unbased_changes.__changes = vm_diff(a1, base_unbased_changes);
base_unbased_changes.__changes_id = vm_diff(a1, base_unbased_changes);

//base[based, changes] 
var base_based_changes = gen_page(null, null, []);
var a2 = gen_page(null, null, [
    {"value": "4"}
]);
base_based_changes.__changes = vm_diff(a2, base_based_changes);
base_based_changes.__changes_id = "XXXXXX";
base_based_changes.__base = a2;
/////////////////////////////////////////////////////////////////

//vm_rebase
/////////////////////////////////////////////////////////////////
//Need a page[based, changes]
var page_based_changes = gen_page(null, null, []);
var a3 = gen_page(null, null, [
    {"value": "4"}
]);
var a4 = gen_page(null, null, [
    {"value": "z"}
]);
a3.__changes = vm_diff(a4, a3);
page_based_changes.__changes = vm_diff(a3, page_based_changes);
page_based_changes.__changes_id = "XXXXXX";
page_based_changes.__base = a3;

//And a base, which will have an extra element
var base_unbased_nochanges_one_entry = gen_page(null, null, [
    {"value": "hola"}
]);
/////////////////////////////////////////////////////////////////

page = gen_page(null, null, [
    {"value": "5"}
]);
