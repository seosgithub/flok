$(document).ready(function() {
  QUnit.testStart(function(details) {
    console.log( "+: ", details.module, details.name);
  });

  QUnit.log(function( details ) {
    if ( details.result ) {
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
    console.log("----------------------------------------------------")
  });
});
