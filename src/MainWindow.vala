/*
 * Copyright 2021 Allie Law <allie@cloverleaf.app>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Mixer.MainWindow : Hdy.Window {

    private Gtk.Grid window_grid;
    private Gtk.Grid grid;
    private int one_app_height = 117;
    public PulseManager pulse_manager;

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
            //  Side margins to make scrolling easier
            margin_left = 10,
            margin_right = 10,
            halign = Gtk.Align.FILL
        };


        var scrolled = new Gtk.ScrolledWindow (null, null) {
            //  Disabled sideways scrolling
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            //  Minimum show one app
            min_content_height = one_app_height,
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

        //  this.pulse_manager = new PulseManager ();
        //  Timeout.add (200, () => {
        //      populate ();
        //      show_all ();
        //      return false;
        //  });
    }

    public void populate (string mockup = "", Response[]? _apps = null, Sink[]? _sinks = null) {
        //  Clear all existing rows
        var children = grid.get_children ();

        foreach (Gtk.Widget element in children) {
            debug ("removing %s", element.name);
            grid.remove (element);
        }

        Response[] apps = _apps;

        if (mockup != "") {
            debug ("Using mockup: %s", mockup);
            apps = mockup_apps (mockup);

            //  If the mockup is invalid
            if (apps.length == 0) {
                grid.add ( new Gtk.Label ("Unknown mockup: " + mockup) {
                    vexpand = true,
                    hexpand = true
                } );
            }
        }
        //  else {
        //      apps = pulse_manager.get_apps ();
        //      //  This is somehow running before get_apps returns
        debug ("Got %d apps", apps.length);
        //  }

        //  var outputs = pulse_manager.get_outputs ();
        var outputs = _sinks;

        //  If no apps are using audio
        if (apps.length == 0 && mockup == "") {

            var no_apps = new AlertView ();
            grid.add (no_apps);
        }

        else {
            for (int i = 0; i < apps.length; i++) {

                var app = apps[i];

                var icon = new Gtk.Image.from_icon_name (app.icon, Gtk.IconSize.DND);
                icon.valign = Gtk.Align.START;
                var name_label = new Gtk.Label (app.name.to_string ()) {
                    //  If the name's longer than 32 chars use ...
                    max_width_chars = 32,
                    ellipsize = Pango.EllipsizeMode.END,
                };

                var volume_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 5);
                volume_scale.adjustment.page_increment = 5;
                volume_scale.draw_value = false;
                volume_scale.hexpand = true;
                volume_scale.set_value (app.volume * 100);

                var volume_label = new Gtk.Label (_("Volume:"));
                volume_label.halign = Gtk.Align.START;

                var balance_label = new Gtk.Label (_("Balance:"));
                balance_label.valign = Gtk.Align.START;
                balance_label.halign = Gtk.Align.START;

                var balance_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, -1, 1, 0.1) {
                    draw_value = false,
                    has_origin = false,
                    width_request = 150
                };
                balance_scale.adjustment.page_increment = 0.1;
                balance_scale.add_mark (-1, Gtk.PositionType.BOTTOM, _("Left"));
                balance_scale.add_mark (0, Gtk.PositionType.BOTTOM, _("Centre"));
                balance_scale.add_mark (1, Gtk.PositionType.BOTTOM, _("Right"));
                balance_scale.set_value (app.balance);

                //  Make the volume slider function
                volume_scale.value_changed.connect (() => {
                    pulse_manager.set_volume (app, balance_scale, volume_scale);
                });

                //  Create mute switch
                var volume_switch = new Gtk.Switch () {
                    valign = Gtk.Align.CENTER,
                    active = !app.muted
                };

                //  Make the mute switch function
                volume_switch.notify["active"].connect (() => {
                    pulse_manager.set_mute (app, !volume_switch.active);
                });


                //  Make the switch disable the sliders
                volume_switch.bind_property ("active", volume_scale, "sensitive", BindingFlags.SYNC_CREATE);

                //  If the app's in mono
                if (apps[i].is_mono) {
                    //  Disable inputs on balance slider
                    balance_scale.sensitive = false;
                    //  Also grey out the label
                    balance_label.sensitive = false;
                    //  Give it a tooltip explaining this
                    balance_scale.tooltip_markup = Granite.markup_accel_tooltip ({}, _("This app is using mono audio"));
                } else {
                    //  If not, make the switch toggle its input
                    volume_switch.bind_property ("active", balance_scale, "sensitive", BindingFlags.SYNC_CREATE);

                    //  Make the balance slider function
                    balance_scale.value_changed.connect (() => {
                        pulse_manager.set_volume (app, balance_scale, volume_scale);
                    });
                }

                //  Output label
                var output_label = new Gtk.Label (_ ("Output:"));

                //  Output dropdown
                var dropdown = new Gtk.ComboBoxText () {
                    //  Minimum width
                    width_request = 75,
                };

                dropdown.cell_area.foreach ((cell_renderer) => {
                    var text = (Gtk.CellRendererText)cell_renderer;
                    text.ellipsize = Pango.EllipsizeMode.END;
                    return true;
                });


                for (int j = 0; j < outputs.length; j++) {
                    var sink = outputs[j];
                    dropdown.append_text ("%s - %s".printf (sink.port_name, sink.port_description));

                    //  If this is the current output
                    if (app.sink == sink.index) {
                        dropdown.set_active (j);
                    }
                }

                //  Make the dropdown function
                dropdown.changed.connect (() => {
                    pulse_manager.move (app, outputs[dropdown.active]);
                });

                var base_top = i * 4;
                var separator_top = ( (i + 1) * 3 ) + i;

                //  Add First row for app, volume slider and mute switch
                grid.attach (name_label, 0, base_top + 0);
                grid.attach (volume_label, 1, base_top + 0);
                grid.attach (volume_scale, 2, base_top + 0);
                grid.attach (volume_switch, 3, base_top + 0, 1, 2);
                //  Second row for icon and balance
                grid.attach (icon, 0, base_top + 1);
                grid.attach (balance_label, 1, base_top + 1);
                grid.attach (balance_scale, 2, base_top + 1);
                //  Third row for picking output
                grid.attach (output_label, 0, base_top + 2);
                grid.attach (dropdown, 1, base_top + 2, 3);

                //  If this isn't the last element
                if (i != apps.length - 1) {
                    //  Add a seperator below the last element
                    grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, separator_top, 4);
                }
            };
        }

        //  TODO Request the window size
        //  var height = (apps.length * one_app_height);
        //  set_default_size (-1, height) ;
        show_all ();
    }

    //  Runs a synchronous command without output
    private void run_command (string command) {
        try {

            string output;
            string error;

            Process.spawn_command_line_sync (command, out output, out error);

            if (output == "" && error == "") {
                debug ("Command %s ran successfully", command);
            } else {
                debug ("Command %s failed", command);
                debug ("Output: %s", output);
                debug ("Error: %s", error);
            }

        } catch (SpawnError e) {
            error ("Error: %s\n", e.message);
        }
    }

}
