function check_by_ids(ids) {
    for(var i = 0; i < ids.length; i++){
        $('#'+ids[i]).attr('checked', true);
    }
    return false;
}

function uncheck_by_ids(ids) {
    for(var i = 0; i < ids.length; i++){
        $('#'+ids[i]).attr('checked', false);
    }
    return false;
}
