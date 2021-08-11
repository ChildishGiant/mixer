
public class Sink : GLib.Object {

    public string index;
    public string description;
    public string active_port;

}


public static Sink[] get_outputs () {

    string raw_sinks;

    try {

        //  Get a list of all sinks
        //  get just the info we want
        Process.spawn_command_line_sync (
            "env LANG=C pactl list sinks",
            out raw_sinks
        );

        Sink[] sinks = {};
        string[] ports = {};
        bool capture_ports = false;

        Regex id_pattern = new Regex (
            "Sink #(.*)",
            RegexCompileFlags.MULTILINE
        );
        Regex desc_pattern = new Regex (
            "device\\.description = \"(.*)\"",
            RegexCompileFlags.MULTILINE
        );

        foreach (string line in raw_sinks.split ("\n")) {

            line = line.strip ();
            string id, description;

            MatchInfo match_id;
            if (id_pattern.match (line, 0, out match_id)) {
                Sink sink = new Sink ();
                id = match_id.fetch (1);
                sink.index = id;
                sinks += sink;
            }

            MatchInfo match_desc;
            if (desc_pattern.match (line, 0, out match_desc)) {
                description = match_desc.fetch (1);
                sinks[sinks.length - 1].description = description;
            }


            if (capture_ports) {
                //  Make sure we're not on the active port
                if (line.index_of ("Active Port") == 0) {

                    string selected_port = line.split (":")[1].strip ();

                    //  Find the correct port
                    foreach (string port in ports) {
                        //  If this line starts with the selected port
                        if (port.index_of (selected_port) == 0) {

                            //  Get readable part
                            string part = port.split (":")[1];
                            string readable = part.substring (1, part.length - 11);
                            sinks[sinks.length - 1].active_port = readable;
                            //  We can stop looking
                            break;
                        }
                    }
                    //  Stop capturing ports
                    capture_ports = false;
                } else { //  If we're not on the active port
                    //  Add the port to the list
                    ports += line;
                }
            }

            //  If we're at the start of this sink's ports
            //  This is after the previous if to avoid capturing the label line
            if (line.index_of ("Ports:") == 0) {
                //  Clear the ports array
                ports = {};
                //  Start capturing them
                capture_ports = true;
            }


        }

        return sinks;

    } catch (Error e) {
        error ("Error: %s\n", e.message);
    }

}
