// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//= require_directory .
// GUARANTEED NECESSARY
// Callback to respond to value changes on form elements,
//  triggering immediate response
function queryChange() {
    // queryformHit(this.form);
    queryformHit($("form")[0]);
}

// Callback to respond to select on list owner,
//  triggering immediate response
function queryownerChange() {
    queryheaderHit(this.form);
    queryformHit(this.form);
}

function queryListmodeChange() {
    var form = $("form")[0];
    var formstr = $(form).serialize();
    // Add the popup to the rcpquery params in the form
    var div = $('select#rcpquery_listmode_str')[0];
    var divstr = $(div).serialize();
    var datastr = "element=tabnum&" + formstr + "&" + divstr;
    debugger;
    //...and proceed with the form hit as usual
    var resp =
    jQuery.ajax({
        type: "POST",
        url: form.action,
        data: datastr,
        // Submit the data from the form
        dataType: "html",
        success: queryresultsUpdate
    }
    );
}

// Handle a hit on one of the query fields by POSTing the whole form, then
// (via callback) updating the results list
function queryformHit(form) {
    var resp =
    jQuery.ajax({
        type: "POST",
        url: form.action,
        data: "element=tabnum&" + $(form).serialize(),
        // Submit the data from the form
        dataType: "html",
        success: queryresultsUpdate
    }
    );
}

// Callback after an update to hit the appropriate recipe tab
function queryresultsUpdate(resp, succ, xhr) {
    // The response is just the index of the tab to hit
    $("#rcpquery_tabset").tabs('load', Number(resp));
    $("select#rcpquery_listmode_str").change(queryListmodeChange);
}

// Handle a hit on the header (backtome link or list selector) by firing off a query-update request
function queryheaderHit(form) {
    var resp = jQuery.ajax({
        type: "POST",
        url: form.action,
        data: "element=querylist_header&" + $(form).serialize(),
        // Submit the data from the form
        dataType: "html",
        success: queryheaderUpdate
    });
}

// Callback for replacing the recipe list header when the update returns
function queryheaderUpdate(resp, succ, xhr) {
    // Just slam the HTML--if any--in there. (Nil response => leave unchanged.)
    if (resp != "") {
        $('#querylist_header').replaceWith(resp);
        // Replace the hit-handler
        $("select#rcpquery_owner_id").change(queryownerChange);
    }
}

// Called when a tab loads => fit any pics in their frames
function queryTabOnLoad() {
    wdwFitImages();
    $("select#rcpquery_listmode_str").change(queryListmodeChange);
}

// Called when a tab is selected
function queryTabOnSelect() {
    var x = 2;
}


// Make orphan tags draggable (not applicable for dynatree)
/*
function treatOrphanTags() {	
    $(".orphantag").multidraggable(
	{
        // containment: "#workpane",
        opacity: 0.7,
        zIndex: 1,
        revert: "invalid"
    }
	);
}
*/

// Called when the tag tabs load to set up dynatree, etc.
function tagTabsOnLoad(event, info) {
    // Set up handler for tag typing
    // Since apparently the entry panel isn't set up when the tabs have loaded,
    // we need to set a timer to periodically look for them.
    var TO = window.setInterval(function() {
        var idselector = "#tag_entry" + info.index;
        // var source = '/tags/match?morph=strings&tabindex=' + info.index;
        // var source = '/tags.json';
        if ($(idselector).length > 0) {
            // $(idselector).autocomplete({source:source, search:tagTabsTakeTyping})
            $(idselector).bind('change', tagTabsTakeTyping);
            $(idselector).bind('keypress', tagTabsTakeTyping);
            $(idselector).bind('input', tagTabsTakeTyping);
            window.clearInterval(TO);
        }
		setupDynatree();
    },
    100);
 	// treatOrphanTags();
    // , helper:"clone"
    $(".tag_tab").droppable({
        drop: tagTabTakeDropFromDynatree,
        hoverClass: "dropGlow",
        tolerance: "pointer"
    });
}

function tagTabTakeDrop(event, info) {
    var drug = info.draggable;
    drug = $(".ui-draggable-dragging");
    // First thing is, collect an array of ids for the dragged elements
    var ids = [];
    var id;
    drug.each(function() {
        var id;
        if (id = (this.getAttribute("id"))) {
            ids.push(id);
        }
    });
    if (ids.length < 1) {
        return;
    }

    // Now get the index of the tab being dropped upon
    var hit = $(this);
    var parent = $(this).parent();
    var children = parent.children();
    var toIndex = $.inArray(this, children);

    // By the way, what tab is active now?
    var fromIndex = $("#tags_tabset").tabs('option', 'selected');

    // Fire off an Ajax call notifying the server of the (re)classification
    jQuery.get("/tags/typify",
    {
        fromtabindex: fromIndex,
        totabindex: toIndex,
        tagids: ids
    },
    function(body, status, instance) {
        // Use the returned IDs to remove the entries from the list
        // First, generate a query string for jQuery from the returned ids
        var refstr = body.map(function(elmt, ix, arr) { return "#" + elmt; }).join(',');
        $(refstr).remove();
        // Could be adding the strings to the target tab, if it's loaded
    },
    "json");
}

function tagTabTakeDropFromDynatree(event, info) {
    var drug = info.draggable;
    drug = $(".ui-draggable-dragging");
    // First thing is, collect an array of ids for the dragged elements
    var ids = [];
    var id;
	var dtNode = $(drug[0]).data("dtSourceNode")
	ids[0] = dtNode.data.key

    // Now get the index of the tab being dropped upon
    var hit = $(this);
    var parent = $(this).parent();
    var children = parent.children();
    var toIndex = $.inArray(this, children);

    // By the way, what tab is active now?
    var fromIndex = $("#tags_tabset").tabs('option', 'selected');

	dtNode.remove();
    // Fire off an Ajax call notifying the server of the (re)classification
    jQuery.get("/tags/typify",
    {
        fromtabindex: fromIndex,
        totabindex: toIndex,
        tagids: ids
    },
    function(body, status, instance) {
        // Use the returned IDs to remove the entries from the list
        // First, generate a query string for jQuery from the returned ids
        // var refstr = body.map(function(elmt, ix, arr) { return "#" + elmt; }).join(',');
        // $(refstr).remove();
        // Could be adding the strings to the target tab, if it's loaded
		var wdwData = getWdwData(); // Get structure containing tabindex, listid and treeid names
		$(wdwData.listTextElement).focus();
    },
    "json");
}

function getWdwData() {
	var tabindex = $("#tags_tabset").tabs('option', 'selected');
	return {
		tabindex: tabindex,
		tagListSelector: "#taglist"+tabindex,
		referentTreeSelector: "#referenttree"+tabindex,
		listTextElement: "#tag_entry"+tabindex
	}
}

// Respond to typing into the search box: hit the server for a list of matching keys
//  tabindex: index of this tab on the tags page
//  typing: the string typed thus far
//	makeormatch: used to force existence of this exact key
//  url: http string used to hit the server
function tagTabsTakeTyping(event, info) {
    // Send current string to server
    // Get back replacement list of keys
    var id = event.srcElement.id;
    // var tabindex = id.match(/(\D*)(\d*)$/)[2];
    // Tab's index ends the id string
    // var taglistSelector = "#taglist" + tabindex;
    var typing = event.srcElement.value;
    var makeormatch = (event.type == "change") && ($(this).attr("lastCharTyped") == 13);
	// For keypress events, just record the last character typed, for future reference
	if(event.type == "keypress") {
		$(this).attr("lastCharTyped", event.keyCode);
		return;
	}
	if(makeormatch) { 
		debugger; 
	}
	var wdwData = getWdwData(); // Get structure containing tabindex, listid and treeid names
	// Reload the dynatree to reflect the typed string
	$(wdwData.tagListSelector).dynatree("option", 
		"initAjax", {
			   url: "/tags/match",
               data: {
					tabindex: wdwData.tabindex,
					unbound_only: true,
					response_format: "dynatree",
					term: typing,
					makeormatch: makeormatch
               }
    });
	var tree = $(wdwData.tagListSelector).dynatree("getTree");
	tree.reload();
	/*
	var resp = jQuery.get(
		"/tags/match",
	    {
	        tabindex: tabindex,
	        term: typing,
	        makeormatch: makeormatch
	    },
	    function(body, status, instance) { 
			$(taglistSelector).replaceWith(body); 
			treatOrphanTags();
		},
	    "html"
	    );
	*/
}

// Here's how to setup a wrapper method:
/*
(function($){
  $.fn.mycheck = function() {
	var val = $("#tags_tabset").tabs('option', 'selected');
	debugger;
    return 1;
  };
})(jQuery);
*/

function setupDynatree() {
	// $(".taglist").mycheck();
	
	var wdwData = getWdwData(); // Get structure containing tabindex, listid and treeid names
	$(wdwData.tagListSelector).dynatree({
	    initAjax: {url: "/tags/match",
	               data: {
						  tabindex: wdwData.tabindex,
						  unbound_only: true,
						  response_format: "dynatree"
	                      }
	               },
		autoFocus: false, // So's not to lose focus upon text input
	    dnd: {
	      onDragStart: function(node) {
	        /** This function MUST be defined to enable dragging for the tree.
	         *  Return false to cancel dragging of node.
	         */
	        logMsg("tree.onDragStart(%o)", node);
	        if(node.data.isFolder)
	          return false;
	        return true;
	      },
	      onDragStop: function(node) {
	        logMsg("tree.onDragStop(%o)", node);
	      }
	    }		
	});
    $(wdwData.referentTreeSelector).dynatree({	// XXX Currently only the 0 tab has a referent tree
	    initAjax: {url: "/referents",
	               data: {key: 0, // Optional arguments to append to the url
	                      mode: "all"
	                      }
	               },
        onActivate: function(node) {
            // A DynaTreeNode object is passed to the activation handler
            // Note: we also get this event, if persistence is on, and the page is reloaded.
            alert("You activated " + node.data.title);
        },
	    onLazyRead: function(node){
	        node.appendAjax({url: "/referents",
	                           data: {"key": node.data.key, // Optional url arguments
	                                  "mode": "all"
	                                  }
	                          });
	    },
        dnd: {
            onDragStart: function(node) {
                /** This function MUST be defined to enable dragging for the tree.
                 *  Return false to cancel dragging of node.
                 */
                logMsg("tree.onDragStart(%o)", node);
                return true;
            },
	        autoExpandMS: 300, // Expand nodes after n milliseconds of hovering.
	        preventVoidMoves: true, // Prevent dropping nodes 'before self', etc.
			onDragEnter: function(targetNode, sourceNode) {
				logMsg("tree.onDragEnter(%o)", sourceNode);
				return true;
			},
            onDrop: function(node, sourceNode, hitMode, ui, draggable) {
                /** This function MUST be defined to enable dropping of items on
                 * the tree.
                 */
				/* We're dropping a node from either the tag list or the tree itself.
				   If the source is the tag list, we send JSON to create a new referent
					to drop into place.
				   If the source is the tree itself, we send JSON to relocate the referent
					in the hierarchy.
				*/
                logMsg("tree.onDrop(%o, %o, %s)", node, sourceNode, hitMode);
				var sourceTreeName = sourceNode.parent.tree.divTree.className;
				var nodeTreeName = node.parent.tree.divTree.className;
				if(sourceTreeName == nodeTreeName) {
					// Notify the server of the change in hierarchy
					function catchReferent( xhr, status ) {
						debugger;
						if(status == "success") {
							sourceNode.move(node, hitMode);
						}
					}
				  	$.ajax({
							type:"POST",
							url:"/referents/"+sourceNode.data.key,
							data: {_method:'PUT', referent: {parent_id: node.data.key, mode:hitMode }},
							dataType: 'json',
							complete: catchReferent
						});
				} else {
					/* In moving a tag into the referent tree, we're either dropping the tag ONTO a referent
					    (making it an expression for the ref), or dropping it somewhere in the tree. The former
					    is denoted by a hitMode of "over".
					 need to go back to the
						server to 1) notify it of the new referent, and 2) get the referent
						key for inserting into the tree.
					  # POST /referents.json??tagid=1&mode={over,before,after}&target=referentid
					*/
					function catchReferent(response, status, xhr) {
						if(status == "success") {
							if(response[0].key > 0) { // 0 key means no new node
								var copynode = sourceNode.toDict(true, function(dict){
								  // dict.title = "Copy of " + dict.title;
								  // delete dict.key; // Remove key, so a new one will be created
								});
								copynode.key = response[0].key;
						        if(hitMode == "over"){
						          // Append as child node
						          node.addChild(copynode);
						          // expand the drop target
						          node.expand(true);
						        }else if(hitMode == "before"){
						          // Add before this, i.e. as child of current parent
						          node.parent.addChild(copynode, node);
						        }else if(hitMode == "after"){
						          // Add after this, i.e. as child of current parent
						          node.parent.addChild(copynode, node.getNextSibling());
						        }
							} else {
								// Didn't create new node b/c we just dropped term onto it
								// Redraw the target node to reflect changes
								node.setTitle(response[0].title);
							}
			                sourceNode.remove();
				        }
					}
				  	$.post("/referents",
						{tagid:sourceNode.data.key, mode:hitMode, target:node.data.key },
						catchReferent,
						"json");
				}
            }
        },
        persist: true
    });
}


// Check that the images in a window have been loaded, fitting them into
// their frames when the size is available.
function wdwFitImages() {
    var TO = window.setInterval(function() {
        var allDone = true;
        $("img.fitPic").each(function() {
            allDone = fitImage(this) && allDone;
        });
        if (allDone) {
            window.clearInterval(TO);
        }
    },
    100);
}

function fitImage(img) {

    if (!img.complete) {
        return false;
    }

    var width = img.parentElement.clientWidth;
    var height = img.parentElement.clientHeight;

    var aspect = img.width / img.height;
    // 'shrinkage' is the scale factor, offsets are for centering the result
    var shrinkage,
    offsetX = 0,
    offsetY = 0;
    if (aspect > width / height) {
        // If the image is wider than the frame
        // Shrink to just fit in width
        shrinkage = width / img.width;
        offsetY = (height - img.height * shrinkage) / 2;
    } else {
        // Shrink to just fit in height
        shrinkage = height / img.height;
        offsetX = (width - img.width * shrinkage) / 2;
    }
    // Scale the image dimensions to fit its parent's box
    // img.width *= shrinkage;
    $(img).css("width", img.width * shrinkage);
    img.style.position = "relative";
    $(img).css("top", offsetY);
    $(img).css("left", offsetX);
    $(img).css("visibility", "visible");
    return true;
}

// Callback when token set changes
function tokenChangeCallback(hi, li) {
    var x = 2;
    queryformHit(this[0].form);
}

// NOT YET GUARANTEED
// Responder for link to return to the user's list
function backToMe(uid) {
    debugger;
    var x = 2;
}

// Callback when query text changes
// function textChangeCallback( ) {
// var x = 2;
// queryformHit(this[0].form);
// }
function alertIframeSelection() {
    var iframe = document.getElementById("viewframe");
    alert(getIframeSelectionText(iframe));
};

function alertSelectionText() {
    var editor_body = self.window.document;
    var range;

    if (editor_body.getSelection()) {
        range = editor_body.getSelection();
        alert(range.toString());
    } else if (editor_body.selection.createRange()) {
        range = editor_body.selection.createRange();
        alert(range.text);
    } else return;
}

function makeIframeSelectionRed() {
    var editor_body = self.window.document;
    var range;

    if (editor_body.getSelection()) {
        range = editor_body.getSelection();
    } else if (editor_body.selection.createRange()) {
        range = editor_body.selection.createRange();
    } else return;
    range.pasteHTML("<span style='color: red'>" + range.htmlText + "</span>");

    // var range = document.getElementById("myid").contentWindow.document.selection.createRange();
    // range.pasteHTML("<span style='color: red'>" + range.htmlText + "</span>");
}

function remove_fields(link) {
    $(link).prev("input[type=hidden]").val("1");
    $(link).closest(".fields").hide();
    queryformHit($("form")[0]);
}

function add_fields(link, association, content) {
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g")
    $(link).parent().before(content.replace(regexp, new_id));
}

$(function() {
    $("#recipe_tag_tokens").tokenInput("/tags/match.json", {
        crossDomain: false,
        hintText: "Type your own tag(s) for the recipe",
        prePopulate: $("#recipe_tag_tokens").data("pre"),
        theme: "facebook",
        allowCustomEntry: true
    });
    $("#rcpquery_tag_tokens").tokenInput("/tags/match.json", {
        crossDomain: false,
        hintText: "Type tags to look for",
        prePopulate: $("#rcpquery_tag_tokens").data("pre"),
        theme: "facebook",
        onAdd: tokenChangeCallback,
        onDelete: tokenChangeCallback,
        allowCustomEntry: true
    });
});

function add_rating(link, association, content) {
    // Get the selected option
    var opts = link.options;
    var selection_ix;
    for (var i = 0; i < opts.length; i++) {
        if (opts[i].selected) {
            selection_ix = i;
        }
    }
    // We expect to get the scale's ID to initialize the fields
    var scale_id_sub = new RegExp("rating_scale_id", "g")

    var rating_id_sub = new RegExp("new_" + association, "g")
    var rating_id = new Date().getTime();

    var name_sub = new RegExp("rating_rname", "g")
    var minlabel_sub = new RegExp("rating_minlabel", "g")
    var maxlabel_sub = new RegExp("rating_maxlabel", "g")

    var labels = opts[selection_ix].title.split(" to ");
    var scalename = opts[selection_ix].text;
    var scale_minlabel = labels[0];
    var scale_maxlabel = labels[1];
    // Substitute labels for the rating, then deploy the scale
    $(link).after(content.
    replace(rating_id_sub, rating_id).
    replace(name_sub, scalename).
    replace(minlabel_sub, scale_minlabel).
    replace(maxlabel_sub, scale_maxlabel).
    replace(scale_id_sub, opts[selection_ix].value));
    // The chosen value
    opts[selection_ix] = null;
    var radbtns = $('input[id^=\'rcpquery_ratings_attributes\']');
    $('input[id^=\'rcpquery_ratings_attributes\']').change(queryChange);
    // if(link.options.length < 2) {
    // Once the last rating is selected and deployed,
    // change the prompt and deactivate the control
    // opts[0].prompt = "No more scales to add";
    // debugger;
    // }
}

