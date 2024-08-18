/* window.vala
 *
 * Copyright 2022 Allie Law
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[GtkTemplate (ui = "/com/github/childishgiant/mixer/appEntry.ui")]
private class Mixer.AppEntry : Adw.ExpanderRow {
    [GtkChild]
    public unowned Gtk.Scale volume_scale;
    [GtkChild]
    public unowned Gtk.Image icon;
    [GtkChild]
    public unowned Gtk.Scale balance_scale;
    [GtkChild]
    public unowned Adw.ComboRow output_row;
    [GtkChild]
    public unowned Gtk.ToggleButton mute_button;

    public uint32 id { get; set; } // Id equal to index of sink-input
}


[GtkTemplate (ui = "/com/github/childishgiant/mixer/window.ui")]
public class Mixer.Window : Adw.ApplicationWindow {

    [GtkChild]
    private unowned Adw.PreferencesGroup apps_grid;
    [GtkChild]
    private unowned Gtk.Stack stack;

    public PulseManager pulse_manager;
    Response[] responses;
    Sink[] sinks;
    //  private uint32[] current_ids = {};

    //  A hash table of sink_indexs:AppEntry
    private GLib.HashTable<uint32, Mixer.AppEntry> current_app_rows = new GLib.HashTable<uint32, Mixer.AppEntry> (
        GLib.direct_hash,   // Hash function for uint32 keys
        GLib.direct_equal   // Equality function for uint32 keys
    );

    public Window (Gtk.Application app) {
        Object (
            application: app,
            icon_name: "com.github.childishgiant.mixer",
            resizable: true,
            title: _("Mixer")
        );

    }

    construct {

        pulse_manager = new PulseManager ();

        pulse_manager.get_apps ();
        pulse_manager.get_outputs ();

        pulse_manager.sinks_updated.connect ((_sinks) => {
            sinks = _sinks;
            if (responses != null) {
                populate ("", responses, sinks);
            }
        });

        pulse_manager.apps_updated.connect ((_apps) => {
            responses = _apps;
            if (sinks != null) {
                populate ("", responses, sinks);
            }
        });

        present ();

    }

    public void populate (string mockup = "", Response[]? _apps = null, Sink[]? _outputs = null) {

            debug ("Populate called");

            var outputs = _outputs;

            //  Hash table of sink_index:Response
            GLib.HashTable<uint32, Response> apps = new GLib.HashTable<uint32, Response> (
                GLib.direct_hash,   // Hash function for uint32 keys
                GLib.direct_equal   // Equality function for uint32 keys
            );

            //  Output lists
            Response[] new_apps = {}; // Apps that are new to the app


            //  Iterate all over all apps now in use
            for (int i = 0; i < _apps.length; i++) {
                debug ("Inputted app: %s (%s)", _apps[i].name, _apps[i].index.to_string ());
                var sink_index = _apps[i].index;

                //  Add response to apps hashtable 
                apps.insert (sink_index, _apps[i]);

                //  If not in the list of existing app rows
                if (!current_app_rows.contains (sink_index)) {
                    debug ("App %s is not in the apps_grid, add it", _apps[i].name);
                    //  If it's not in the apps_grid, add it
                    new_apps += _apps[i];
                }
            }

            debug ("new_apps length %d", new_apps.length);

            //  Iterate over existing apps to remove/update them
            current_app_rows.foreach_remove ((sink_index, app_row) => {

                //  If this existing app isn't in the new ones
                if (!apps.contains (sink_index)) {
                    debug ("%s not in new ids, removing", app_row.title);
                    //  If not, remove it
                    apps_grid.remove (app_row);
                    //  Also remove it from the list of current apps
                    return true;

                } else {
                    //  If this row is still in use
                    debug ("%s (%d) is present, updating", app_row.title, (int)sink_index);

                    //  App response to avoid searching hash loads
                    var app = apps.get (sink_index);

                    //  Update title
                    app_row.set_title (app.name);
                    //  Update volume slider
                    app_row.volume_scale.set_value (app.volume);
                    //  Update balance slider
                    app_row.balance_scale.set_value (app.balance);
                    //  Update mute button
                    app_row.mute_button.active = app.muted;


                }
                //  If we're here, we don't want to remove this item
                return false;
            });

            //  if (mockup != "") {
            //      debug ("Using mockup: %s", mockup);

            //      new_apps = mockup_apps (mockup);
            //      outputs = mockup_outputs ();


            //      //  If the mockup is invalid
            //      if (new_apps.length == 0) {
            //          apps_grid.add ( new Gtk.Label ("Unknown mockup: " + mockup) {
            //              vexpand = true,
            //              hexpand = true
            //          });
            //      }
            //  }

            //  If no apps are using audio
            if (_apps.length == 0 && mockup == "") {
                // Switch to no apps stack page
                stack.set_visible_child_name ("no-apps");
            }

            else {
                // Some apps exist
                // Make sure we're on the right stack page
                stack.set_visible_child_name ("main-content");

                //  Iterate over new apps
                for (int i = 0; i < new_apps.length; i++) {

                    var app = new_apps[i];
                    var app_widget = new Mixer.AppEntry ();

                    //  Give the ExpanderRow an id equal to the sink index so we can keep track of it
                    app_widget.id = app.index;

                    // TODO Maybe show the ID if there are duplicate names
                    app_widget.set_title (app.name.to_string ());

                    if (app.icon != "application-default-icon") {
                        app_widget.icon.icon_name = app.icon;
                    }

                    //  Set balance slider to app's value
                    app_widget.balance_scale.set_value (app.balance);

                    //  Set volume slider to app's value
                    app_widget.volume_scale.set_value (app.volume);

                    // Make the volume slider function
                    app_widget.volume_scale.value_changed.connect (() => {
                        pulse_manager.set_volume (app, app_widget.balance_scale, app_widget.volume_scale);
                    });

                    //  Make the mute switch toggle icon when clicked
                    app_widget.mute_button.toggled.connect ((mute_button) => {

                        if (mute_button.active) {
                            mute_button.icon_name = "audio-volume-muted";
                        } else {
                            mute_button.icon_name = "audio-volume-high-symbolic";
                        }

                        //  Set mute of app to match the button
                        pulse_manager.set_mute (app, mute_button.active);
                    });

                    // Set mute switch to match the app
                    app_widget.mute_button.set_active (app.muted);

                    // If the app's in mono
                    if (app.is_mono) {
                        // Disable inputs on balance slider
                        app_widget.balance_scale.sensitive = false;
                        // Give it a tooltip explaining this
                        app_widget.balance_scale.set_tooltip_text ( _("This app is using mono audio"));
                    } else {
                        // If not, make the switch toggle its input
                        //app_widget.volume_switch.bind_property ("active", app_widget.balance_scale, "sensitive", BindingFlags.SYNC_CREATE);

                        // Make the balance slider function
                        app_widget.balance_scale.value_changed.connect (() => {
                            pulse_manager.set_volume (app, app_widget.balance_scale, app_widget.volume_scale);
                        });
                    }

                    // TODO Port to gtk4
                    //  app_widget.dropdown.cell_area.foreach ((cell_renderer) => {
                    //      var text = (Gtk.CellRendererText)cell_renderer;
                    //      text.ellipsize = Pango.EllipsizeMode.END;
                    //      return true;
                    //  });


                    for (int j = 0; j < outputs.length; j++) {
                        var sink = outputs[j];
                        // app_widget.dropdown.append_text ("%s - %s".printf (sink.port_name, sink.port_description));

                        // If this is the current output
                        if (app.sink == sink.index) {
                         // app_widget.dropdown.set_active (j);
                        }
                    }

                    // Make the dropdown function
                    //app_widget.dropdown.changed.connect (() => {
                      //  pulse_manager.move (app, outputs[app_widget.dropdown.active]);
                    //});

                    //  Add this to the list of rows so we can manage it later
                    current_app_rows.insert (app.index, app_widget);

                    // Add this to the app grid
                    apps_grid.add (app_widget);

                };
            }

            //  set_size_request (700, height);

            //  Update the list of current apps
            //  current_ids = _apps_ids;

        }
}
