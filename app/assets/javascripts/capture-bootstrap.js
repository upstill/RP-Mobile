/* This file is loaded by the RecipePower bookmarklet. */

if (!($ = window.jQuery)) { // typeof jQuery=='undefined' works too  
    script = document.createElement( 'script' );  
    script.src = 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js';  
    script.onload=recipePowerCapture;  
    document.body.appendChild(script);  
}  
else {  
    recipePowerCapture();  
}  

function recipePowerCapture() {
    var resource = "http://localhost:5000/recipes/capture";
    alert( "Got recipePowerCapture!");
    var obj = 
	  { url: window.location.href,
	 	title: document.title,
		area: "at_top",
		how: "modeless" }
		
	recipePowerGetAndRunHTML(resource, obj)
}

/* Take an HTML stream and run a dialog from it. Assumptions:
  1) The body is a div element of class 'dialog'. (It will work if the 'div.dialog'
	is embedded within the HTML, but it won't clean up properly.)
  2) There is styling on the element that will determine the width of the dialog
  3) [optional] The 'div.dialog' has a 'title' attribute containing the title string
  4) The submit action returns a json structure that the digestion function understands
  5) The dialog will be run modally unless there is a 'at_top' class or 'at_left' class
	on the 'div.dialog' element.
  6) While not required, it is conventional that an 'Onload' function be defined for the 
	dialog to set up various response functions.
*/

function recipePowerGetAndRunHTML(request, params={} ) {
	// Serialize the request
	var str = [];
	for(var p in params)
	  str.push(encodeURIComponent(p) + "=" + encodeURIComponent(params[p]));
	var request += "?" + str.join("&");
	
	$('span.query').text(request);
	var xmlhttp;
	// Send the request using minimal Javascript
	if (window.XMLHttpRequest) { xmlhttp=new XMLHttpRequest(); }
	else {
	  try { xmlhttp = new ActiveXObject("Msxml2.XMLHTTP"); }
	  catch (e) {
		try { xmlhttp = new ActiveXObject("Microsoft.XMLHTTP"); }
		catch (e) { xmlhttp = null; }
	  }
	}
	if(xmlhttp != null) {
	  xmlhttp.onreadystatechange=function() {
	    if (xmlhttp.readyState==4 && xmlhttp.status==200) {
		  // Now we have code, possibly required for jQuery and certainly 
		  // required for any of our javascript. Ensure the code is loaded.
		
		  var result = { code: xmlhttp.responseText };
		  if(typeof postSuccess === 'function')
			  postSuccess( result );
		  result.how = how;
		  result.area = area;
		  runResponse(result);
	    }
	  }
	  xmlhttp.open("GET", request, true);
	  xmlhttp.setRequestHeader("Accept", "text/html" );
	  xmlhttp.send();		
	}
}
