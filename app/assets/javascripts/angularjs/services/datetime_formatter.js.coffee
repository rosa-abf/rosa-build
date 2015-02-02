DateTimeFormatter = ->
  UtcFormatter = (api_time) ->
    moment.utc(api_time * 1000).format "YYYY-MM-DD HH:mm:ss UTC"

  utc: UtcFormatter

angular
  .module("RosaABF")
  .service "DateTimeFormatter", DateTimeFormatter
