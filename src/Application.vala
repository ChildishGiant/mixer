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

public class Mixer.App : Gtk.Application {

    private static string version = "0.1.4";
    private static bool print_version = false;
    private static string mockup = null;

    public App () {
        Object (
            application_id: "com.github.childishgiant.mixer",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    private const OptionEntry[] OPTIONS = {
        { "version", 'v', 0, OptionArg.NONE, ref print_version,
            "Display version number." },
        { "mockup", 'm', 0, OptionArg.STRING, ref mockup,
            "Use mock applications." },
        { null }
    };

    construct {
        add_main_option_entries (OPTIONS);
    }

    protected override void activate () {

        if (print_version) {
            stdout.printf (_("Mixer version: %s"), version + "\n");
        }

        unowned var gtk_settings = Gtk.Settings.get_default ();
        unowned var granite_settings = Granite.Settings.get_default ();

        gtk_settings.gtk_cursor_theme_name = "elementary";
        gtk_settings.gtk_icon_theme_name = "elementary";

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
            );
        });

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q", "<Control>w"});

        var app_window = new MainWindow (this);

        //  Set default width so the dropdown isn't squashed too much
        app_window.set_default_size (700, -1);

        if (mockup != null) {
            app_window.populate (mockup);
            app_window.show_all ();
            return;
        }

        var listener = new Listener ("/home", "/usr/bin/pactl subscribe");

        listener.output_changed.connect ((line) => {
            //  If the change is a sink-input
            if (line.contains ("sink-input") && (line.contains ("new") || line.contains ("remove"))) {
                debug (line.strip ());
                app_window.populate ();
                app_window.show_all ();
            }
        });

        listener.run ();

        app_window.destroy.connect (() => {
            listener.quit ();
        });

        app_window.show_all ();

        quit_action.activate.connect (() => {
            if (app_window != null) {
                app_window.destroy ();
            }
        });

    }

    public static int main (string[] args) {
        var app = new App ();
        return app.run (args);
    }
}
