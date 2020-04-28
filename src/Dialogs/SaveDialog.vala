/*
 * Copyright (c) 2014–2016 Fabio Zaramella <ffabio.96.x@gmail.com>
 *               2017–2018 elementary LLC. (https://elementary.io)
 *               2020 Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 3 as published by the Free Software Foundation.
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
 *              Artem Anufrij <artem.anufrij@live.de>
 *              Fabio Zaramella <ffabio.96.x@gmail.com>
 *              Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
 */

namespace ScreenRec {

    public class SaveDialog : Gtk.Dialog {

        public string filepath { get; construct; }
        public int expected_width {get; construct;}
        public int expected_height {get; construct;}
        private string extension;
        public Cancellable cancellable;

        private Gtk.Entry name_entry;
        private Gtk.Button save_btn;
        private VideoPlayer preview;
        private string folder_dir = Environment.get_user_special_dir (UserDirectory.VIDEOS)
        +  "%c".printf(GLib.Path.DIR_SEPARATOR) + ScreenRecApp.SAVE_FOLDER;

        public SaveDialog (Gtk.Window parent, string filepath, int expected_width, int expected_height, string extension) {
            Object (
                border_width: 0,
                deletable: false,
                modal: true,
                resizable: false,
                title: parent.title,
                transient_for: parent,
                filepath: filepath,
                expected_width: expected_width,
                expected_height: expected_height,
                application: parent.application
            );

            this.extension = extension;
            response.connect (manage_response);
        }

        construct {
            GLib.Settings settings = ScreenRecApp.settings;
            Gdk.Rectangle selection_rect;
            Gdk.get_default_root_window ().get_frame_extents (out selection_rect);
            int max_width_height = selection_rect.height*46/100;
            debug ("Max width/height: %d",max_width_height);
            preview = new VideoPlayer (filepath, expected_width, expected_height, max_width_height);

            var preview_box = new Gtk.Grid ();
            preview_box.halign = Gtk.Align.CENTER;
            preview_box.add (preview);

            var preview_box_context = preview_box.get_style_context ();
            preview_box_context.add_class ("card");

            var dialog_label = new Gtk.Label (_("Save record as…"));
            dialog_label.get_style_context ().add_class ("h4");
            dialog_label.halign = Gtk.Align.START;

            var name_label = new Gtk.Label (_("Name:"));
            name_label.halign = Gtk.Align.END;

            var screen_scale = this.scale_factor;
            var file_name = get_file_name (screen_scale);

            name_entry = new Gtk.Entry ();
            name_entry.hexpand = true;
            name_entry.text = file_name;

            var location_label = new Gtk.Label (_("Folder:"));
            location_label.halign = Gtk.Align.END;

            var folder_from_settings = settings.get_string ("folder-dir");

            if (folder_from_settings != folder_dir && folder_from_settings != "") {
                folder_dir = folder_from_settings;
            }
            ScreenRecApp.create_dir_if_missing (folder_dir);

            var location = new Gtk.FileChooserButton (_("Select Screen Records Folder…"), Gtk.FileChooserAction.SELECT_FOLDER);
            location.set_filename (folder_dir);

            var grid = new Gtk.Grid ();
            grid.margin = 12;
            grid.margin_top = 0;
            grid.margin_bottom = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.attach (preview_box, 0, 0, 2, 1);
            grid.attach (dialog_label, 0, 1, 2, 1);
            grid.attach (name_label, 0, 2, 1, 1);
            grid.attach (name_entry, 1, 2, 1, 1);
            grid.attach (location_label, 0, 3, 1, 1);
            grid.attach (location, 1, 3, 1, 1);

            var content = this.get_content_area () as Gtk.Box;
            content.margin_top = 0;
            content.add (grid);

            var cancel_btn = add_button (_("Cancel"), 0);
            cancel_btn.margin_bottom = 6;

            save_btn = add_button (_("Save"), 1) as Gtk.Button;
            save_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            save_btn.margin_end = 6;
            save_btn.margin_bottom = 6;

            location.selection_changed.connect (() => {
                settings.set_string ("folder-dir", location.get_filename ());
                folder_dir = settings.get_string ("folder-dir");
            });

            key_press_event.connect ((e) => {
                if (e.keyval == Gdk.Key.Return) {
                    manage_response (1);
                }
                return false;
            });
        }

        private void manage_response (int response_id) {

            if (response_id == 1) {

                cancellable = new Cancellable ();

                if (preview.is_playing()) {

                    preview.play_pause();
                }

                File tmp_file = File.new_for_path (filepath);
                string file_name = Path.build_filename (folder_dir, "%s%s".printf (name_entry.get_text (), extension));
                File save_file = File.new_for_path (file_name);

                try {

                    save_btn.always_show_image = true;
                    var spinner = new Gtk.Spinner ();
                    save_btn.set_image (spinner);
                    spinner.start ();
                    sensitive = false;

                    // progress_dialog.show_all ();
                    debug("Progress Dialog MOVE!");
                    tmp_file.move (save_file, 0, cancellable, null); //progress_callback

                } catch (Error e) {

                    print ("Error: %s\n", e.message);
                }

                close ();

            } else if (response_id == 0) {

                GLib.FileUtils.remove (filepath);
                close ();
            }
        }

        private string get_file_name (double d_screen_scale) {

            var date_time = new GLib.DateTime.now_local ().format ("%Y-%m-%d %H.%M.%S");
            var file_name = _("Screen record from %s").printf (date_time);

            var d_file_scale = (d_screen_scale < 1)? 1 : d_screen_scale;
            var file_scale = (int) d_file_scale;

            if (file_scale > 1) {
                file_name += "@%ix".printf (file_scale);
            }
            return file_name;
        }
    }
}
