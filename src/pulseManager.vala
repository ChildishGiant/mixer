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

            context.subscribe (Context.SubscriptionMask.SINK_INPUT | Context.SubscriptionMask.SINK);
            context.set_subscribe_callback (this.subscribe_cb);

            this.update_all_sink_inputs ();
            this.update_all_sinks ();
        }

    }

    private void subscribe_cb (Context local_context, Context.SubscriptionEventType event, uint32 id) {

        //  debug ("Subscription event %s", );

        switch (event) {
            case Context.SubscriptionEventType.SINK:
                debug ("Updating outputs");
                sinks_updated (get_outputs ());
                break;

            case Context.SubscriptionEventType.CARD:
                debug ("CARD");
                break;
            case Context.SubscriptionEventType.CHANGE:
                debug ("CHANGE");
                break;
            case Context.SubscriptionEventType.CLIENT:
                debug ("CLIENT");
                break;
            case Context.SubscriptionEventType.FACILITY_MASK:
                debug ("FACILITY_MASK");
                break;
            case Context.SubscriptionEventType.MODULE:
                debug ("MODULE");
                break;
            case Context.SubscriptionEventType.REMOVE:
                debug ("REMOVE");
                break;
            case Context.SubscriptionEventType.SAMPLE_CACHE:
                debug ("SAMPLE_CACHE");
                break;
            case Context.SubscriptionEventType.SERVER:
                debug ("SERVER");
                break;
            case Context.SubscriptionEventType.SOURCE:
                debug ("SOURCE");
                break;
            case Context.SubscriptionEventType.SOURCE_OUTPUT:
                debug ("SOURCE_OUTPUT");
                break;
            case Context.SubscriptionEventType.TYPE_MASK:
                debug ("TYPE_MASK");
                break;

            case Context.SubscriptionEventType.SINK_INPUT:
            default:
                //  Fall-through because for some reason there's a lot of undefined events
                get_apps ();

                break;
        }
    }

    private void sink_input_info_cb (Context local_context, SinkInputInfo? sink_input, int eol) {

        if (eol == 1) {
            sink_inputs_done = true;
            return;
        }

        if (sink_input != null) {
            //  Add to list of apps
            var response = digest (sink_input);
            this.sink_inputs += response;
        }

    }

    private void sink_info_cb (Context local_context, SinkInfo? sink, int eol) {


        if (sink != null) {
            // debug("Sink info: %s", sink.proplist.to_string());

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

    private void success_cb (Context c, int success) {
        if (success == 0) {
            debug ("Failed: %s", c.errno(  ).to_string(  ));
        }
    }

    public void set_volume (Response app, Gtk.Scale balance_scale, Gtk.Scale volume_scale) {

        debug ("Setting volume and balance for %s (%i)", app.name, (int)app.index);

        var balance = (float)balance_scale.get_value ();
        var volume = volume_scale.get_value ();
        var cvol = CVolume ();

        //  Set volume
        debug ("Volume input: %s", volume.to_string ());
        var vol = PulseAudio.Volume.sw_from_linear (volume);
        cvol.set (app.channel_map.channels, vol);
        debug ("Volume: %s", vol.to_string ());

        // Set balance
        cvol.set_balance (app.channel_map, balance);
        debug ("Balance: %s", cvol.get_balance (app.channel_map).to_string ());


        context.set_sink_input_volume (app.index, cvol, success_cb);
    }

    public void set_mute (Response app, bool mute) {
        debug ("%s %s", mute ? "Muting" : "Unmuting", app.name);
        context.set_sink_input_mute (app.index, mute, success_cb);
    }

    public void move (Response app, Sink sink) {
        debug ("Moving %s to %s", app.name, sink.port_description);
        context.move_sink_input_by_index (app.index, sink.index, success_cb);
    }

}
