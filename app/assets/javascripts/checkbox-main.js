function changeCheck(el)
/* 
	Russsian comments deleted
	el - span
	input
*/
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
/*
	Russsian comments deleted
*/
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
	/*
		 Russsian comments deleted
		 Russsian comments deleted
	 */
	startChangeCheck(document.getElementById("niceCheckbox1"));
	startChangeCheck(document.getElementById("niceCheckbox2"));
	startChangeCheck(document.getElementById("niceCheckbox3"));
	startChangeCheck(document.getElementById("niceCheckbox4"));
}