/*
* Copyright (c) 2021 - Today Allie Law (ChildishGiant)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Allie Law <allie@cloverleaf.app>
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
            videos.sink = "1";

            var brave = new Response ();
            brave.volume = 100;
            brave.balance = 0;
            brave.muted = true;
            brave.icon = "brave-browser";
            brave.name = "Brave";
            brave.is_mono = false;
            brave.sink = "1";

            var music = new Response ();
            music.volume = 75;
            music.muted = false;
            music.icon = "io.elementary.music";
            music.name = "Music";
            music.is_mono = true;
            music.sink = "1";

            return {videos, brave, music};

        case "varied_lengths":

            var app1 = new Response ();
            app1.name = "App 1";

            var app2 = new Response ();
            app2.name = "App with a longer name";

            var app3 = new Response ();
            app3.name = "App with a really long name";

            return {app1, app2, app3};


        default:
            stdout.printf ("Unknown mockup style");
            break;
    }

    return {};
}
