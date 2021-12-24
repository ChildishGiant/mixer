/*
 * Copyright 2021 Allie Law <allie@cloverleaf.app>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Mixer.MainWindow : Hdy.Window {

    private Gtk.Grid window_grid;
    private Gtk.Grid grid;
    private const int ONE_APP_HEIGHT = 117;
    private const int SEPERATOR_HEIGHT = 13;
    public PulseManager pulse_manager;
    private uint32[] current_ids = {};
    private const int ELEMENTS_PER_ROW = 3;
    //  Store where each app starts in the grid
    private Gee.HashMap <uint32, int> app_base = new Gee.HashMap<uint32, int> ();
    // Store how many rows we have for each app
    private Gee.HashMap <uint32, int> app_rows = new Gee.HashMap<uint32, int> ();

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            border_width: 0,
            icon_name: "com.github.childishgiant.mixer",
            resizable: true,
            title: _ ("Mixer"),
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        Hdy.init ();

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/childishgiant/mixer");

        var header = new Hdy.HeaderBar () {
            show_close_button = true,
            title = _ ("Mixer")
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
            min_content_height = ONE_APP_HEIGHT,
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

    }

    public void populate (string mockup = "", Response[]? _apps = null, Sink[]? _outputs = null) {

        debug ("Populate called");

        var outputs = _outputs;

        //  Do a diff between the current list of apps and the new list of apps
        uint32[] _apps_ids = {}; // List of IDS of all the apps in this call

        //  Output lists
        uint32[] to_remove = {}; // Apps to remove from the grid
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
                debug ("App %s is not in the grid, add it", _apps[i].name);
                //  If it's not in the grid, add it
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

            var base_row = app_base[to_remove[i]];
            var rows = app_rows[to_remove[i]];

            //  Remove all rows used by that app
            for (int j = 0; j < rows; j++) {
                //  Since deleting shuffles the rows about, we don't need to worry about the index
                grid.remove_row (base_row);
            }

            //  Clean up the row list
            app_base.unset (to_remove[i]);
            app_rows.unset (to_remove[i]);

            //  Re-calculate the base row for each app
            Gee.HashMap <uint32, int> new_app_base = new Gee.HashMap<uint32, int> ();

            foreach (var row in app_base) {
                new_app_base[row.key] = app_base[row.key] - rows;
            }

            app_base = new_app_base;
        }

        if (mockup != "") {
            debug ("Using mockup: %s", mockup);

            new_apps = mockup_apps (mockup);
            outputs = mockup_outputs ();

            total_apps = new_apps.length;

            //  If the mockup is invalid
            if (new_apps.length == 0) {
                grid.add ( new Gtk.Label ("Unknown mockup: " + mockup) {
                    vexpand = true,
                    hexpand = true
                } );
            }
        }

        //  If no apps are using audio
        if (new_apps.length == 0 && mockup == "" && to_update.length == 0) {

            var no_apps = new AlertView ();
            grid.add (no_apps);
        }

        else {

            debug (total_apps.to_string () + " apps total");

            for (int i = 0; i < new_apps.length; i++) {

                var app = new_apps[i];

                var icon = new Gtk.Image.from_icon_name (app.icon, Gtk.IconSize.DND);
                icon.valign = Gtk.Align.START;
                //  TODO Maybe show the ID if there are duplicate names
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

                var volume_label = new Gtk.Label (_ ("Volume:"));
                volume_label.halign = Gtk.Align.START;

                var balance_label = new Gtk.Label (_ ("Balance:"));
                balance_label.valign = Gtk.Align.START;
                balance_label.halign = Gtk.Align.START;

                var balance_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, -1, 1, 0.1) {
                    draw_value = false,
                    has_origin = false,
                    width_request = 150
                };
                balance_scale.adjustment.page_increment = 0.1;
                balance_scale.add_mark (-1, Gtk.PositionType.BOTTOM, _ ("Left"));
                balance_scale.add_mark (0, Gtk.PositionType.BOTTOM, _ ("Centre"));
                balance_scale.add_mark (1, Gtk.PositionType.BOTTOM, _ ("Right"));
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
                if (app.is_mono) {
                    //  Disable inputs on balance slider
                    balance_scale.sensitive = false;
                    //  Also grey out the label
                    balance_label.sensitive = false;
                    //  Give it a tooltip explaining this
                    balance_scale.tooltip_markup = Granite.markup_accel_tooltip ({}, _ ("This app is using mono audio"));
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

                //             number of apps before * how many elements per row + how many seperators there will be
                var base_top = (i + to_update.length) * ELEMENTS_PER_ROW + (to_update.length + i - 1);
                //  debug ("(%d + %d) * %d + (%d + %d - 1)", i, to_update.length, ELEMENTS_PER_ROW, i, to_update.length);

                //  Store where this app starts
                app_base[app.index] = base_top;

                //  If this isn't the first app
                if (i > 0 || to_update.length > 0) {

                    //  Add a seperator above this app
                    var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

                    //  Add one to the number of lines this app uses
                    app_rows[app.index] = 1;

                    debug ("Adding seperator at %d", base_top);
                    grid.attach (sep, 0, base_top, 4);

                    //  Update the base_top so the rest of this app gets added below it
                    base_top += 1;
                }

                //  Add First row for app, volume slider and mute switch
                grid.attach (name_label, 0, base_top );
                grid.attach (volume_label, 1, base_top);
                grid.attach (volume_scale, 2, base_top);
                grid.attach (volume_switch, 3, base_top, 1, 2);
                //  Second row for icon and balance
                grid.attach (icon, 0, base_top + 1);
                grid.attach (balance_label, 1, base_top + 1);
                grid.attach (balance_scale, 2, base_top + 1);
                //  Third row for picking output
                grid.attach (output_label, 0, base_top + 2);
                grid.attach (dropdown, 1, base_top + 2, 3);

                //  Add our row count to the map
                app_rows[app.index] = app_rows[app.index] + ELEMENTS_PER_ROW; // += doesn't work for some reason

            };
        }

        var height = (_apps_ids.length * ONE_APP_HEIGHT + ((total_apps - 1) * SEPERATOR_HEIGHT) );
        set_size_request (700, height);

        //  Update the list of current apps
        current_ids = _apps_ids;

        //  Show all our hard work
        show_all ();
    }

}
