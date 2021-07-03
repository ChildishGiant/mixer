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

    private Gtk.Grid[] rows;

    public Application () {
        Object (
            application_id: "com.github.mixer",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {

        Response[] apps = digester();

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit",  {"<Control>q", "<Control>w"});

        var main_window = new Gtk.ApplicationWindow (this);
        main_window.default_height = 250;
        main_window.default_width = 500;
        main_window.title = "Mixer";


        var grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6,
            margin = 6,
            halign = Gtk.Align.FILL
        };


        //  If no apps are using audio
        if (apps.length == 0) {
            var label = new Gtk.Label (_("No apps"));
            label.expand = true;
            grid.add(label);
        }

        else {
            for (int i = 0; i < apps.length; i++) {

                var item_grid = new Gtk.Grid () {
                    column_spacing = 6,
                    row_spacing = 6,
                    halign = Gtk.Align.FILL,
                    valign = Gtk.Align.CENTER
                };

                var icon = new Gtk.Image.from_icon_name (apps[i].icon, Gtk.IconSize.DND);
                icon.valign = Gtk.Align.START;
                var name_label = new Gtk.Label (apps[i].name.to_string());

                var volume_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 5);
                volume_scale.adjustment.page_increment = 5;
                volume_scale.draw_value = false;
                volume_scale.hexpand = true;
                volume_scale.set_value(apps[i].volume);

                var volume_label = new Gtk.Label (_("Volume:"));
                volume_label.halign = Gtk.Align.END;

                var balance_label = new Gtk.Label (_("Balance:"));
                balance_label.valign = Gtk.Align.START;
                balance_label.halign = Gtk.Align.END;

                var balance_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, -1, 1, 0.1);
                balance_scale.adjustment.page_increment = 0.1;
                balance_scale.draw_value = false;
                balance_scale.has_origin = false;
                balance_scale.add_mark (-1, Gtk.PositionType.BOTTOM, _("Left"));
                balance_scale.add_mark (0, Gtk.PositionType.BOTTOM, _("Centre"));
                balance_scale.add_mark (1, Gtk.PositionType.BOTTOM, _("Right"));
                balance_scale.set_value(apps[i].balance);

                //  Create mute switch
                var volume_switch = new Gtk.Switch() {
                    valign = Gtk.Align.CENTER,
                    active = !apps[i].muted
                };

                //  TODO: Make the mute switch function
                //  volume_switch.notify["active"].connect (() => {
                    //  print(volume_switch.margin_left.to_string()+"!!!");
                    //  print(i.to_string() + "\n");
                    //  print(apps[0].index + "\n");
                    //  print(apps.length.to_string());
                    //  print(apps[i].index);
                    //  if (volume_switch.active) {
                    //      //  "pacmd set-sink-input-mute "+ apps[i].index +" true"
                    //      Process.spawn_command_line_sync("pacmd set-sink-input-mute "+ apps[i].index +" true");
                    //      print("True");
                    //  } else {
                    //      Process.spawn_command_line_sync("pacmd set-sink-input-mute "+ apps[i].index +" false");
                    //      print("False");
                    //  }
                //  });


                //  Make the switch disable the sliders
                volume_switch.bind_property ("active", volume_scale, "sensitive", BindingFlags.SYNC_CREATE);

                //  If the app's in mono
                if (apps[i].is_mono){
                    //  Disable inputs on balance slider
                    balance_scale.sensitive = false;
                    //  Give it a tooltip explaining this
                    balance_scale.tooltip_markup = Granite.markup_accel_tooltip ({},_("This app is using mono audio"));
                } else {
                    //  If not, make the switch toggle its input
                    volume_switch.bind_property ("active", balance_scale, "sensitive", BindingFlags.SYNC_CREATE);
                }

                //  Add row
                item_grid.attach (name_label,    0, 0);
                item_grid.attach (icon,          0, 1);
                item_grid.attach (volume_label,  1, 0);
                item_grid.attach (volume_scale,  2, 0, 2);
                item_grid.attach (volume_switch, 4, 0, 1, 2);
                item_grid.attach (balance_label, 1, 1);
                item_grid.attach (balance_scale, 2, 1, 2);

                //  Add the row to the list
                rows += item_grid;
                //  Add the row to the main app grid
                grid.attach(item_grid, 0, i*2);

                //  If this isn't the last element
                if (i != apps.length-1) {
                    //  Add a seperator below the last element
                    grid.attach(new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, (i*2)+1);
                }

            };
        }

        main_window.add (grid);
        main_window.show_all ();

        quit_action.activate.connect (() => {
            main_window.destroy ();
        });


    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}

