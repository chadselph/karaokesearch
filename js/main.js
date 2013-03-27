var Songs = [];

$.get("data/latest.json", function(data) {
    Songs = data.sort(function (a, b) {
        if(a.artist < b.artist) return -1;
        else if(b.artist < a.artist) return 1;
        else if(a.title < b.title) return -1;
        else if(b.title < a.title) return 1;
        else return 0;
    });
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

window.addEventListener('load', function() {
    window.setTimeout(function() {
        var bubble = new google.bookmarkbubble.Bubble();

        var parameter = 'bmb=1';

        bubble.hasHashParameter = function() {
            return window.location.hash.indexOf(parameter) != -1;
        };

        bubble.setHashParameter = function() {
            if (!this.hasHashParameter()) {
                window.location.hash += parameter;
            }
        };

        bubble.showIfAllowed();
    }, 1000);
}, false);
