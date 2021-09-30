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
    public double volume;
    public float balance;
    public bool muted;
    public string icon = "application-default-icon"; // Or should it be application-x-executable?
    public string name;
    public bool is_mono = true;
    public uint32 sink;
    public PulseAudio.ChannelMap channel_map;

}


public Response digest (PulseAudio.SinkInputInfo sink_input) {

    //  debug(sink_input.proplist.to_string());

    Response app = new Response ();

    //  Set the index
    app.index = sink_input.index;
    debug ("Index: %d", (int)app.index);

    //  Set mute state
    if (sink_input.mute == 0) {
        app.muted = false;
    } else {
        app.muted = true;
    }
    debug ("\t Mute: %s", app.muted.to_string ());

    //  Set mono
    app.is_mono = !sink_input.channel_map.can_balance ();
    debug ("\t Mono: %s", (!sink_input.channel_map.can_balance ()).to_string ());

    //  Set volume
    var volumes = sink_input.volume.values;
    var left = volumes[0].sw_to_linear ();
    var right = volumes[1].sw_to_linear ();
    app.volume = double.max (left, right);

    debug ("\t Volume: %f", app.volume);

    //  Set balance
    app.balance = sink_input.volume.get_balance (sink_input.channel_map);
    debug ("\t Balance: %f", app.balance);

    //  Set icon
    if (sink_input.proplist.gets ("application.icon_name") != null) {
        app.icon = sink_input.proplist.gets ("application.icon_name");
    }
    debug ("\t Icon: %s", app.icon);

    //  Set name
    app.name = sink_input.proplist.gets ("application.name");
    debug ("\t Name: %s", app.name);

    //  Set sink
    app.sink = sink_input.sink;

    //  Set channel map
    app.channel_map = sink_input.channel_map;

    return app;

}
