var DropDownMenu = function() {
  this.timeout = 500;
  this.close_timer	= 0;
  this.menu_item	= 0;
};
// open hidden layer
DropDownMenu.prototype.open = function(id) {
	// cancel close timer
	this.cancel_close_time();

	// close old layer
	if(this.menu_item) this.menu_item.hide();

	// get new layer and show it
	this.menu_item = $("#" + id);
  this.menu_item.show();
};

// close showed layer
DropDownMenu.prototype.close = function() {
	if (this.menu_item) this.menu_item.hide();
};

// go close timer
DropDownMenu.prototype.close_time = function() {
  var _this = this;
  function mclose() {
    return _this.close();
  }
	this.close_timer = window.setTimeout(mclose, this.timeout);
}; 

// cancel close timer
DropDownMenu.prototype.cancel_close_time = function() {
	if(this.close_timer)
	{
		window.clearTimeout(this.close_timer);
		this.close_timer = null;
	}
};

var menu = new DropDownMenu();
document.onclick = menu.close;
