function changeCheck(el)

{
     var el = el,
          input = el.getElementsByTagName("input")[0];
		
     if(input.checked)
     {
	     el.style.backgroundPosition="0 0"; 
		 input.checked=false;
     }
     else
     {
          el.style.backgroundPosition="0 -18px"; 
		  input.checked=true;
     }
     return true;
}
function startChangeCheck(el)

{
	var el = el,
          input = el.getElementsByTagName("input")[0];
     if(input.checked)
     {
          el.style.backgroundPosition="0 -18px";     
      }
     return true;
}

function startCheck()
{

	startChangeCheck(document.getElementById("niceCheckbox1"));
	startChangeCheck(document.getElementById("niceCheckbox2"));
	startChangeCheck(document.getElementById("niceCheckbox3"));
	startChangeCheck(document.getElementById("niceCheckbox4"));
}