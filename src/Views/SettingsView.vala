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

    public class SettingsView : Gtk.Box {

        public ScreenrecorderWindow window { get; construct; }

            // Settings Buttons/Switch/ComboBox
                // Mouse pointer and close switch
            public Gtk.Switch pointer_switch;
            public Gtk.Switch close_switch;
    
                // Audio
            private Gtk.CheckButton record_speakers_btn;
            private Gtk.CheckButton record_mic_btn;
            private Gtk.Image speaker_icon;
            private Gtk.Image speaker_icon_mute;
            private Gtk.Image mic_icon;
            private Gtk.Image mic_icon_mute;
            public bool speakers_record = false;
            public bool mic_record = false;
    
            public int delay;
            public int framerate;
    
                // Format
            private enum Column {
                CODEC_GSK,
                CODEC_USER,
                CODEC_EXT
            }
            public const string[] codec_gsk = {"x264enc", "x264enc-mkv", "vp8enc"};
            public const string[] codec_user = {"mp4", "mkv", "webm"};
            public const string[] codec_ext = {".mp4", ".mkv", ".webm"};
            // Disable the use of lossless/Raw codec for now.
            // public const string[] codec_gsk = {"x264enc", "vp8enc", "avenc_huffyuv", "avenc_ljpeg", "raw"};
            // public const string[] codec_user = {"mp4 (h264)", "webm (vp8)", "avi (huffyuv)", "avi (lossless jpeg)", "avi (raw)"};
            // public const string[] codec_ext = {".mp4", ".webm", ".avi", ".avi", ".avi"};

            private Gtk.ComboBox format_cmb;
            public string format;
            public string extension;
    
            // Settings Grid
            private Gtk.Grid sub_grid;


        public SettingsView (ScreenrecorderWindow window) {

            Object (
                orientation: Gtk.Orientation.VERTICAL,
                spacing: 12,
                window: window,
                margin: 0
            );
        }

        construct {

            // Load Settings
            GLib.Settings settings = ScreenRecApp.settings;

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
            record_speakers_btn.tooltip_text = _("Record sound from computer");
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
            record_mic_btn.tooltip_text = _("Record sound from microphone");
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

            add(sub_grid);

            // Bind Settings - Start
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

        }

    }
}
