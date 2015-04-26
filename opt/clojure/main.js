var my_var = "hello";

function hello_world(callback) {
  console.log(my_var);

  if (Math.random() > 0.5) {
    callback();
  }
}

hello_world(function() {
  console.log("no");
});
