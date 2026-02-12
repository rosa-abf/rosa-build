/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

const images = require.context("../images", true);

import { $, jQuery } from 'jquery';
import { _locales } from "../src/locales.js.erb";

window.$ = $;
window.jQuery = jQuery;
window._locales = _locales;

require("angular")
require("angular-cookies")
require("angular-datepicker")
require("angular-loading-bar")
require("angular-route")
require("angular-resource")
require("angular-sanitize")
require("angular-ui-bootstrap")

require("bootstrap-datepicker")
require("bootstrap-typeahead")

require("ui-codemirror")

require("../src/lib/notify.js")
require("../src/lib/notify-bootstrap.js")
require("../src/lib/angular-moment.js")
require("../src/lib/angular-ui-bootstrap-tpls.min.js")
require("../src/lib/bootstrap-tooltip")

require("../src/custom-bootstrap-typeahead.js")

require("../src/angularjs/angular-config.js.erb")
require("../src/angularjs/angular-i18n.js")
require("../src/angularjs/angular-rails-csrf.js")
require("../src/angularjs/angular-templates.js")
require("../src/angularjs/build_lists/build_list_controller.js")
require("../src/angularjs/build_lists/build_lists_controller.js.erb")
require("../src/angularjs/build_lists/build_log_controller.js")
require("../src/angularjs/build_lists/new_build_list_controller.js")
require("../src/angularjs/comments/comment.js")
require("../src/angularjs/comments/comments_controller.js")
require("../src/angularjs/controllers/activity_controller.js")
require("../src/angularjs/controllers/advisories_controller.js")
require("../src/angularjs/controllers/datepicker_controller.js.erb")
require("../src/angularjs/controllers/git_tree_controller.js")
require("../src/angularjs/controllers/platforms_controller.js")
require("../src/angularjs/controllers/product_build_list_controller.js.erb")
require("../src/angularjs/controllers/profile_controller.js")
require("../src/angularjs/controllers/project_branches_controller.js")
require("../src/angularjs/controllers/project_repo_block_controller.js")
require("../src/angularjs/controllers/project_tags_controller.js")
require("../src/angularjs/controllers/projects_controller.js")
require("../src/angularjs/controllers/rosa_abf_controller.js")
require("../src/angularjs/controllers/statistics_controller.js")
require("../src/angularjs/directives/ng_confirm_click.js")
require("../src/angularjs/issues/issue.js")
require("../src/angularjs/issues/issue_controller.js")
require("../src/angularjs/issues/issues_controller.js")
require("../src/angularjs/labels/label.js")
require("../src/angularjs/labels/labels_controller.js")
require("../src/angularjs/mass_builds/mass_build_service.js")
require("../src/angularjs/mass_builds/new_mass_build_controller.js")
require("../src/angularjs/models/build_list.js.erb")
require("../src/angularjs/models/project.js")
require("../src/angularjs/models/project_ref.js")
require("../src/angularjs/platforms/automatic_metadata_regeneration_controller.js")
require("../src/angularjs/platforms/contents_controller.js")
require("../src/angularjs/platforms/platform_sys_repos_controller.js")
require("../src/angularjs/platforms/repository_projects_controller.js")
require("../src/angularjs/projects/collaborators_controller.js")
require("../src/angularjs/projects/project_schedule_controller.js")
require("../src/angularjs/pull_requests/pull_request.js")
require("../src/angularjs/pull_requests/pull_request_controller.js")
require("../src/angularjs/services/activity_filter.js")
require("../src/angularjs/services/collaborator.js")
require("../src/angularjs/services/compile_html.js")
require("../src/angularjs/services/confirm_message.js.erb")
require("../src/angularjs/services/datetime_formatter.js")
require("../src/angularjs/services/preview.js")
require("../src/angularjs/services/project.js")

require("../src/extra/diff.js")
require("../src/extra/diff_chevrons.js")
require("../src/extra/fork.js")
require("../src/extra/highlight.js")
require("../src/extra/pull.js")
require("../src/extra/scroller.js")

function setCookie (name, value, expires, path, domain, secure) {
  document.cookie = name + "=" + escape(value) +
    ((expires) ? "; expires=" + expires : "") +
    ((path) ? "; path=" + path : "") +
    ((domain) ? "; domain=" + domain : "") +
    ((secure) ? "; secure" : "");
}

$(document).ready(function() {
  $('.notify.alert button.close').click(function () {
    var exdate=new Date();
    exdate.setDate(exdate.getDate() + 365);
    var expires="expires="+exdate.toUTCString();
    setCookie("flash_notify_hash", FLASH_HASH_ID, expires);
  });

  $('.datetime_moment').each(function() {
    var mtime = moment($(this).attr('origin_datetime'), 'YYYY-MM-DD HH:mm Z');
    $(this).attr('title', mtime.utc().format('YYYY-MM-DD HH:mm:ss UTC'));
  });

  window.updateTime = function () {
    $('.datetime_moment').each(function() {
      var time = moment($(this).attr('origin_datetime'), 'YYYY-MM-DD HH:mm Z');
      $(this).html(time.format('D MMM YYYY, HH:mm') + ' (' + time.fromNow() + ')');
    });
  };

  updateTime();
  setInterval( updateTime, 15000 );

  // TODO refactoring
  $('#branch_selector').change(function() {
    var form = $('form#branch_changer');
    form.attr('action', $(this).val());
    form.submit();
  });

//  $('[data-toggle="tooltip"]').tooltip();
});

