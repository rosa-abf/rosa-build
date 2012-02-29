function disError(elem) {
  $("#hint").fadeOut("fast");
  if (document.getElementById("user_login").className=="registartion-input-error") {
    if (this.id=="user_login") {
      document.getElementById("user_login").className="registartion-input-focus";
    } else {
      document.getElementById("user_login").className="registartion-input-no-focus";
    }
  }
  if (document.getElementById("user_password").className=="registartion-input-error") {
   if (this.id=="user_password") {
      document.getElementById("user_password").className="registartion-input-focus";
    } else {
      document.getElementById("user_password").className="registartion-input-no-focus";
    }
  }
  buttonCheck();
}

function buttonCheck() {
  var login_default = document.getElementById("login_default").value;
  var pass_default = document.getElementById("password_default").value;
  if ((document.getElementById("user_login").value!="")&&(document.getElementById("user_login").value!=login_default)&&
       (document.getElementById("user_password").value!="")&&(document.getElementById("user_password").value!=pass_default)) {
    document.getElementById("btnLogin").className = "button";
  } else {
    document.getElementById("btnLogin").className = "button disabled";
  }
}

function changeCheck(el) {
  var el = el,
    input = el.getElementsByTagName("input")[0];

   if(input.checked) {
      el.style.backgroundPosition="0 0"; 
      input.checked=false;
   }
   else {
      el.style.backgroundPosition="0 -17px"; 
      input.checked=true;
   }
   return true;
}

function startChangeCheck(el) {
  var el = el,
    input = el.getElementsByTagName("input")[0];
  if(input.checked) { el.style.backgroundPosition="0 -17px"; }
  return true;
}

function startCheck() {
  startChangeCheck(document.getElementById("niceCheckbox1"));
}