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
public class Mixer.AppEntry : Adw.ExpanderRow {
    [GtkChild]
    public unowned Gtk.Scale volume_scale;
    [GtkChild]
    public unowned Gtk.Image icon;
    [GtkChild]
    public unowned Gtk.Scale balance_scale;
    [GtkChild]
    public unowned Adw.ComboRow output_row;


}


[GtkTemplate (ui = "/com/github/childishgiant/mixer/window.ui")]
public class Mixer.Window : Adw.ApplicationWindow {

    [GtkChild]
    private unowned Adw.PreferencesGroup apps_grid;

    private const int ONE_APP_HEIGHT = 117;
    public PulseManager pulse_manager;
    Response[] responses;
    Sink[] sinks;
    private uint32[] current_ids = {};
    private Adw.StatusPage no_apps = new Adw.StatusPage ();

    public Window (Gtk.Application app) {
        Object (
            application: app,
            icon_name: "com.github.childishgiant.mixer",
            resizable: true,
            title: _("Mixer")
        );

    }

    construct {

        // Setup no apps widget
        // TODO make this a blp, there were issues last time
        no_apps.icon_name = "audio-volume-muted";
        no_apps.title = _("No apps");
        no_apps.description = _("There are no apps making any noise.");
        no_apps.vexpand = true;
        no_apps.hexpand = true;

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

            //  Do a diff between the current list of apps and the new list of apps
            uint32[] _apps_ids = {}; // List of IDS of all the apps in this call

            //  Output lists
            uint32[] to_remove = {}; // Apps to remove from the apps_grid
            Response[] new_apps = {}; // Apps that are new to the app
            uint32[] to_update = {}; // Apps that have remained

            //  Add new ids to list
            for (int i = 0; i < _apps.length; i++) {
                debug ("Inputted app: %s (%s)", _apps[i].name, _apps[i].index.to_string ());
                _apps_ids += _apps[i].index;


                //  If app isn't already present
                int current_index = get_index (current_ids, (int)_apps[i].index);
                debug ("Index in existing: " + current_index.to_string ());
                if (current_index == -1) {
                    debug ("App %s is not in the apps_grid, add it", _apps[i].name);
                    //  If it's not in the apps_grid, add it
                    new_apps += _apps[i];
                }
            }

            //  Iterate over existing ids
            for (int i = 0; i < current_ids.length; i++) {

                //  Check if the app is still in the list
                int new_index = get_index (_apps_ids, (int)current_ids[i]);
                if (new_index == -1) {
                    debug ("App %s not in new ids, add it to the remove list", current_ids[i].to_string ());
                    //  If not, add it to the list to remove
                    to_remove += current_ids[i];
                } else {
                    debug ("App %s is present", current_ids[i].to_string ());
                    to_update += current_ids[i];
                }
            }

            var total_apps = new_apps.length + to_update.length;

            debug ("New apps: %s", new_apps.length.to_string ());
            debug ("Apps to remove: %s", to_remove.length.to_string ());
            debug ("Apps to update: %s", to_update.length.to_string ());
            debug ("Total apps: %s", total_apps.to_string ());

            //  Remove all unused apps
            for (int i = 0; i < to_remove.length; i++) {
                debug ("Removing app %s", to_remove[i].to_string ());

                // var base_row = app_base[to_remove[i]];
                // var rows = app_rows[to_remove[i]];

                //  Remove all rows used by that app
                // for (int j = 0; j < rows; j++) {
                    //  Since deleting shuffles the rows about, we don't need to worry about the index
                    // apps_grid.remove_row (base_row);
                // }


            }

            if (mockup != "") {
                debug ("Using mockup: %s", mockup);

                new_apps = mockup_apps (mockup);
                outputs = mockup_outputs ();

                total_apps = new_apps.length;

                //  If the mockup is invalid
                if (new_apps.length == 0) {
                    apps_grid.add ( new Gtk.Label ("Unknown mockup: " + mockup) {
                        vexpand = true,
                        hexpand = true
                    });
                }
            }

            apps_grid.add (no_apps);
            //  If no apps are using audio
            if (new_apps.length == 0 && mockup == "" && to_update.length == 0) {
                // Add no apps message
                apps_grid.add (no_apps);
            }

            else {

                // Remove the no apps label
                if (current_ids.length == 0) {
                    debug ("Removing no apps label");
                    apps_grid.remove (no_apps);
                }

                debug (total_apps.to_string () + " apps total");

                for (int i = 0; i < new_apps.length; i++) {

                    var app = new_apps[i];
                    var app_widget = new Mixer.AppEntry ();

                    // TODO Maybe show the ID if there are duplicate names
                    app_widget.set_title(app.name.to_string ());

                    if (app.icon != "application-default-icon") {
                        app_widget.icon.icon_name = app.icon;
                    }

                    //  Add marks to balance slider
                    app_widget.balance_scale.add_mark (-1, Gtk.PositionType.BOTTOM, _("Left"));
                    app_widget.balance_scale.add_mark (0, Gtk.PositionType.BOTTOM, _("Centre"));
                    app_widget.balance_scale.add_mark (1, Gtk.PositionType.BOTTOM, _("Right"));
                    //  Set balance slider to app's value
                    app_widget.balance_scale.set_value (app.balance);

                    //  Set volume slider to app's value
                    app_widget.volume_scale.set_value (app.volume);

                    // Make the volume slider function
                    app_widget.volume_scale.value_changed.connect (() => {
                        pulse_manager.set_volume (app, app_widget.balance_scale, app_widget.volume_scale);
                    });

                    // Set mute switch
                    //app_widget.volume_switch.active = !app.muted;

                    // Make the mute switch function
                    //app_widget.volume_switch.notify["active"].connect (() => {
                    //    pulse_manager.set_mute (app, !app_widget.volume_switch.active);
                    //});

                    // Make the switch disable the sliders
                    //app_widget.volume_switch.bind_property ("active", app_widget.volume_scale, "sensitive", BindingFlags.SYNC_CREATE);

                    // If the app's in mono
                    if (app.is_mono) {
                        // Disable inputs on balance slider
                        app_widget.balance_scale.sensitive = false;
                        // Give it a tooltip explaining this
                        app_widget.balance_scale.set_tooltip_text( _("This app is using mono audio"));
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


                    // Add this to the app grid
                    apps_grid.add( app_widget);

                };
            }

            //  var height = (_apps_ids.length * ONE_APP_HEIGHT + ((total_apps - 1) * SEPERATOR_HEIGHT) );
            //  set_size_request (700, height);

            //  Update the list of current apps
            current_ids = _apps_ids;

        }
}
