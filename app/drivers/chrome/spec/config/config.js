QUnit.testStart(function(details) {
  console.log( "+: ", details.module, details.name);
});

QUnit.log(function( details ) {
  //Only show failed results
  if (details.result) {
    return;
  }

  var loc = details.module + ": " + details.name + ": ",
  output = "FAILED: " + loc + ( details.message ? details.message + ", " : "" );

  if ( details.actual ) {
    output += "expected: " + details.expected + ", actual: " + details.actual;
  }
  if ( details.source ) {
    output += ", " + details.source;
  }
  console.log( output );
}); 

QUnit.testDone(function( details ) {
  console.log("[passed/total]: ", details.passed, "/", details.total);
  console.log("-----------------------------------------------------------------");
});

QUnit.moduleDone(function(details) {
  var passed = details.passed;
  var total = details.total;

  console.log("Finished Tests: " + passed + "/" + total + " passed")

  if (passed == total) {
    console.log("__SUCCESS")
  } else {
    console.log("__FAILED")
  }
});
