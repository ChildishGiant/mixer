/*
 * Copyright 2021 Allie Law <allie@cloverleaf.app>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using PulseAudio;

public class Sink : GLib.Object {

    public int index;
    public string description;
    public int active_port;

}

public class PulseManager : Object {

    private GLibMainLoop loop;
    private Context context;
    private Response[] sink_inputs;
    private bool sink_inputs_done = true;
    private bool sinks_done = true;
    private Sink[] sinks;

    public signal void sinks_updated (Sink[] sinks);
    public signal void apps_updated (Response[] apps);


    public PulseManager() {

        loop = new GLibMainLoop();
        context = new Context(loop.get_api(), null);
        context.set_state_callback(this.cstate_cb);
        context.set_subscribe_callback(this.subscribe_cb);
        //  this.context.subscribe(Context.SubscriptionMask.ALL);
        context.set_event_callback(this.on_pa_event);

        // Connect the context
        if (context.connect( null, Context.Flags.NOFAIL, null) < 0) {
                debug ( "pa_context_connect() failed: %s",
                    PulseAudio.strerror(context.errno()));
        }
    }

    public void on_pa_event(Context local_context, string index, Proplist? mask) {
        debug("Index %s", index);

        //  debug (mask.to_string());
    }

    public void cstate_cb(Context local_context){

        debug("Context state changed");

        Context.State state = local_context.get_state();
        if (state == Context.State.UNCONNECTED) { debug ("state UNCONNECTED"); }
        if (state == Context.State.CONNECTING) { debug ("state CONNECTING"); }
        if (state == Context.State.AUTHORIZING) { debug ("state AUTHORIZING,"); }
        if (state == Context.State.SETTING_NAME) { debug ("state SETTING_NAME"); }
        if (state == Context.State.READY) { debug ("state READY"); }
        if (state == Context.State.FAILED) { debug ("state FAILED,"); }
        if (state == Context.State.TERMINATED) { debug ("state TERMINATED"); }

        if (state == Context.State.READY) {
            this.update_all_sink_inputs();
            this.update_all_sinks();
        }

    }

    private void subscribe_cb(Context local_context, Context.SubscriptionEventType event, uint32 id) {

        debug("Subscription id %d", (int)id);

        //  debug (event.to_string());

    }

    private void sink_input_info_cb(Context local_context, SinkInputInfo? sink_input, int eol) {

        if (sink_input != null) {
            //  Add to list of apps
            var response = digest(sink_input);
            this.sink_inputs += response;
        }

        if (eol == 1) {
            sink_inputs_done = true;
        }
    }

    private void sink_info_cb(Context local_context, SinkInfo? sink, int eol) {


        if (sink != null) {
            //  debug("Sink info: %s", sink.proplist.to_string());
            var sink_response = new Sink();
            sink_response.index = (int)sink.index;
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

    public Response[] get_apps() {

        update_all_sink_inputs();

        Timeout.add(5, () => {

            if (sink_inputs_done) {
                print ("Done!!!\n");
                apps_updated (this.sink_inputs);
            }

            return !sink_inputs_done;
        });
        return this.sink_inputs;
    }

    public Sink[] get_outputs() {
        update_all_sinks();

        Timeout.add(5, () => {

            if (sinks_done) {
                sinks_updated (this.sinks);
            }

            return !sinks_done;
        });

        return this.sinks;
    }

}
