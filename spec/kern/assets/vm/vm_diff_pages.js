//Will return an array with two equal (but not pointing to the same object) pages like [page_a, page_b]
//The first page is the original page, the second page you should modify for the tests for comparison.
//The 'entries' will automatically be put in an array and have an _id and _sig attached to them. The _id field
//will go from 0, 1, 2, 3, etc. and the _sig will be set to 'sig'.
function gen_pages(head, next, entries) {
  for (var i = 0; i < entries.length; ++i) {
    entries[i]._sig = 'sig';
    entries[i]._id = "id"+i;
  }

  page_a = {
    _head: head,
    _next: next,
    _id: "id",
    _hash: "__not_used__",
    entries: JSON.parse(JSON.stringify(entries))
  }

  page_b = {
    _head: head,
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
//Changing one element
mod0 = gen_pages(null, null, [
    {"value": 'a'},
]);
mod0[1].entries[0].value = 'b';
mod0[1].entries[0]._sig = 'sig_new';

//Changing one element when two are present
mod1 = gen_pages(null, null, [
    {"value": 'a'},
    {"value": 'b'},
    {"value": 'd'}
]);
mod1[1].entries[1].value = 'c';
mod1[1].entries[1]._sig = 'sig_new';

//Changing both elements when two are present
mod2 = gen_pages(null, null, [
    {"value": 'a'},
    {"value": 'b'}
]);
mod2[1].entries[0].value = 'b';
mod2[1].entries[0]._sig = 'sig_new';

mod2[1].entries[1].value = 'c';
mod2[1].entries[1]._sig = 'sig_new';
///////////////////////////////////////////////////////////////////////////

//Testing deleted entry (backwards insert)////////////////////////////////
//Deleting one element
dmod0 = gen_pages(null, null, [
    {"value": 'a'},
]);
dmod0[1].entries.splice(0, 1);

//Deleting one element when two are present
dmod1 = gen_pages(null, null, [
    {"value": 'a'},
    {"value": 'b'},
    {"value": 'c'}
]);
dmod1[1].entries.splice(1, 1);

//Deleting both elements when two are present
dmod2 = gen_pages(null, null, [
    {"value": 'a'},
    {"value": 'b'}
]);
dmod2[1].entries.splice(0, 1);
dmod2[1].entries.splice(0, 1);
///////////////////////////////////////////////////////////////////////////
