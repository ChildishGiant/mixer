/*
 * Copyright 2021 Allie Law <allie@cloverleaf.app>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Mixer.App : Gtk.Application {

    private static string version = "1.1.0";
    private static bool print_version = false;
    private static string mockup = null;
    public PulseManager manager;
    Response[] responses;
    Sink[] sinks;

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
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

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

        manager = new PulseManager ();
        app_window.pulse_manager = manager;

        manager.get_apps ();
        manager.get_outputs ();

        manager.sinks_updated.connect ((_sinks) => {
            sinks = _sinks;
            if (responses != null) {
                app_window.populate ("", responses, sinks);
            }
        });

        manager.apps_updated.connect ((_apps) => {
            responses = _apps;
            if (sinks != null) {
                app_window.populate ("", responses, sinks);
                app_window.show_all ();
            }
        });

        quit_action.activate.connect (() => {
            if (app_window != null) {
                app_window.destroy ();
                app_window.show_all ();
            }
        });

    }

    public static int main (string[] args) {
        var app = new App ();
        return app.run (args);
    }
}
