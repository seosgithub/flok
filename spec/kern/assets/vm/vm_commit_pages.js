//Page Factor
//////////////////////////////////////////////////////////////////////////////////////////
function PageFactory(head, next) {
  this.head = head;
  this.next = next;
  this.entries = [];
}

//Add an entry
PageFactory.prototype.addEntry = function(eid, value) {
  this.entries.push({_id: eid, _sig: value, value: value});
}

//This adds up to four entrys that can be represented as a square:
//-------------
//| id0 | id1 |
//-------------
//| id2 | id3 |
//-------------
//Leaving out parts of the values array will not add those entries, e.g. ["Square", null, null, "Triangle"]
//--------------------|
//| Square | null     |
//--------------------| 
//| null   | Triangle |
//--------------------|
//Where 'Square' is id0 and 'Triangle' is id3
PageFactory.prototype.addEntryFourSquare = function(values) {
  if (values.length != 4) {
    throw "FourSquare requires for values. Make values null if you don't need them"
  }

  for (var i = 0; i < values.length; ++i) {
    if (values[i]) {
      this.addEntry("id"+i, values[i]);
    }
  }
}

//Returns a page
PageFactory.prototype.compile = function() {
  var page = vm_create_page("default");
  page._head = this.head;
  page._next = this.next;

  page.entries = this.entries;

  vm_rehash_page(page);
  vm_reindex_page(page);

  return page;
}
//////////////////////////////////////////////////////////////////////////////////////////

var pf = new PageFactory();
pf.addEntryFourSquare(["Triangle", "Square", "Z", null]);
triangle_square_z_null = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["Triangle", "Circle", null, "Q"]);
triangle_circle_null_q = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["Triangle", "Circle", null, "Q"]);
triangle_circle_null_q = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["Q", null, "Circle", "Square"]);
q_null_circle_square = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["P", "Circle", null, "Q"]);
p_circle_null_q = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["P", "Circle", null, null]);
p_circle_null_null  = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["P", null, null, "Q"]);
p_null_null_q = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["P", "Square", null, null]);
p_square_null_null  = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["Triangle", null, "A", "M"]);
triangle_null_a_m = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["Triangle", "Square", null, null]);
triangle_square_null_null = pf.compile();

var pf = new PageFactory();
pf.addEntryFourSquare(["Triangle", "Z", "Q", null]);
triangle_z_q_null  = pf.compile();

var pf = new PageFactory(null);
head_null = pf.compile();

var pf = new PageFactory("world");
head_world = pf.compile();

var pf = new PageFactory(null);
next_null  = pf.compile();

var pf = new PageFactory(null, "world");
next_world = pf.compile();
