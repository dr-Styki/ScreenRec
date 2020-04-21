/*
* Copyright (c) 2020 Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
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
* Authored by: Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
*/

namespace ScreenRec {

    public class Recorder : GLib.Object {

        public bool is_recording { get; private set; default = false; }
        public int width { get; private set; }
        public int height { get; private set; }
        dynamic Gst.Pipeline pipeline;
        Gst.Bin videobin;
        Gst.Bin audiobin;

        public Recorder (
            ScreenrecorderWindow.CaptureType capture_mode,
            Gdk.Window window,
            string tmp_file_path,
            int frame_rate,
            bool is_speakers_recorded,
            bool is_mic_recorded){


            pipeline = new Gst.Pipeline ("screencast-pipe");

            var muxer = Gst.ElementFactory.make ("webmmux", "mux");
            var sink = Gst.ElementFactory.make ("filesink", "sink");

            // video bin
            this.videobin = new Gst.Bin ("video");

            try {
                videobin = (Gst.Bin)Gst.parse_bin_from_description ("ximagesrc name=\"videosrc\" ! video/x-raw, framerate=24/1 ! videoconvert ! vp8enc name=\"encoder\" ! queue", true);
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }

            // audio bin
            this.audiobin = new Gst.Bin ("audio");

            string default_output = "";
            try {
                string sound_outputs = "";
                Process.spawn_command_line_sync ("pacmd list-sinks", out sound_outputs);
                GLib.Regex re = new GLib.Regex ("(?<=\\*\\sindex:\\s\\d\\s\\sname:\\s<)[\\w\\.\\-]*");
                MatchInfo mi;
                if (re.match (sound_outputs, 0, out mi)) {
                    default_output = mi.fetch (0);
                }
            } catch (Error e) {
                warning (e.message);
            }

            try {
                if (is_mic_recorded && is_speakers_recorded && default_output != "") {
                    audiobin = (Gst.Bin)Gst.parse_bin_from_description ("adder name=mux ! audioconvert ! audioresample ! vorbisenc pulsesrc ! queue ! mux. pulsesrc device=" + default_output + ".monitor ! queue ! mux.", true);
                } else if (is_mic_recorded) {
                    audiobin = (Gst.Bin)Gst.parse_bin_from_description ("pulsesrc name=\"audiosrc\" ! audioconvert ! vorbisenc ! queue", true);
                } else if (is_speakers_recorded && default_output != "") {
                    audiobin = (Gst.Bin)Gst.parse_bin_from_description ("pulsesrc device=" + default_output + ".monitor ! audioconvert ! vorbisenc ! queue", true);
                }
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }

            string cores = "0-1";

            try {
                Process.spawn_command_line_sync ("cat /sys/devices/system/cpu/online", out cores);
            } catch (Error e) {
                warning (e.message);
            }

            //configure
            assert (sink != null);
            //  /!\
            //string tmp_path = GLib.Environment.get_tmp_dir () + "/screencast_" + new GLib.DateTime.now_local ().to_unix ().to_string () + ".webm";
            sink.set ("location", tmp_file_path);

            var src = videobin.get_by_name ("videosrc");

            assert (src != null);

            Gdk.Rectangle selection_rect;
            window.get_frame_extents (out selection_rect);
            width = selection_rect.width;
            height = selection_rect.height;

            if (capture_mode == ScreenrecorderWindow.CaptureType.SCREEN || 
                capture_mode == ScreenrecorderWindow.CaptureType.CURRENT_WINDOW) {
                
                int startx = selection_rect.x;  //this.monitor_rec.x * scale;
                int starty = selection_rect.y;  //this.monitor_rec.y * scale;
                int endx = selection_rect.x + selection_rect.width; //settings.sx + this.monitor_rec.width * scale - 1;
                int endy = selection_rect.y + selection_rect.height; //settings.sy + this.monitor_rec.height * scale - 1;

                src.set ("startx", startx);
                src.set ("starty", starty);
                src.set ("endx",   endx);
                src.set ("endy",   endy);

            } else if (capture_mode == ScreenrecorderWindow.CaptureType.AREA) {

                src.set ("xid", ((Gdk.X11.Window) window).get_xid());
            }
            
            src.set ("use-damage", false);
            src.set ("display-name", 0); // ------ /!\ ------

            // videobin.get_by_name ("encoder").set  ("mode", 1);
            var encoder = videobin.get_by_name ("encoder");

            assert (encoder != null);

            // From these values see https://mail.gnome.org/archives/commits-list/2012-September/msg08183.html
            encoder.set ("min_quantizer", 13);
            encoder.set ("max_quantizer", 13);
            encoder.set ("cpu-used", 5);
            encoder.set ("deadline", 1000000);
            encoder.set ("threads", int.parse (cores.substring (2)));

            if (pipeline == null || muxer == null || sink == null || videobin == null || audiobin == null) {
                stderr.printf ("Error: Elements weren't made correctly!\n");
            }

            if (is_mic_recorded || (is_speakers_recorded && default_output != "")) {
                pipeline.add_many (audiobin, videobin, muxer, sink);
            } else {
                pipeline.add_many (videobin, muxer, sink);
            }

            videobin.get_static_pad ("src").link (muxer.get_request_pad ("video_%u"));

            if (is_mic_recorded || (is_speakers_recorded && default_output != "")) {
                audiobin.get_static_pad ("src").link (muxer.get_request_pad ("audio_%u"));
            }

            muxer.link (sink);

            pipeline.get_bus ().add_watch (Priority.DEFAULT, bus_message_cb);
            pipeline.set_state (Gst.State.READY);

        }

        private bool bus_message_cb (Gst.Bus bus, Gst.Message msg) {
            switch (msg.type) {
            case Gst.MessageType.ERROR :
                GLib.Error err;

                string debug;

                msg.parse_error (out err, out debug);

                //display_error ("Screencast encountered a gstreamer error while recording, creating a screencast is not possible:\n%s\n\n[%s]".printf (err.message, debug), true);
                stderr.printf ("Error: %s\n", debug);
                pipeline.set_state (Gst.State.NULL);
                break;
            case Gst.MessageType.EOS :
                pipeline.set_state (Gst.State.NULL);

                this.is_recording = false;

                //save_file ();
                pipeline.dispose ();
                pipeline = null;
                break;
            default :
                break;
            }

            return true;
        }

        public void start () {

            pipeline.set_state (Gst.State.PLAYING);
            this.is_recording = true;

        }

        public void pause () {

            pipeline.set_state (Gst.State.PAUSED);
            this.is_recording = false;
        }

        public void resume () {

            this.pipeline.set_state (Gst.State.PLAYING);
            this.is_recording = true;
        }

        public void stop () {

            if (!this.is_recording) {
                this.resume();
            }
            pipeline.send_event (new Gst.Event.eos ());
            this.is_recording = false;
        }
    }
}