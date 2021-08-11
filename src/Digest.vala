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

private double lerp (double a, double b, double t) {
    return (1.0 - t) * a + b * t;
}

private double inverse_lerp (double a, double b, double v) {
    return (v - a) / (b - a);
}

private double remap (double i_min, double i_max, double o_min, double o_max, double v) {
    double t = inverse_lerp (i_min, i_max, v);
    return lerp (o_min, o_max, t);
}

public class Response : GLib.Object {

    public string index;
    public int volume;
    public float balance;
    public bool muted;
    public string icon = "application-default-icon"; // Or should it be application-x-executable?
    public string name;
    public bool is_mono = true;
    public string sink;

}


public static Response[] digester () {

        string sinks;
        string ls_stderr;
        int ls_status;

        try {

            //  Get a list of all apps using audio
            //  get just the info we want
            Process.spawn_command_line_sync (
                "env LANG=C pactl list sink-inputs",
                out sinks,
                out ls_stderr,
                out ls_status
            );

            Regex id_pattern = new Regex (
                "Sink Input #(.*)",
                RegexCompileFlags.MULTILINE
            );
            Regex stereo_pattern = new Regex (
                "Volume:.* (\\d{1,3})%.* (\\d{1,3})%",
                RegexCompileFlags.MULTILINE
            );
            Regex mono_pattern = new Regex (
                "Volume: .* (\\d{1,3})%",
                RegexCompileFlags.MULTILINE
            );
            Regex balance_pattern = new Regex (
                "balance (-?\\d\\.\\d\\d)",
                RegexCompileFlags.MULTILINE
            );
            Regex muted_pattern = new Regex (
                "Mute: ([a-z]*)",
                RegexCompileFlags.MULTILINE
            );
            Regex icon_name_pattern = new Regex (
                "application\\.icon_name = \"([a-z-\\.]*)\"$",
                RegexCompileFlags.MULTILINE
            );
            Regex app_name_pattern = new Regex (
                "application\\.name = \"(.*)\"$",
                RegexCompileFlags.MULTILINE
            );
            Regex sink_pattern = new Regex (
                "Sink: (\\d*)",
                RegexCompileFlags.MULTILINE
            );

            Response[] apps = {};
            foreach (string line in sinks.split ("\n")) {
                line = line.strip ();

                MatchInfo match_id;
                if (id_pattern.match (line, 0, out match_id)) {
                    Response app = new Response ();
                    var id = match_id.fetch (1);
                    app.index = id;
                    apps += app;
                }

                //  Match mono before stereo so that stero overrides it
                MatchInfo match_mono;
                if (mono_pattern.match (line, 0, out match_mono)) {
                    var volume = match_mono.fetch (1);
                    apps[apps.length - 1].volume = int.parse (volume);
                    debug ("Mono: %s", volume);
                }

                MatchInfo match_stereo;
                if (stereo_pattern.match (line, 0, out match_stereo)) {
                    var volumes = match_stereo.fetch_all ();
                    apps[apps.length - 1].is_mono = false; // Mark app as stereo
                    var left = int.parse (volumes[1]);
                    var right = int.parse (volumes[2]);

                    //  Re-map volumes to 100%
                    //  This keeps the correct balance but tops out at 100%
                    if (left > 100 || right > 100) {
                        debug ("Volume should be between 0 and 100, but was " +
                        left.to_string () + " and " + right.to_string ());
                        var max = int.max (left, right);

                        left = (int)remap (0.0, max, 0.0, 100.0, left);
                        right = (int)remap (0.0, max, 0.0, 100.0, right);
                    }

                    debug ("Stereo: " + left.to_string () + " " + right.to_string ());

                    apps[apps.length - 1].volume = int.max (left, right);
                }

                MatchInfo match_balance;
                if (balance_pattern.match (line, 0, out match_balance)) {
                    var balance = match_balance.fetch (1);
                    debug ("Balance: %s", balance);
                    apps[apps.length - 1].balance = float.parse (balance);
                }

                MatchInfo match_muted;
                if (muted_pattern.match (line, 0, out match_muted)) {
                    var muted = match_muted.fetch (1);

                    if (muted == "yes") {
                        apps[apps.length - 1].muted = true;
                    } else {
                        apps[apps.length - 1].muted = false;
                    }
                }

                MatchInfo match_icon_name;
                if (icon_name_pattern.match (line, 0, out match_icon_name)) {
                    apps[apps.length - 1].icon = match_icon_name.fetch (1);
                }

                MatchInfo match_app_name;
                if (app_name_pattern.match (line, 0, out match_app_name)) {
                    apps[apps.length - 1].name = match_app_name.fetch (1);
                    debug ("App name: %s", match_app_name.fetch (1));
                }

                MatchInfo match_sink;
                if (sink_pattern.match (line, 0, out match_sink)) {
                    apps[apps.length - 1].sink = match_sink.fetch (1);
                }
            }

            return apps;

        } catch (Error e) {
            error ("Error: %s\n", e.message);
        }

    }
