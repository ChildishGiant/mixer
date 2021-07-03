
public class Response : GLib.Object {

    public string index;
    public int volume;
    public float balance;
    public bool muted;
    public string icon = "application-default-icon"; // Or should it be application-x-executable?
    public string name;
    public bool is_mono;

}


public static Response[] digester () {

        string sinks;
        string ls_stderr;
        int ls_status;

        try {

            //  Get a list of all apps using audio
            //  get just the info we want
            Process.spawn_command_line_sync(
                "sh -c \"pacmd list-sink-inputs | grep -e index: -e volume: -e balance -e muted: -e 'application.icon_name = ' -e 'application.name = '\"",
                out sinks,
                out ls_stderr,
                out ls_status
            );

            Response[] apps = {};
            var test = sinks.split("\n");
            foreach(string line in sinks.split("\n")){
                line = line.strip();
                string[] split = line.split(" ");

                switch (split[0]) {

                    case "index:":
                        Response app = new Response();
                        app.index = split[1];
                        apps += app;
                        break;

                    case "volume:":
                        var sep = line.split("/");
                        var colon = line.split(":");

                        //  If mono
                        if (colon[1] == " mono") {
                            apps[apps.length-1].is_mono = true;
                            var stripped = sep[1].strip();
                            apps[apps.length-1].volume = int.parse(stripped.substring(0,stripped.length-1));

                        } else {
                            var left = int.parse(sep[1].substring(0, sep[1].length-1));
                            var right = int.parse(sep[3].substring(0, sep[3].length-1));

                            //  Use the larger of the two
                            if (left > right) {
                                apps[apps.length-1].volume = left;
                            } else {
                                apps[apps.length-1].volume = right;
                            }
                        }
                        break;
                    case "balance":
                        apps[apps.length-1].balance = float.parse(split[1]);
                        break;
                    case "muted:":
                        switch (split[1]) {
                            case "no":
                                apps[apps.length-1].muted = false;
                                break;
                            default:
                                apps[apps.length-1].muted = true;
                                break;
                        }
                        break;
                    case "application.icon_name":
                        apps[apps.length-1].icon = line.substring(25, line.length-26);
                        break;
                    case "application.name":
                        apps[apps.length-1].name = line.substring(20, line.length-21);
                        break;
                    default:
                        break;
                }
            }

            return apps;

        } catch (SpawnError e) {
            error ("Error: %s\n", e.message);
        }

    }


