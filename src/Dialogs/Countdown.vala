/*
 *  Copyright (C) 2011-2015 Eidete Developers
 *  Copyright (C) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
 *  Copyright (C) 2020 Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

namespace ScreenRec {

    public class Countdown : Gtk.Dialog {
        
        public Gtk.Label count;
        public int time = 0;
        public bool is_active_cd { get; private set; default = false; }
        private bool is_canceled = false;
        private SendNotification send_notification;

        public Countdown (Gtk.Window parent, SendNotification? send_notification) {

            Object (
                title: parent.title,
                application: parent.application
            );

            this.send_notification = send_notification;

            window_position = Gtk.WindowPosition.CENTER;
            set_default_size (400, 200);
            set_resizable (false);
            set_keep_above (true);
            set_deletable(false);
            stick ();

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.margin_start = 30;
            box.margin_end = 40;
            box.margin_top = box.margin_bottom = 20;

            var title = new Gtk.Label ("<span size='20000'>" + _("Recording starts in…") + "</span>");
            title.use_markup = true;
            title.margin_bottom = 10;

            this.count = new Gtk.Label ("<span size='50000'>" + time.to_string () + "</span>");
            this.count.use_markup = true;

            box.pack_start (title);
            box.pack_start (count);

            var content_area = this.get_content_area ();
            content_area.add (box);

            delete_event.connect (() => {
                
                return true;
            });
        }

        public void start (Recorder? recorder, ScreenrecorderWindow? app, Gtk.Stack? stack, RecordView? record_view) {

            this.is_active_cd = true;
            this.show_all ();

            Timeout.add (1000, () => { // Wait 1s

                this.time--;
                this.count.label = "<span size='50000'>" + this.time.to_string () + "</span>";

                if (time == -1) {

                    this.destroy ();
                    Timeout.add (100, () => { // Wait 100ms, let the countdown disappear before starting

                        if (!is_canceled) {

                            recorder.start ();
                            stack.visible_child_name = "record";
                            record_view.init_count ();
                            send_notification.start();
                            this.is_active_cd = false;
                            app.right_button.set_label (_("Stop Recording"));
                            app.right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                            app.left_button.set_label (_("Pause"));

                        } else {

                            debug ("Countdown Canceled.");
                        }

                        return false;
                    });

                    return false;
                }

                return true;
            });
        }

        public void set_delay (int delay) {

            this.time = delay;
            this.count.label = "<span size='50000'>" + this.time.to_string () + "</span>";
        }

        public void cancel () {

            this.is_canceled = true;
            this.is_active_cd = false;
            this.destroy();
        }
    }
}
