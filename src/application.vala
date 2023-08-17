/* application.vala
 *
 * Copyright 2022 Allie Law
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Mixer {
    public class Application : Adw.Application {

        private static bool print_version = false;
        private static string mockup = "";
        private Adw.ApplicationWindow win;

        private const GLib.OptionEntry[] options = {

            { "version", '\0', OptionFlags.NONE, OptionArg.NONE, ref print_version,
            "Display version number", null },
            { "mockup", 'm', OptionFlags.NONE, OptionArg.STRING, ref mockup},
            // list terminator
            { null }
        };

        private Settings settings = new Settings (Constants.APP_ID);


        public Application () {
            Object (
                application_id: Constants.APP_ID,
                flags: ApplicationFlags.FLAGS_NONE
            );

            this.add_main_option_entries (options);
        }


        construct {


            ActionEntry[] action_entries = {
                { "about", this.on_about_action },
                { "preferences", this.on_preferences_action },
                { "quit", this.quit }
            };
            this.add_action_entries (action_entries, this);
            this.set_accels_for_action ("app.quit", {"<primary>q"});


             add_main_option_entries (options);
        }

        public override void activate () {

            debug ("Mockup: %s".printf (mockup));
            debug (mockup == ""? "Mockup: %s".printf (mockup) : "No mockup");

            if (print_version) {

                stdout.printf (_("Mixer version: %s"), Constants.VERSION + "\n");
                return;
            }

            base.activate ();
            // win = this.active_window;
            if (win == null) {
                win = new Mixer.Window (this);
            }

            //  FIXME TODO mockup not working now.
            // Just move it to a blp
            if (mockup != null) {
                debug ("Using mockup");
                var cast_win = (Mixer.Window) win;
                cast_win.populate (mockup);
                return;
            }

            win.present ();
        }

        private void on_about_action () {
            string[] authors = { "Allie Law" };
            Gtk.show_about_dialog (this.active_window,
                                   "program-name", "mixer",
                                   "authors", authors,
                                   "version", Constants.VERSION);
        }

        private void on_preferences_action () {
            message ("app.preferences action activated");
        }
    }
}
