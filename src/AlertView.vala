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
* Authored by: Rajdeep Singha <singharajdeep97@gmail.com>
*/

public class AlertView : Gtk.Grid {
    construct {
        column_spacing = 12;
        row_spacing = 12;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        margin = 24;
        vexpand = true;

        var title_label = new Gtk.Label ("No Apps") {
            hexpand = true,
            xalign = 0
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var description_label = new Gtk.Label ("There are no apps making any noise.") {
            hexpand = true,
            xalign = 0,
            valign = Gtk.Align.START
        };

        var image = new Gtk.Image.from_icon_name ("preferences-desktop-sound", Gtk.IconSize.DIALOG) {
            margin_top = 6,
            valign = Gtk.Align.START
        };

        attach (image, 1, 1, 1, 2);
        attach (title_label, 2, 1, 1, 1);
        attach (description_label, 2, 2, 1, 1);
    }
}
