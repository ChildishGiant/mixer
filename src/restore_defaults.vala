// Adds a button to the header bar that restores the default Mixer configuration.

public class RestoreDefaultsButton : Gtk.Button {

    public signal void restored ();

    public RestoreDefaultsButton (GLib.Settings? settings) {
        set_label (_("Restore Defaults"));
        set_tooltip_text (_("Set all app volumes, balances, mute states, and output devices back to defaults"));

        clicked.connect (() => {
            if (settings != null) {
                var keys = settings.list_keys ();
                if (keys != null) {
                    foreach (var key in keys) {
                        settings.reset (key);
                    }
                }
            }

            var toplevel = get_toplevel ();
            if (toplevel != null) {
                reset_widget (toplevel);
            }

            restored ();
        });
    }

    private void reset_widget (Gtk.Widget? widget) {
        if (widget == null) {
            return;
        }

        var scale = widget as Gtk.Scale;
        if (scale != null) {
            var range = scale.get_range ();
            if (range != null) {
                if (range.lower < 0.0 && range.upper > 0.0) {
                    scale.set_value ((range.lower + range.upper) / 2.0);
                } else {
                    scale.set_value (range.upper);
                }
            }
        }

        var toggle = widget as Gtk.ToggleButton;
        if (toggle != null) {
            toggle.set_active (false);
        }

        var combo = widget as Gtk.ComboBox;
        if (combo != null) {
            combo.set_active (-1);
        }

        var container = widget as Gtk.Container;
        if (container != null) {
            var children = container.get_children ();
            if (children != null) {
                foreach (var child in children) {
                    reset_widget (child);
                }
            }
        }
    }

    public static void install (Gtk.HeaderBar header, GLib.Settings? settings) {
        header.pack_end (new RestoreDefaultsButton (settings));
    }
}
