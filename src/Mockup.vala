/*
 * Copyright 2021 Allie Law <allie@cloverleaf.app>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public static Response[] mockup_apps (string style) {

    switch (style) {
        case "screenshot":
            var videos = new Response ();
            videos.volume = 100;
            videos.balance = 0;
            videos.muted = false;
            videos.icon = "io.elementary.videos";
            videos.name = "Videos";
            videos.is_mono = false;
            videos.sink = 1;

            var brave = new Response ();
            brave.volume = 100;
            brave.balance = 0;
            brave.muted = true;
            brave.icon = "brave-browser";
            brave.name = "Brave";
            brave.is_mono = false;
            brave.sink = 1;

            var music = new Response ();
            music.volume = 75;
            music.muted = false;
            music.icon = "io.elementary.music";
            music.name = "Music";
            music.is_mono = true;
            music.sink = 1;

            return {videos, brave, music};

        case "varied_lengths":

            var app1 = new Response ();
            app1.name = "App 1";

            var app2 = new Response ();
            app2.name = "App with a longer name";

            var app3 = new Response ();
            app3.name = "App with a really long name";

            var app4 = new Response ();
            app4.name = "App with a far too long name that was probably just the binary name and it has a git hash in and everything";

            return {app1, app2, app3, app4};

        case "too_many":

            Response[] to_return = {};

            for (var i = 0; i < 50; i++) {
                var to_add = new Response ();
                to_add.name = "App " + i.to_string ();

                if (i % 3 == 0) {
                    to_add.icon = "emblem-error";
                } else

                if (i % 2 == 0) {
                    to_add.icon = "emblem-enabled";
                } else {
                    to_add.icon = "emblem-mixed";
                };

                to_return += to_add;
            }

            return to_return;

        default:
            return {};
    }
}


public static Sink[] mockup_outputs () {


    var sink1 = new Sink ();
    sink1.index = 0;
    sink1.port_description = "Ellesmere HDMI Audio [Radeon RX 470/480 / 570/580/590] Digital Stereo (HDMI 4)";
    sink1.port_name = "HDMI/DisplayPort 4";

    var sink2 = new Sink ();
    sink2.index = 1;
    sink2.port_description = "Family 17h (Models 00h-0fh) HD Audio Controller Analogue Stereo";
    sink2.port_name = "Line Out";

    return {sink1, sink2};
}
