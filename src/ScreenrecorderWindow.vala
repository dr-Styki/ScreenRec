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

        private Gtk.RadioButton all;
        private Gtk.RadioButton curr_window;
        private Gtk.RadioButton selection;

        //Actons Buttons
        public Gtk.Button right_button;
        public Gtk.Button left_button;
        private Gtk.Box actions;

        // Global Grid
        private SettingsView settings_views;
        private RecordView record_view;
        private Gtk.Stack stack;
        private Gtk.Grid grid;
  
        // Others
        public Gdk.Window win;
        private Recorder recorder;
        public Countdown countdown;
        private string tmpfilepath;
        private bool save_dialog_present = false;
        public SendNotification send_notification;

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
            send_notification = new SendNotification(this);
            recorder = new Recorder();
            countdown = new Countdown (this, this.send_notification);

            // Select Screen/Area
            all = new Gtk.RadioButton (null);
            all.image = new Gtk.Image.from_icon_name ("grab-screen-symbolic", Gtk.IconSize.DND);
            all.tooltip_text = _("Grab the whole screen");

            curr_window = new Gtk.RadioButton.from_widget (all);
            curr_window.image = new Gtk.Image.from_icon_name ("grab-window-symbolic", Gtk.IconSize.DND);
            curr_window.tooltip_text = _("Grab the current window");

            selection = new Gtk.RadioButton.from_widget (curr_window);
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

            // Views
            settings_views = new SettingsView (this);
            record_view = new RecordView ();
            stack = new Gtk.Stack ();
            stack.add_named (settings_views, "settings");
            stack.add_named (record_view, "record");
            stack.visible_child_name = "settings";

            // Right Button
            right_button = new Gtk.Button.with_label (_("Record Screen"));
            right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            right_button.can_default = true;
            this.set_default (right_button);

            // Left Button
            left_button = new Gtk.Button.with_label (_("Close"));

            // Actions : [Close][Record]
            actions = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            actions.margin_top = 24;
            actions.set_hexpand(true);
            actions.set_homogeneous(true);
            actions.add (left_button);
            actions.add (right_button);

            // Main Grid
            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.margin_top = 0;
            grid.row_spacing = 6;
            grid.set_hexpand(true);
            grid.attach (stack   , 0, 1, 2, 7);
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
            } else if (settings.get_enum ("last-capture-mode") == CaptureType.CURRENT_WINDOW){
                capture_mode = CaptureType.CURRENT_WINDOW;
                curr_window.active = true;
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
                    send_notification.stop();
                    

                } else if (!recorder.is_recording && !countdown.is_active_cd && recorder.is_recording_in_progress) {

                    recorder.resume ();
                    stop_recording ();
                    send_notification.stop();

                } else if (!recorder.is_recording && countdown.is_active_cd && !recorder.is_recording_in_progress) {

                    countdown.cancel ();
                    right_button.set_label (_("Record Screen"));
                    right_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                    right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    left_button.set_label (_("Close"));
                    settings_views.set_sensitive (true);
                    capture_type_grid.set_sensitive (true);
                    send_notification.cancel_countdown();
                }
            });

            left_button.clicked.connect (() => {

                if (recorder.is_recording && !countdown.is_active_cd && recorder.is_recording_in_progress) {

                    recorder.pause();
                    record_view.pause_count ();
                    left_button.set_label (_("Resume"));
                    send_notification.pause();

                } else if (!recorder.is_recording && !countdown.is_active_cd && recorder.is_recording_in_progress) {

                    recorder.resume();
                    record_view.resume_count ();
                    left_button.set_label (_("Pause"));
                    send_notification.resume();

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

            var gtk_settings = Gtk.Settings.get_default ();
            gtk_settings.notify["gtk-application-prefer-dark-theme"].connect (() => {
                update_icons (gtk_settings.gtk_application_prefer_dark_theme);
            });
        }

        private void update_icons (bool prefers_dark) {
            if (prefers_dark) {
                all.image = new Gtk.Image.from_icon_name ("grab-screen-symbolic-dark", Gtk.IconSize.DND);
            } else {
                all.image = new Gtk.Image.from_icon_name ("grab-screen-symbolic", Gtk.IconSize.DND);
            }
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
            tmpfilepath = Path.build_filename (temp_dir, "ScreenRec-%08x%s".printf (Random.next_int (), settings_views.extension));
            debug ("Temp file created at: %s", tmpfilepath);

            // Init Recorder
            recorder = new Recorder();
            recorder.config(capture_mode,
                            tmpfilepath, 
                            settings_views.framerate, 
                            settings_views.speakers_record, 
                            settings_views.mic_record,
                            settings_views.pointer_switch.get_state(),
                            settings_views.format,
                            win);

            // Delay before recording ?
            if (settings_views.delay > 0) {

                countdown = new Countdown (this, this.send_notification);
                countdown.set_delay(settings_views.delay);
                countdown.start(recorder, this, stack, record_view);
                right_button.set_label (_("Cancel"));
                right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                left_button.set_label (_("Minimise"));

            } else {

                recorder.start();
                record_view.init_count ();
                stack.visible_child_name = "record";
                send_notification.start();
                right_button.set_label (_("Stop Recording"));
                right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                left_button.set_label (_("Pause"));
            }
            right_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            settings_views.set_sensitive (false);
            capture_type_grid.set_sensitive (false);
        }

        void stop_recording () {

            // Update Buttons
            right_button.set_label (_("Record Screen"));
            right_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            left_button.set_label (_("Close"));

            // Stop Recording
            recorder.stop ();
            record_view.stop_count ();
            stack.visible_child_name = "settings";
            present ();

            // Open Sav Dialog
            var save_dialog = new SaveDialog (this, tmpfilepath, recorder.width, recorder.height, settings_views.extension);
            save_dialog_present = true;
            //save_dialog.set_keep_above (true);
            debug("Sav Dialog Open");
            save_dialog.show_all ();
            debug("Sav Dialog Close");
            //save_dialog.set_keep_above (false);

            save_dialog.close.connect (() => {

                debug("Sav Dialog Close Connect");

                save_dialog_present = false;
                settings_views.set_sensitive (true);
                capture_type_grid.set_sensitive (true);

                //if close after saving
                if(settings_views.close_switch.get_state()) { 

                    close();
                }
            });
        }

        public void set_capture_type(int capture_type) {

            switch (capture_type) {
                case 1:
                    all.activate();
                    break;
                case 2:
                    curr_window.activate();
                    break;
                case 3:
                    selection.activate();
                    break;
            }

        }

        public void autostart () {

            right_button.activate();
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