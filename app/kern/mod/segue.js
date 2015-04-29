//Contains bottom view as key and a the values are also a hash
//that contains the 'top' thing
//{
//  'nav_container' =>
//    {
//      'nav_container' => 'name'
//    }
//}
int_segue_interceptors = {
}

//Contains an array 

//Register a segue intercept
//name - The name of the segue to be given if_segue_do
//from_view_name - The name of the bottom view to intercept
//to_view_name - The name of the top view to intercept

function reg(name, from_view_name, to_view_name) {
  //Create hash if it dosen't already exist
  int_segue_interceptors[from_view_name] = int_segue_interceptors[from_view_name] || {};
  int_segue_interceptors[from_view_name][to_view_name] = name;
}

//Will send the 'if' commands
function intercept_if_necessary(bottom_view_name, top_view_name, from_vp, to_vp) {
  console.log("Intercept if necessars")
  if (int_segue_interceptors[bottom_view_name] && int_segue_interceptors[bottom_view_name][top_view_name]) {
    var rez = int_segue_interceptors[bottom_view_name][top_view_name];

    SEND("main", "if_segue_do", rez, from_vp, to_vp);
  }
}

reg("modal", "nav_container", "nav_container");
