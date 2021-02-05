'use strict';

angular.module('angular-i18n', []);
angular.module('angular-i18n', []).filter('i18n', ['$locale', function($locale) {
	return function(str) {
		var offset = 1;
		if (arguments[1] && arguments[1] === 'plural') {
			var n = arguments[2],
					plural;

			switch ($locale.id) {
				case 'en-us':
				case 'de-de':
				case 'es-es':
					plural = 0 + (n != 1);
					break;
				case 'ru-ru':
					plural = (n % 10 == 1 && n % 100 != 11 ? 0 : n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20) ? 1 : 2);
					break;
				case 'ar':
					plural = n == 0 ? 0 : n == 1 ? 1 : n == 2 ? 2 : n % 100 >= 3 && n % 100 <= 10 ? 3 : n % 100 >= 11 ? 4 : 5;
				default:
					plural = 0 + (n != 1);
			}

			if (_locales[$locale.id][str]) {
				str = _locales[$locale.id][str][plural] || str;
			}
			offset = 2;
		} else {
			str = _locales[$locale.id][str] || str;
		}

		for (var i = offset; i < arguments.length; i++) {
			str = str.split('%' + (i - offset + 1)).join(arguments[i]);
		}

		return str;
	}
}]);