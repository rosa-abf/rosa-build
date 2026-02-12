var DateTimeFormatter = function() {
  var UtcFormatter = function(api_time) {
    return moment.utc(api_time * 1000).format("YYYY-MM-DD HH:mm:ss UTC");
  };

  this.utc = UtcFormatter;
};

angular
  .module("RosaABF")
  .service("DateTimeFormatter", DateTimeFormatter);
