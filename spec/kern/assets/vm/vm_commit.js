//Create a page
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

//[unbased, no-changes]
var unbased_nochanges = gen_page(null, null, [
    {"value": "hello"}
]);

//[unbased, changes]
var unbased_changes = gen_page(null, null, []);
var a1 = gen_page(null, null, [
    {"value": "4"}
]);
unbased_changes.__changes = vm_diff(a1, unbased_changes);
unbased_changes.__changes_id = "XXXXXXXXXX";

//[based, changes] 
var based_changes = gen_page(null, null, []);
var a2 = gen_page(null, null, [
    {"value": "4"}
]);
var a3 = gen_page(null, null, [
    {"value": "z"}
]);
a2.__changes = vm_diff(a3, a2);
a2.__changes_id = "XYXYXY";
based_changes.__changes = vm_diff(a2, based_changes);
based_changes.__changes_id = "XXXXXX";
based_changes.__base = a2;

//[unbased, no-changes] page
page = gen_page(null, null, [
    {"value": "5"}
]);
