/* Copyright 2011-2019 elementary, Inc. (https://elementary.io)
*                      2020 Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
*
* This program is free software: you can redistribute it
* and/or modify it under the terms of the GNU Lesser General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see http://www.gnu.org/licenses/.
*/

namespace ScreenRec {

    public class ProgressDialog : Gtk.Dialog {

        public Cancellable cancellable;
        //public FileProgressCallback progress_callback;
        private Gtk.ProgressBar progress_bar;

        public ProgressDialog (Gtk.Window parent, Cancellable? cancellable) { //, FileProgressCallback? progress_callback

            Object (
                border_width: 0,
                deletable: false,
                modal: true,
                resizable: false,
                title: parent.title,
                transient_for: parent,
                application: parent.application
            );

            this.cancellable = cancellable;
            //this.progress_callback = progress_callback;
        }

        construct {
            var image = new Gtk.Image.from_icon_name ("edit-copy", Gtk.IconSize.DIALOG);
            image.valign = Gtk.Align.START;

            var primary_label = new Gtk.Label (null);
            primary_label.max_width_chars = 50;
            primary_label.wrap = true;
            primary_label.xalign = 0;
            primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);
            primary_label.label = _("Video recording in progress");

            progress_bar = new Gtk.ProgressBar ();
            progress_bar.width_request = 300;
            progress_bar.hexpand = true;
            progress_bar.valign = Gtk.Align.START;

            progress_bar.fraction = 30 / 100.0;

            var cancel_button = (Gtk.Button) add_button (_("Cancel"), 0);

            var grid = new Gtk.Grid ();
            grid.column_spacing = 12;
            grid.row_spacing = 6;
            grid.margin = 6;
            grid.attach (image, 0, 0, 1, 2);
            grid.attach (primary_label, 1, 0);
            grid.attach (progress_bar, 1, 1);
            grid.show_all ();

            border_width = 6;
            deletable = false;
            get_content_area ().add (grid);

            cancel_button.clicked.connect (() => {

                this.cancellable.cancel ();
                destroy ();
            });
        }
    }

    //public int progress {
    //    set {
    //        if (value >= 100) {
    //            destroy ();
    //        }
    //        // progress_bar.fraction = value / 100.0;
    //        progress_bar.fraction = value / 100.0;
    //    }
    //}
}