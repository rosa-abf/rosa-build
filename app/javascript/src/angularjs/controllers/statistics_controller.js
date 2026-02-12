import { Chart } from 'chart.js/auto'

RosaABF.controller('StatisticsController', ['$scope', '$http', '$timeout', function($scope, $http, $timeout) {

  $scope.users_or_groups = null;
  $scope.range = 'last_30_days';
  $scope.range_start = $('#range_start').attr('value');
  $scope.range_end = $('#range_end').attr('value');
  $scope.loading = false;
  $scope.statistics = {};
  $scope.statistics_path = '/statistics';

  $scope.colors = [
    '56, 132, 158',
    '77, 169, 68',
    '241, 128, 73',
    '174, 199, 232'
    // '255, 187, 120',
    // '152, 223, 138',
    // '214, 39, 40',
    // '31, 119, 180'
  ];
  $scope.charts = {};

  $scope.dateOptions = {
    formatYear: 'yy',
    startingDay: 1
  };

  $scope.init = function() {
    $('#statistics-form .date_picker').datepicker({
      'dateFormat': 'yy-mm-dd',
      maxDate: 0,
      minDate: -366,
      showButtonPanel: true
    });

    $scope.update();
    return true;
  };

  $scope.$on("activate_stats_tab", function(event, args) {
    if (Object.keys($scope.statistics).length === 0) {
      $timeout($scope.init, 1000);
    }

    return true;
  });

  $scope.openRangeStart = function($event) {
    if ($scope.loading) {
      return;
    }
    $event.preventDefault();
    $event.stopPropagation();
    $scope.range_start_opened = true;
  };

  $scope.openRangeEnd = function($event) {
    if ($scope.loading) {
      return;
    }
    $event.preventDefault();
    $event.stopPropagation();
    $scope.range_end_opened = true;
  };

  $scope.prepareRange = function() {
    var range_start = new Date($scope.range_start);
    var range_end = new Date($scope.range_end);

    if (range_start > range_end) {
      var tmp = $scope.range_start;
      $scope.range_start = $scope.range_end;
      $scope.range_end = tmp;
    }
  };

  $scope.update = function() {
    if ($scope.loading) {
      return;
    }
    $scope.loading = true;
    $scope.statistics = {};

    $scope.prepareRange();
    $('.doughnut-legend').remove();

    var params = {
      range: $scope.range,
      range_start: $scope.range_start,
      range_end: $scope.range_end,
      users_or_groups: $scope.users_or_groups,
      format: 'json'
    };

    $http.get($scope.statistics_path, { params: params })
    .then(function(results) {
      $scope.statistics = results.data;
      $scope.loading = false;

      // BuildLists
      if ($scope.statistics.build_lists) {
        $scope.initBuildListsChart();
      }

      // PullRequests
      if ($scope.statistics.pull_requests) {
        $scope.initPullRequestsChart();
      }

      // Issues
      if ($scope.statistics.issues) {
        $scope.initIssuesChart();
      }

      // Commits
      if ($scope.statistics.commits) {
        $scope.initCommitsChart();
      }
    })
    .catch(function(data, status, headers, config) {
      console.log('error:', data, status, headers, config);
      $scope.loading = false;
    });
  };

  $scope.dateChart = function(id, collections) {
    var new_collections = $.grep(collections, function(c) {
      return c;
    });

    if (collections.length === new_collections.length) {
      if ($scope.charts[id]) {
        $scope.charts[id].destroy();
      }

      var points = collections[0];
      var factor = Math.floor(points.length / 45) + 1;

//      var tooltipTitles = [];
      var labels = _.map(points, function(d, index) {
        var x = d.x;
//        tooltipTitles.push(x);
        if (index % factor === 0) {
          return x;
        } else {
          return '';
        }
      });

      var datasets = _.map(collections, function(collection, index) {
        var data = _.map(collection, function(d) {
          return d.y;
        });

        var dataset = {
          backgroundColor: "rgba(" + $scope.colors[index] + ", 0.1)",
          pointBackgroundColor: "rgba(" + $scope.colors[index] + ", 1)",
          pointBorderColor: "#fff",
          tension: 0.4,
          data: data,
          fill: {
            target: 'origin',
            below: "rgba(" + $scope.colors[index] + ", 0.1)" //FIXME не работает берёт цвет линии
          }
        };

        return dataset;
      });

      var data = {
        type: 'line',
        data: {
          datasets: datasets,
          // We display only limited count of labels on X axis, but tooltips should have titles
          // See: Chart.js "Added by avokhmin"
          labels: labels
        },
        options: {
          responsive: true,
          plugins: {
            legend: {
              display: false
            },
            tooltip: {
              intersect: false
            }
          }
        }
      };

      var chart = $(id);
      chart.attr({
        width: chart.parent().width(),
        height: chart.parent().outerHeight()
      });

      $scope.charts[id] = new Chart(chart, data);
    }
  };

  $scope.initBuildListsChart = function() {
    $scope.dateChart('#build_lists_chart', [
      $scope.statistics.build_lists.build_started,
      $scope.statistics.build_lists.success,
      $scope.statistics.build_lists.build_error,
      $scope.statistics.build_lists.build_published
    ]);
  };

  $scope.initCommitsChart = function() {
    $scope.dateChart('#commits_chart', [
      $scope.statistics.commits.chart
    ]);
  };

  $scope.initPullRequestsChart = function() {
    $scope.dateChart('#pull_requests_chart', [
      $scope.statistics.pull_requests.open,
      $scope.statistics.pull_requests.merged,
      $scope.statistics.pull_requests.closed
    ]);
  };

  $scope.initIssuesChart = function() {
    $scope.dateChart('#issues_chart', [
      $scope.statistics.issues.open,
      $scope.statistics.issues.reopen,
      $scope.statistics.issues.closed
    ]);
  };

}]);

