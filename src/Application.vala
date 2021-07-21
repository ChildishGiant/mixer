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

public class Application : Gtk.Application {

    private Gtk.Grid grid;

    //  Takes balance and volume, outputs left and right volumes
    private int[] balance_volume (double balance, double volume) {
        debug ("Balance: %s", balance.to_string ());
        debug ("Volume: %s", volume.to_string ());

        double l;
        double r;

        if (balance < 0) {
            l = (100 * balance) + 100;
            r = 100;
        } else if (balance > 0) {
            l = 100;
            r = (-100 * balance) + 100;

        }else {
            l = 100;
            r = 100;
        };

        int new_l = (int)(l * volume / 100);
        int new_r = (int)(r * volume / 100);

        return {new_l, new_r};
    }

    //  Runs a synchronous command without output
    private void run_command (string command) {
        try {
            Process.spawn_command_line_sync (command);
        } catch (SpawnError e) {
            error ("Error: %s\n", e.message);
        }
    }

    private void set_volume (Response app, Gtk.Scale balance_scale, Gtk.Scale volume_scale) {
        var volumes = balance_volume (balance_scale.get_value (), volume_scale.get_value ());

        string percentages;

        //  If the app is mono, only set one channel
        if (app.is_mono) {
            percentages = int.max (volumes[1], volumes[0]).to_string () + "%";
        } else {
            percentages = volumes[1].to_string () + "% " + volumes[0].to_string () + "%";
        }

        run_command ("pactl set-sink-input-volume " + app.index + " " + percentages);
    }

    public Application () {
        Object (
            application_id: "com.github.childishgiant.mixer",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    private void populate (Gtk.ApplicationWindow main_window) {

        //  Clear all existing rows
        var children = grid.get_children ();
        foreach (Gtk.Widget element in children) {
            grid.remove (element);
        }

        var apps = digester ();
        var outputs = get_outputs ();

        //  If no apps are using audio
        if (apps.length == 0) {
            var no_apps = new Granite.Widgets.AlertView (
                _("No Apps"),
                _("There are no apps making any noise."),
                "preferences-desktop-sound"
            );
            no_apps.show_all ();
            grid.add (no_apps);
        }

        else {
            for (int i = 0; i < apps.length; i++) {

                var app = apps[i];

                var item_grid = new Gtk.Grid () {
                    column_spacing = 6,
                    row_spacing = 6,
                    halign = Gtk.Align.FILL,
                    valign = Gtk.Align.CENTER
                };

                var icon = new Gtk.Image.from_icon_name (app.icon, Gtk.IconSize.DND);
                icon.valign = Gtk.Align.START;
                var name_label = new Gtk.Label (app.name.to_string ());

                var volume_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 5);
                volume_scale.adjustment.page_increment = 5;
                volume_scale.draw_value = false;
                volume_scale.hexpand = true;
                volume_scale.set_value (app.volume);

                var volume_label = new Gtk.Label (_("Volume:"));
                volume_label.halign = Gtk.Align.START;

                var balance_label = new Gtk.Label (_("Balance:"));
                balance_label.valign = Gtk.Align.START;
                balance_label.halign = Gtk.Align.START;

                var balance_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, -1, 1, 0.1);
                balance_scale.adjustment.page_increment = 0.1;
                balance_scale.draw_value = false;
                balance_scale.has_origin = false;
                balance_scale.add_mark (-1, Gtk.PositionType.BOTTOM, _("Left"));
                balance_scale.add_mark (0, Gtk.PositionType.BOTTOM, _("Centre"));
                balance_scale.add_mark (1, Gtk.PositionType.BOTTOM, _("Right"));
                balance_scale.set_value (app.balance);

                //  Make the volume slider function
                volume_scale.value_changed.connect (() => {
                    set_volume (app, balance_scale, volume_scale);
                });

                //  Create mute switch
                var volume_switch = new Gtk.Switch () {
                    valign = Gtk.Align.CENTER,
                    active = !app.muted
                };

                //  Make the mute switch function
                volume_switch.notify["active"].connect (() => {
                    if (volume_switch.active) {
                        run_command ("pacmd set-sink-input-mute " + app.index + " false");
                        debug ("Unmuting %s", app.index);
                    } else {
                        run_command ("pacmd set-sink-input-mute " + app.index + " true");
                        debug ("Muting %s", app.index);
                    }
                });


                //  Make the switch disable the sliders
                volume_switch.bind_property ("active", volume_scale, "sensitive", BindingFlags.SYNC_CREATE);

                //  If the app's in mono
                if (apps[i].is_mono) {
                    //  Disable inputs on balance slider
                    balance_scale.sensitive = false;
                    //  Give it a tooltip explaining this
                    balance_scale.tooltip_markup = Granite.markup_accel_tooltip ({}, _("This app is using mono audio"));
                } else {
                    //  If not, make the switch toggle its input
                    volume_switch.bind_property ("active", balance_scale, "sensitive", BindingFlags.SYNC_CREATE);

                    //  Make the balance slider function
                    balance_scale.value_changed.connect (() => {
                        set_volume (app, balance_scale, volume_scale);
                    });
                }

                //  Output label
                var output_label = new Gtk.Label (_ ("Output:"));

                //  Output dropdown
                var dropdown = new Gtk.ComboBoxText ();

                for (int j = 0; j < outputs.length; j++) {
                    var sink = outputs[j];
                    dropdown.append_text (sink.description);

                    //  If this is the current output
                    if (app.sink == sink.index) {
                        dropdown.set_active (j);
                    }
                }

                //  Make the dropdown function
                dropdown.changed.connect (() => {
                    var sink = outputs[dropdown.active];
                    run_command ("pactl move-sink-input " + app.index + " " + sink.index);
                });

                //  Add First row for app, volume slider and mute switch
                item_grid.attach (name_label, 0, 0);
                item_grid.attach (volume_label, 1, 0);
                item_grid.attach (volume_scale, 2, 0);
                item_grid.attach (volume_switch, 3, 0, 1, 2);
                //  Second row for icon and balance
                item_grid.attach (icon, 0, 1);
                item_grid.attach (balance_label, 1, 1);
                item_grid.attach (balance_scale, 2, 1);
                //  Third row for picking output
                item_grid.attach (output_label, 0, 2);
                item_grid.attach (dropdown, 1, 2, 3);

                //  Add the row to the main app grid
                grid.attach (item_grid, 0, i * 2);

                //  If this isn't the last element
                if (i != apps.length - 1) {
                    //  Add a seperator below the last element
                    grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, (i * 2) + 1);
                }

            };
        }

        main_window.show_all ();

    }

    protected override void activate () {

        var main_window = new Gtk.ApplicationWindow (this) {
            default_height = 250,
            default_width = 500,
            title = "Mixer"
        };

        grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6,
            margin = 6,
            halign = Gtk.Align.FILL
        };

        var headerbar = new Gtk.HeaderBar () {
            has_subtitle = false,
            show_close_button = true,
            title = "Mixer"
        };

        main_window.set_titlebar (headerbar);
        main_window.add (grid);

        populate (main_window);

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q", "<Control>w"});

        quit_action.activate.connect (() => {
            main_window.destroy ();
        });

        var listener = new Listener ("/home", "/usr/bin/pactl subscribe");
        listener.run ();

        listener.output_changed.connect ((line) => {
            //  If the change is a sink-input
            if (line.contains ("sink-input") && (line.contains ("new") || line.contains ("remove"))) {
                debug (line.strip ());
                populate (main_window);
            }
        });

    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
