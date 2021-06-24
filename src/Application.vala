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

    //  pacmd list-sink-inputs
    //  pactl set-sink-input-volume id volume
    //  pacmd set-sink-input-mute toggle
    //  pactl subscribe

    public Application () {
        Object (
            application_id: "com.github.mixer",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {


        // Blocking with output
        //  string standard_output, standard_error;
        //  int exit_status;
        //  Process.spawn_command_line_sync ("ls", out standard_output,
        //                                         out standard_error,
        //                                         out exit_status);

        //  stderr.printf(standard_error);
        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit",  {"<Control>q", "<Control>w"});

        var main_window = new Gtk.ApplicationWindow (this);
        main_window.default_height = 300;
        main_window.default_width = 300;
        main_window.title = "Mixer";



        var grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6,
            margin = 6,
            expand = true,
            halign = Gtk.Align.FILL
        };


        for (int i = 0; i < 3; i++) {

            var label = new Gtk.Label ("App name" + i.to_string());

            var adjustment = new Gtk.Adjustment (100, 0, 120, 1, 0.1, 0.1);

            var slider = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, adjustment) {
                draw_value = true,
                expand = true
            };

            slider.add_mark (100, Gtk.PositionType.TOP, null);

            //  Add row
            grid.attach (label, 0, i, 1, 1);
            grid.attach_next_to (slider, label, Gtk.PositionType.RIGHT, 1, 1);
        };

        main_window.add (grid);
        main_window.show_all ();

        quit_action.activate.connect (() => {
            main_window.destroy ();
        });


        digester();

    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}

