
public class Sink : GLib.Object {

    public string index;
    public string description;

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

        foreach (string line in raw_sinks.split ("\n")) {
            try {
                line = line.strip ();
                string id, description;
                Regex id_pattern = new Regex ("Sink #(.*)", RegexCompileFlags.MULTILINE);
                MatchInfo match_id;
                if (id_pattern.match (line, 0, out match_id)) {
                    id = match_id.fetch (1);
                    Sink sink = new Sink ();
                    sink.index = id;
                    sinks += sink;
                }

                Regex desc_pattern = new Regex ("Name: (.*)", RegexCompileFlags.MULTILINE);
                MatchInfo match_desc;
                if (desc_pattern.match (line, 0, out match_desc)) {
                    description = match_desc.fetch (1);
                    sinks[sinks.length - 1].description = description;
                }
            } catch (Error e) {
                warning (e.message);
            }
        }

        return sinks;

    } catch (SpawnError e) {
        error ("Error: %s\n", e.message);
    }

}
