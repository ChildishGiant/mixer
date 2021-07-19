
public class Sink : GLib.Object {

    public string index;
    public string description;

}


public static Sink[] get_outputs () {

        string raw_sinks;

        try {

            //  Get a list of all sinks
            //  get just the info we want
            Process.spawn_command_line_sync(
                "sh -c \"pacmd list-sinks | grep -e index: -e device.description\"",
                out raw_sinks
            );

            Sink[] sinks = {};

            foreach(string line in raw_sinks.split("\n")){
                line = line.strip();
                string[] split = line.split(" ");

                switch (split[0]) {

                        Sink sink = new Sink();

                    case "*":
                    case "index:":
                        Sink sink = new Sink();

                        if (split[0] == "*") {
                            sink.index = split[2];
                        } else {
                            sink.index = split[1];
                        }

                        sinks += sink;
                        break;
                    case "device.description":
                        sinks[sinks.length-1].description = line.substring(22, line.length-23);
                        break;
                    default:
                        break;
                }
            }

            return sinks;

        } catch (SpawnError e) {
            error ("Error: %s\n", e.message);
        }

    }


