var Songs = [];

$.get("data/latest.json", function(data) {
    Songs = data;
    filter(Songs);
});

function search(query) {
    return Songs.filter(function (song) {
        var q = query.toLowerCase().trim().replace(/[^\w\s]/g, "");
        var haystack = formatSong(song).toLowerCase().replace(/[^\w\s]/g, "");
        return haystack.indexOf(q) != -1;
    });
}

function formatSong(song) {
    return song.artist + " - " + song.title;
}

function filter(results) {
    // limit to 100 results at a time
    for (var r in results.slice(0, 100)) {
        var result = results[r];
        $(".results ul").append(
            $("<li />").text(formatSong(result))
        );
    }
}

$(".search").live('keyup', (function () {
    var results = search(this.value);
    $(".results ul").empty();
    filter(results);
}));
