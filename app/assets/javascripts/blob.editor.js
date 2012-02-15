(function($) {
    $.BlobEditor = function() {
        $.BlobEditor.Placeholder.add($('#gollum-editor-edit-summary input'));
        $('#gollum-editor form[name="blob-editor"]').submit(function( e ) {
            e.preventDefault();
            $.BlobEditor.Placeholder.clearAll();
            //debug('submitting');
            $(this).unbind('submit');
            $(this).submit();
        });
    };

    $.BlobEditor.Placeholder = $.GollumPlaceholder;
})(jQuery);
