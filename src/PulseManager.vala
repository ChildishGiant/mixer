/*
 * Copyright 2021 Allie Law <allie@cloverleaf.app>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using PulseAudio;

public class Sink : GLib.Object {

    public int index;
    public string port_description;
    public string port_name;

}

public class PulseManager : Object {

    private GLibMainLoop loop;
    public Context context;
    private Response[] sink_inputs;
    private bool sink_inputs_done = true;
    private bool sinks_done = true;
    private Sink[] sinks;

    public signal void sinks_updated (Sink[] sinks);
    public signal void apps_updated (Response[] apps);


    public PulseManager () {

        loop = new GLibMainLoop ();
        context = new Context (loop.get_api (), null);
        context.set_state_callback (this.cstate_cb);
        context.set_subscribe_callback (this.subscribe_cb);
        //  this.context.subscribe(Context.SubscriptionMask.ALL);
        context.set_event_callback (this.on_pa_event);

        // Connect the context
        if (context.connect (null, Context.Flags.NOFAIL, null) < 0) {
                debug ( "pa_context_connect() failed: %s",
                    PulseAudio.strerror (context.errno ()));
        }
    }

    public void on_pa_event (Context local_context, string index, Proplist? mask) {
        debug ("Index %s", index);

        //  debug (mask.to_string());
    }

    public void cstate_cb (Context local_context) {

        debug ("Context state changed");

        Context.State state = local_context.get_state ();
        if (state == Context.State.UNCONNECTED) { debug ("state UNCONNECTED"); }
        if (state == Context.State.CONNECTING) { debug ("state CONNECTING"); }
        if (state == Context.State.AUTHORIZING) { debug ("state AUTHORIZING,"); }
        if (state == Context.State.SETTING_NAME) { debug ("state SETTING_NAME"); }
        if (state == Context.State.READY) { debug ("state READY"); }
        if (state == Context.State.FAILED) { debug ("state FAILED,"); }
        if (state == Context.State.TERMINATED) { debug ("state TERMINATED"); }

        if (state == Context.State.READY) {
            this.update_all_sink_inputs ();
            this.update_all_sinks ();
        }

    }

    private void subscribe_cb (Context local_context, Context.SubscriptionEventType event, uint32 id) {

        debug ("Subscription id %d", (int)id);

        //  debug (event.to_string());

    }

    private void sink_input_info_cb (Context local_context, SinkInputInfo? sink_input, int eol) {

        if (sink_input != null) {
            //  Add to list of apps
            var response = digest (sink_input);
            this.sink_inputs += response;
        }

        if (eol == 1) {
            sink_inputs_done = true;
        }
    }

    private void sink_info_cb (Context local_context, SinkInfo? sink, int eol) {


        if (sink != null) {
            //  debug("Sink info: %s", sink.proplist.to_string());

            var sink_response = new Sink ();

            //  Set index
            sink_response.index = (int)sink.index;
            debug ("Sink #%i", sink_response.index);

            //  Set description
            sink_response.port_description = sink.description;
            debug ("Description: %s", sink_response.port_description);

            //  Set active port
            sink_response.port_name = sink.active_port.name;
            debug ("Active port: %s", sink_response.port_name);


            this.sinks += sink_response;
        }

        if (eol == 1) {
            sinks_done = true;
        }
    }

    public void update_all_sink_inputs () {
        this.sink_inputs = {};
        this.sink_inputs_done = false;
        context.get_sink_input_info_list (sink_input_info_cb);
    }

    public void update_all_sinks () {
        this.sinks = {};
        this.sinks_done = false;
        context.get_sink_info_list (sink_info_cb);
    }

    public Response[] get_apps () {

        update_all_sink_inputs ();

        Timeout.add (5, () => {

            if (sink_inputs_done) {
                apps_updated (this.sink_inputs);
            }

            return !sink_inputs_done;
        });
        return this.sink_inputs;
    }

    public Sink[] get_outputs () {
        update_all_sinks ();

        Timeout.add (5, () => {

            if (sinks_done) {
                sinks_updated (this.sinks);
            }

            return !sinks_done;
        });

        return this.sinks;
    }

    public void set_volume (Response app, Gtk.Scale balance_scale, Gtk.Scale volume_scale) {

        //  var volumes = balance_volume (balance_scale.get_value (), volume_scale.get_value ());

        var balance = balance_scale.get_value ();
        var volume = volume_scale.get_value ();

        debug ("Setting volume for %s (%i)", app.name, (int)app.index);
        debug ("Balance: %s", balance.to_string ());
        debug ("Volume: %s", volume.to_string ());

        //  string percentages;
        var vol = CVolume ();
        var map = ChannelMap ();

        //  If the app is mono, only set one channel
        if (app.is_mono) {
            map = map.init_mono ();
            //  percentages = int.max (volumes[1], volumes[0]).to_string () + "%";
        } else {
            map = map.init_stereo ();
            //  percentages = volumes[1].to_string () + "% " + volumes[0].to_string () + "%";
        }

        vol.set_balance (map, (float)balance_scale.get_value ());

        //  vol.

        context.set_sink_input_volume (app.index, vol, (c, success) => {
            // Ran after the volume is set
            debug ("Success: %i", success);
            //  debug ("Volume set");
        });
    }

    //  Takes balance and volume, outputs left and right volumes
    //  private int[] balance_volume (double balance, double volume) {

    //      double l;
    //      double r;

    //      if (balance < 0) {
    //          l = (100 * balance) + 100;
    //          r = 100;
    //      } else if (balance > 0) {
    //          l = 100;
    //          r = (-100 * balance) + 100;

    //      }else {
    //          l = 100;
    //          r = 100;
    //      };

    //      int new_l = (int)(l * volume / 100);
    //      int new_r = (int)(r * volume / 100);

    //      return {new_l, new_r};
    //  }

    public void set_mute (Response app, bool mute) {
        debug ("%s %s", mute ? "Muting" : "Unmuting", app.name);
        context.set_sink_input_mute (app.index, mute);
    }

    public void move (Response app, Sink sink) {
        debug ("Moving %s to %s", app.name, sink.port_description);
        context.move_sink_input_by_index (app.index, sink.index);
    }

}
