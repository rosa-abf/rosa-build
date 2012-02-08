jQuery(document).ready(function(){

jQuery(".niceRadio").each(
/* Russsian comments deleted */
function() {
     
     changeRadioStart(jQuery(this));
     
});


});


function changeRadio(el)
/* 
	Russsian comments deleted
*/
{

	var el = el,
		input = el.find("input").eq(0);
	var nm=input.attr("name");
		
	jQuery(".niceRadio input").each(
	
	function() {
     
		if(jQuery(this).attr("name")==nm)
		{
			jQuery(this).parent().removeClass("radioChecked");
		}
	   
	   
	});					  
	
	
	if(el.attr("class").indexOf("niceRadioDisabled")==-1)
	{	
		el.addClass("radioChecked");
		input.attr("checked", true);
	}
	
    return true;
}

function changeVisualRadio(input)
{
/*
	Russsian comments deleted
*/
	var wrapInput = input.parent();
	var nm=input.attr("name");
		
	jQuery(".niceRadio input").each(
	
	function() {
     
		if(jQuery(this).attr("name")==nm)
		{
			jQuery(this).parent().removeClass("radioChecked");
		}
	   
	   
	});

	if(input.attr("checked")) 
	{
		wrapInput.addClass("radioChecked");
	}
}

function changeRadioStart(el)
/* 
	Russsian comments deleted <span class="niceRadio"><input type="radio" name="[name radio]" id="[id radio]" [checked="checked"] /></span>
	Russsian comments deleted
*/
{

try
{
var el = el,
	radioName = el.attr("name"),
	radioId = el.attr("id"),
	radioChecked = el.attr("checked"),
	radioDisabled = el.attr("disabled"),
	radioTab = el.attr("tabindex"),
	radioValue = el.attr("value");
	if(radioChecked)
		el.after("<span class='niceRadio radioChecked'>"+
			"<input type='radio'"+
			"name='"+radioName+"'"+
			"id='"+radioId+"'"+
			"checked='"+radioChecked+"'"+
			"tabindex='"+radioTab+"'"+
			"value='"+radioValue+"' /></span>");
	else
		el.after("<span class='niceRadio'>"+
			"<input type='radio'"+
			"name='"+radioName+"'"+
			"id='"+radioId+"'"+
			"tabindex='"+radioTab+"'"+
			"value='"+radioValue+"' /></span>");
	
	/* Russsian comments deleted */		
	if(radioDisabled)
	{
		el.next().addClass("niceRadioDisabled");
		el.next().find("input").eq(0).attr("disabled","disabled");
	}
	
	/* Russsian comments deleted */		
	el.next().bind("mousedown", function(e) { changeRadio(jQuery(this)) });
	if(jQuery.browser.msie)	el.next().find("input").eq(0).bind("click", function(e) { changeVisualRadio(jQuery(this)) });	
	else el.next().find("input").eq(0).bind("change", function(e) { changeVisualRadio(jQuery(this)) });
	el.remove();
}
catch(e)
{
	// Russsian comments deleted
}

    return true;
}
