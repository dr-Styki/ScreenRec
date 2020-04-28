/*
* Copyright (c) 2018 Mohammed ALMadhoun <mohelm97@gmail.com>
*               2020 Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
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
* Authored by: Mohammed ALMadhoun <mohelm97@gmail.com>
*              Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
*/

namespace ScreenRec {

    public class ScreenrecorderWindow : Gtk.ApplicationWindow  {

        // Capture Type Buttons
        public enum CaptureType {
            SCREEN,
            CURRENT_WINDOW,
            AREA
        }
        public CaptureType capture_mode = CaptureType.SCREEN;
        private Gtk.Grid capture_type_grid;

        // Settings Buttons/Switch/ComboBox

            // Mouse pointer and close switch
        private Gtk.Switch pointer_switch;
        private Gtk.Switch close_switch;

            // Audio
        private Gtk.CheckButton record_speakers_btn;
        private Gtk.CheckButton record_mic_btn;
        private Gtk.Image speaker_icon;
        private Gtk.Image speaker_icon_mute;
        private Gtk.Image mic_icon;
        private Gtk.Image mic_icon_mute;
        private bool speakers_record = false;
        private bool mic_record = false;

        private int delay;
        private int framerate;

            // Format
        private enum Column {
            CODEC_GSK,
            CODEC_USER,
            CODEC_EXT
        }
        public const string[] codec_gsk = {"x264enc", "vp8enc", "avenc_huffyuv", "avenc_ljpeg", "raw"};
        public const string[] codec_user = {"mp4 (h264)", "webm (vp8)", "avi (huffyuv)", "avi (lossless jpeg)", "avi (raw)"};
        public const string[] codec_ext = {".mp4", ".webm", ".avi", ".avi", ".avi"};
        private Gtk.ComboBox format_cmb;
        private string format;
        private string extension;

        // Capture Type + Settings Grid
        private Gtk.Grid sub_grid;

        //Actons Buttons
        public Gtk.Button right_button;
        public Gtk.Button left_button;
        private Gtk.Box actions;

        // Global Grid
        private Gtk.Grid grid;
  
        // Others
        public Gdk.Window win;
        private Recorder recorder;
        public Countdown countdown;
        private string tmpfilepath;
        private bool save_dialog_present = false;
        

        public ScreenrecorderWindow (Gtk.Application app){
            Object (
                application: app,
                border_width: 6,
                resizable: false
            );
        }

        construct {

            set_keep_above (true);
            // Load Settings
            GLib.Settings settings = ScreenRecApp.settings;

            // Init recorder and countdown objects for boolean test 
            recorder = new Recorder();
            countdown = new Countdown (this);

            // Select Screen/Area
            var all = new Gtk.RadioButton (null);
            all.image = new Gtk.Image.from_icon_name ("grab-screen-symbolic", Gtk.IconSize.DND);
            all.tooltip_text = _("Grab the whole screen");

            var curr_window = new Gtk.RadioButton.from_widget (all);
            curr_window.image = new Gtk.Image.from_icon_name ("grab-window-symbolic", Gtk.IconSize.DND);
            curr_window.tooltip_text = _("Grab the current window");

            var selection = new Gtk.RadioButton.from_widget (curr_window);
            selection.image = new Gtk.Image.from_icon_name ("grab-area-symbolic", Gtk.IconSize.DND);
            selection.tooltip_text = _("Select area to grab");

            capture_type_grid = new Gtk.Grid ();
            capture_type_grid.halign = Gtk.Align.CENTER;
            capture_type_grid.column_spacing = 24;
            capture_type_grid.margin_top = capture_type_grid.margin_bottom = 24;
            capture_type_grid.margin_start = capture_type_grid.margin_end = 18;
            capture_type_grid.add (all);
            capture_type_grid.add (curr_window);
            capture_type_grid.add (selection);

            // Grab mouse pointer ? 
            var pointer_label = new Gtk.Label (_("Grab mouse pointer:"));
            pointer_label.halign = Gtk.Align.END;

            pointer_switch = new Gtk.Switch ();
            pointer_switch.halign = Gtk.Align.START;

            // Close after saving ?
            var close_label = new Gtk.Label (_("Close after saving:"));
            close_label.halign = Gtk.Align.END;

            close_switch = new Gtk.Switch ();
            close_switch.halign = Gtk.Align.START;

            // Record Sounds ?
            var audio_label = new Gtk.Label (_("Record sounds:"));
            audio_label.halign = Gtk.Align.END;

                // From Speakers
            record_speakers_btn = new Gtk.CheckButton ();
            record_speakers_btn.tooltip_text = _("Record sounds from speakers");
            record_speakers_btn.toggled.connect(() => {
                speakers_record = !speakers_record;
                if (speakers_record) {
                    record_speakers_btn.image = speaker_icon;
                    record_speakers_btn.get_style_context ().add_class (Granite.STYLE_CLASS_ACCENT);
                } else {
                    record_speakers_btn.image = speaker_icon_mute;
                    record_speakers_btn.get_style_context ().remove_class (Granite.STYLE_CLASS_ACCENT);
                }
            });
            speaker_icon = new Gtk.Image.from_icon_name ("audio-volume-high-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            speaker_icon_mute = new Gtk.Image.from_icon_name ("audio-volume-muted-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            record_speakers_btn.image = speaker_icon_mute;

                // From Mic
            record_mic_btn = new Gtk.CheckButton ();
            record_mic_btn.tooltip_text = _("Record sounds from microphone");
            record_mic_btn.toggled.connect(() => {
                mic_record = !mic_record;
                if (mic_record) {
                    record_mic_btn.image = mic_icon;
                    record_mic_btn.get_style_context ().add_class (Granite.STYLE_CLASS_ACCENT);
                } else {
                    record_mic_btn.image = mic_icon_mute;
                    record_mic_btn.get_style_context ().remove_class (Granite.STYLE_CLASS_ACCENT);
                }
            });
            mic_icon = new Gtk.Image.from_icon_name ("microphone-sensitivity-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            mic_icon_mute = new Gtk.Image.from_icon_name ("microphone-sensitivity-muted-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            record_mic_btn.image = mic_icon_mute;

                // Audio Buttons Grid
            var audio_grid = new Gtk.Grid ();
            audio_grid.halign = Gtk.Align.START;
            audio_grid.column_spacing = 12;
            audio_grid.add (record_speakers_btn);
            audio_grid.add (record_mic_btn);

            // Delay before capture
            var delay_label = new Gtk.Label (_("Delay in seconds:"));
            delay_label.halign = Gtk.Align.END;
            var delay_spin = new Gtk.SpinButton.with_range (0, 15, 1);

            // Frame rate
            var framerate_label = new Gtk.Label (_("Frame rate:"));
            framerate_label.halign = Gtk.Align.END;
            var framerate_spin = new Gtk.SpinButton.with_range (1, 120, 1);

            // Format Combo Box - Start
            var format_label = new Gtk.Label (_("Format:"));
            format_label.halign = Gtk.Align.END;

            Gtk.ListStore list_store = new Gtk.ListStore (3, typeof (string),typeof (string),typeof (string));

            for (int i = 0; i < codec_gsk.length; i++) {

                Gtk.TreeIter iter;
                list_store.append (out iter);
                list_store.set(iter, Column.CODEC_GSK, codec_gsk[i],
                                    Column.CODEC_USER, codec_user[i],
                                    Column.CODEC_EXT, codec_ext[i]);

            }

            format_cmb = new Gtk.ComboBox.with_model (list_store);
            Gtk.CellRendererText cell = new Gtk.CellRendererText ();
            format_cmb.pack_start (cell, false);
            format_cmb.set_attributes (cell, "text", Column.CODEC_USER);
            string saved_format = settings.get_string ("format");
            for (int i = 0; i < codec_gsk.length; i++) {

                if (saved_format == codec_gsk[i]) {

                    this.format_cmb.set_active (i);
                    this.format = codec_gsk[i];
                    this.extension = codec_ext[i];
                    break;
                }
            }
            // Format Combo Box - End

            // Record Button
            right_button = new Gtk.Button.with_label (_("Record Screen"));
            right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            right_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>R"}, _("Toggle recording"));
            right_button.can_default = true;
            this.set_default (right_button);

            // Close Button
            left_button = new Gtk.Button.with_label (_("Close"));

            // Actions : [Close][Record]
            actions = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            actions.margin_top = 24;
            actions.set_hexpand(true);
            actions.set_homogeneous(true);
            actions.add (left_button);
            actions.add (right_button);

            // Sub Grid, all switch/checkbox/combobox/spin
            // except Actions.
            sub_grid = new Gtk.Grid ();
            sub_grid.halign = Gtk.Align.CENTER;
            sub_grid.margin = 0;
            sub_grid.row_spacing = 6;
            sub_grid.column_spacing = 12;
            sub_grid.attach (pointer_label     , 0, 1, 1, 1);
            sub_grid.attach (pointer_switch    , 1, 1, 1, 1);
            sub_grid.attach (close_label       , 0, 2, 1, 1);
            sub_grid.attach (close_switch      , 1, 2, 1, 1);
            sub_grid.attach (audio_label       , 0, 3, 1, 1);
            sub_grid.attach (audio_grid        , 1, 3, 1, 1);
            sub_grid.attach (delay_label       , 0, 4, 1, 1);
            sub_grid.attach (delay_spin        , 1, 4, 1, 1);
            sub_grid.attach (framerate_label   , 0, 5, 1, 1);
            sub_grid.attach (framerate_spin    , 1, 5, 1, 1);
            sub_grid.attach (format_label       , 0, 6, 1, 1);
            sub_grid.attach (format_cmb    , 1, 6, 1, 1);

            // Main Grid
            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.margin_top = 0;
            grid.row_spacing = 6;
            grid.set_hexpand(true);
            grid.attach (sub_grid   , 0, 1, 2, 7);
            grid.attach (actions    , 0, 8, 2, 1);

            // TitleBar (HeaderBar) with capture_type_grid (Screen/Area selection) attach.
            var titlebar = new Gtk.HeaderBar ();
            titlebar.has_subtitle = false;
            titlebar.set_custom_title (capture_type_grid);

            var titlebar_style_context = titlebar.get_style_context ();
            titlebar_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            titlebar_style_context.add_class ("default-decoration");

            set_titlebar (titlebar);
            add (grid);


            // Bind Settings - Start
            if (settings.get_enum ("last-capture-mode") == CaptureType.AREA){
                capture_mode = CaptureType.AREA;
                selection.active = true;
            }

            all.toggled.connect (() => {
                capture_mode = CaptureType.SCREEN;
                settings.set_enum ("last-capture-mode", capture_mode);
            });

            curr_window.toggled.connect (() => {
                capture_mode = CaptureType.CURRENT_WINDOW;
                settings.set_enum ("last-capture-mode", capture_mode);
            });

            selection.toggled.connect (() => {
                capture_mode = CaptureType.AREA;
                settings.set_enum ("last-capture-mode", capture_mode);
            });

            settings.bind ("mouse-pointer", pointer_switch, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("close-on-save", close_switch, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("record-computer", record_speakers_btn, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("record-microphone", record_mic_btn, "active", GLib.SettingsBindFlags.DEFAULT);

            settings.bind ("delay", delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);
            delay_spin.value_changed.connect (() => {
                delay = delay_spin.get_value_as_int ();
            });
            delay = delay_spin.get_value_as_int ();

            settings.bind ("framerate", framerate_spin, "value", GLib.SettingsBindFlags.DEFAULT);
            framerate_spin.value_changed.connect (() => {
                framerate = framerate_spin.get_value_as_int ();
            });
            framerate = framerate_spin.get_value_as_int ();

            format_cmb.changed.connect (() => {
                settings.set_string ("format", codec_gsk[format_cmb.get_active ()]);
                this.format = codec_gsk[format_cmb.get_active ()];
                this.extension = codec_ext[format_cmb.get_active ()];
            });
            // Bind Settings - End

            // Connect Buttons
            right_button.clicked.connect (() => { 

                if (!recorder.is_recording && !countdown.is_active_cd && !recorder.is_recording_in_progress) {

                    switch (capture_mode) {
                        case CaptureType.SCREEN:
                            capture_screen ();
                            break;
                        case CaptureType.CURRENT_WINDOW:
                            capture_window ();
                            break;
                        case CaptureType.AREA:
                            capture_area ();
                            break;
                    }

                } else if (recorder.is_recording && !countdown.is_active_cd && recorder.is_recording_in_progress) {

                    stop_recording ();

                } else if (!recorder.is_recording && !countdown.is_active_cd && recorder.is_recording_in_progress) {

                    recorder.resume ();
                    stop_recording ();

                } else if (!recorder.is_recording && countdown.is_active_cd && !recorder.is_recording_in_progress) {

                    countdown.cancel ();
                    right_button.set_label (_("Record Screen"));
                    right_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                    right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    left_button.set_label (_("Close"));
                    sub_grid.set_sensitive (true);
                    capture_type_grid.set_sensitive (true);
                }
            });

            left_button.clicked.connect (() => {

                if (recorder.is_recording && !countdown.is_active_cd && recorder.is_recording_in_progress) {

                    recorder.pause();
                    left_button.set_label (_("Resume"));

                } else if (!recorder.is_recording && !countdown.is_active_cd && recorder.is_recording_in_progress) {

                    recorder.resume();
                    left_button.set_label (_("Pause"));

                } else if (!recorder.is_recording && countdown.is_active_cd && !recorder.is_recording_in_progress) {

                    iconify ();

                } else if (!recorder.is_recording && !countdown.is_active_cd && !recorder.is_recording_in_progress) {

                    close ();
                }
            });

            // Prevent delete event if record 
            delete_event.connect (() => {
                if (can_quit()) {

                    return false;

                } else {

                    iconify ();
                    return true;
                }
            });
        }

        void capture_screen () {

            this.win = Gdk.get_default_root_window ();
            this.iconify ();
            start_recording (this.win);
        }

        void capture_window () {

            Gdk.Screen screen = null;
            GLib.List<Gdk.Window> list = null;
            screen = Gdk.Screen.get_default ();
            this.iconify ();

            Timeout.add (300, () => { // Wait iconify

                list = screen.get_window_stack ();

                foreach (Gdk.Window item in list) {
                    if (screen.get_active_window () == item) {
                        this.win = item;
                    }
                }

                if (this.win != null) {
                    start_recording (win);
                }
                return false;
            });
        }

        void capture_area () {

            var selection_area = new Screenshot.Widgets.SelectionArea ();
            selection_area.show_all ();

            selection_area.cancelled.connect (() => {

                selection_area.close ();
            });

            this.win = selection_area.get_window ();

            selection_area.captured.connect (() => {

                selection_area.close ();
                this.iconify ();
                start_recording (this.win);
            });
        }

        void start_recording (Gdk.Window? win) {

            // Temp file
            var temp_dir = Environment.get_tmp_dir ();
            tmpfilepath = Path.build_filename (temp_dir, "ScreenRec-%08x%s".printf (Random.next_int (), extension));
            debug ("Temp file created at: %s", tmpfilepath);

            // Init Recorder
            recorder = new Recorder();
            recorder.config(capture_mode,
                            tmpfilepath, 
                            framerate, 
                            speakers_record, 
                            mic_record,
                            pointer_switch.get_state(),
                            format,
                            win);

            // Delay before recording ?
            if (delay > 0) {

                countdown = new Countdown (this);
                countdown.set_delay(delay);
                countdown.start(recorder, this);
                right_button.set_label (_("Cancel"));
                right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                left_button.set_label (_("Minimise"));

            } else {

                recorder.start();
                right_button.set_label (_("Stop Recording"));
                right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                left_button.set_label (_("Pause"));
            }

            sub_grid.set_sensitive (false);
            capture_type_grid.set_sensitive (false);
        }

        void stop_recording () {

            // Update Buttons
            right_button.set_label (_("Record Screen"));
            right_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            left_button.set_label (_("Close"));

            // Stop Recording
            recorder.stop();
            present ();

            // Open Sav Dialog
            var save_dialog = new SaveDialog (this, tmpfilepath, recorder.width, recorder.height, extension);
            save_dialog_present = true;
            //save_dialog.set_keep_above (true);
            debug("Sav Dialog Open");
            save_dialog.show_all ();
            debug("Sav Dialog Close");
            //save_dialog.set_keep_above (false);

            save_dialog.close.connect (() => {

                debug("Sav Dialog Close Connect");

                save_dialog_present = false;

                //if close after saving
                if(close_switch.get_state()) { 

                    close();

                } else {

                    sub_grid.set_sensitive (true);
                    capture_type_grid.set_sensitive (true);
                }
            });
        }

        public bool can_quit () {

            if (recorder.is_recording_in_progress || countdown.is_active_cd) {

                return false;

            } else {

                return true;
            }
        }
    }
}