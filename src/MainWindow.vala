public class Mixer.MainWindow : Hdy.Window {

    private Gtk.Grid window_grid;
    private Gtk.Grid grid;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            border_width: 0,
            icon_name: "com.github.childishgiant.mixer",
            resizable: true,
            title: _("Mixer"),
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        Hdy.init ();

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/childishgiant/mixer");

        var header = new Hdy.HeaderBar () {
            show_close_button = true,
            title = _("Mixer")
        };

        unowned Gtk.StyleContext header_context = header.get_style_context ();
        header_context.add_class ("default-decoration");
        header_context.add_class (Gtk.STYLE_CLASS_FLAT);

        grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6,
            margin = 6,
            halign = Gtk.Align.FILL
        };


        var scrolled = new Gtk.ScrolledWindow (null, null) {
            //  Disabled sideways scrolling
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            //  Minimum show one app
            min_content_height = 111,
            propagate_natural_height = true
        };

        scrolled.add (grid);

        window_grid = new Gtk.Grid () {
            column_spacing = 0,
            row_spacing = 0,
            margin = 0,
            halign = Gtk.Align.FILL
        };

        window_grid.attach (header, 0, 0);
        window_grid.attach (scrolled, 0, 1);

        var window_handle = new Hdy.WindowHandle ();
        window_handle.add (window_grid);

        add (window_handle);

        populate ();

    }

    public void populate () {
        //  Clear all existing rows
        var children = grid.get_children ();

        foreach (Gtk.Widget element in children) {
            debug ("removing %s", element.name);
            grid.remove (element);
        }

        var apps = digester ();
        var outputs = get_outputs ();

        //  If no apps are using audio
        if (apps.length == 0) {

            var no_apps = new AlertView ();
            grid.add (no_apps);
        }

        else {
            for (int i = 0; i < apps.length; i++) {

                var app = apps[i];

                // Make a grid for just this item row
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
                        run_command ("env LANG=C pactl set-sink-input-mute " + app.index + " 0");
                        debug ("Unmuting %s", app.index);
                    } else {
                        run_command ("env LANG=C pactl set-sink-input-mute " + app.index + " 1");
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
                    dropdown.append_text ("%s - %s".printf (sink.active_port, sink.description));

                    //  If this is the current output
                    if (app.sink == sink.index) {
                        dropdown.set_active (j);
                    }
                }

                //  Make the dropdown function
                dropdown.changed.connect (() => {
                    var sink = outputs[dropdown.active];
                    run_command ("env LANG=C pactl move-sink-input " + app.index + " " + sink.index);
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
                debug ("Added %s grid", app.name);
                grid.attach (item_grid, 0, i * 2);

                //  If this isn't the last element
                if (i != apps.length - 1) {
                    //  Add a seperator below the last element
                    grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, (i * 2) + 1);
                }

            };
        }
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

        run_command ("env LANG=C pactl set-sink-input-volume " + app.index + " " + percentages);
    }

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


}
