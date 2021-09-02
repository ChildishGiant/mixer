/*
 * Copyright 2021 Allie Law <allie@cloverleaf.app>
 * SPDX-License-Identifier: GPL-3.0-or-later
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

    public uint32 index;
    public int volume;
    public float balance;
    public bool muted;
    public string icon = "application-default-icon"; // Or should it be application-x-executable?
    public string name;
    public bool is_mono = true;
    public uint32 sink;

}


public Response digest (PulseAudio.SinkInputInfo sink_input) {

    //  if (stereo_pattern.match (line, 0, out match_stereo)) {
    //      var volumes = match_stereo.fetch_all ();
    //      apps[apps.length - 1].is_mono = false; // Mark app as stereo
    //      var left = int.parse (volumes[1]);
    //      var right = int.parse (volumes[2]);

    //      //  Re-map volumes to 100%
    //      //  This keeps the correct balance but tops out at 100%
    //      if (left > 100 || right > 100) {
    //          debug ("Volume should be between 0 and 100, but was " +
    //          left.to_string () + " and " + right.to_string ());
    //          var max = int.max (left, right);

    //          left = (int)remap (0.0, max, 0.0, 100.0, left);
    //          right = (int)remap (0.0, max, 0.0, 100.0, right);
    //      }

    //      debug ("Stereo: " + left.to_string () + " " + right.to_string ());

    //      apps[apps.length - 1].volume = int.max (left, right);
    //  }


    //  debug(sink_input.proplist.to_string());

    Response app = new Response();

    app.index = sink_input.index;
    debug("Index: %d", (int)app.index);

    if (sink_input.mute == 0) {
        app.muted = false;
    } else {
        app.muted = true;
    }
    debug("\t Mute: %s", app.muted.to_string());


    app.balance = sink_input.volume.get_balance(sink_input.channel_map);
    debug("\t Balance: %f", app.balance);

    if (sink_input.proplist.gets("application.icon_name") != null) {
        app.icon = sink_input.proplist.gets("application.icon_name");
    }
    debug("\t Icon: %s", app.icon);

    app.name = sink_input.proplist.gets("application.name");
    debug("\t Name: %s", app.name);

    debug("\t Mono: %s", (!sink_input.channel_map.can_balance ()).to_string ());
    app.is_mono = !sink_input.channel_map.can_balance ();


    return app;

}
