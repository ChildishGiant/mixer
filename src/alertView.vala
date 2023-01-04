/*
 * Copyright 2021 Allie Law <allie@cloverleaf.app>
 * Copyright 2021 Rajdeep Singha <singharajdeep97@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class AlertView : Gtk.Grid {
    construct {
        column_spacing = 12;
        row_spacing = 12;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        //  margin = 24;
        vexpand = true;

        var title_label = new Gtk.Label (_("No Apps")) {
            hexpand = true,
            xalign = 0
        };
        // title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var description_label = new Gtk.Label (_("There are no apps making any noise.")) {
            hexpand = true,
            xalign = 0,
            valign = Gtk.Align.START
        };

        var image = new Gtk.Image.from_icon_name ("preferences-desktop-sound") {
            margin_top = 6,
            valign = Gtk.Align.START
        };

        attach (image, 1, 1, 1, 2);
        attach (title_label, 2, 1, 1, 1);
        attach (description_label, 2, 2, 1, 1);
    }
}
