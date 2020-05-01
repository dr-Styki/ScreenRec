/*
* Copyright 2018-2020 Ryo Nakano
*           2020 Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
*
*/

namespace ScreenRec {

    public class RecordView : Gtk.Box {

        private Gtk.Label time_label;
        private uint count;
        private bool pause = false;
        private int past_minutes_10;
        private int past_minutes_1;
        private int past_seconds_10;
        private int past_seconds_1;


        public RecordView () {

            Object (
                orientation: Gtk.Orientation.VERTICAL,
                spacing: 12,
                margin: 0
            );
        }

        construct {

            time_label = new Gtk.Label (null);
            time_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

            var label_grid = new Gtk.Grid ();
            label_grid.column_spacing = 6;
            label_grid.row_spacing = 6;
            label_grid.halign = Gtk.Align.CENTER;
            label_grid.attach (time_label, 0, 1, 1, 1);

            pack_start (label_grid, false, false);
        }

        public async void trigger_stop_recording () {

            stop_count ();
        }

        public void init_count () {

            past_minutes_10 = 0;
            past_minutes_1 = 0;
            past_seconds_10 = 0;
            past_seconds_1 = 0;

            pause = false;
            show_timer_label (time_label, past_minutes_10, past_minutes_1, past_seconds_10, past_seconds_1);
            start_count ();
        }

        private void show_timer_label (Gtk.Label label, int minutes_10, int minutes_1, int seconds_10, int seconds_1) {

            label.label = "<span size='64000' weight='normal'>%i%i</span><span size='24000' weight='normal'>:%i%i</span>".printf (minutes_10, minutes_1, seconds_10, seconds_1);
            label.use_markup = true;
            label.margin_top = 20;
        }

        private void start_count () {

            count = Timeout.add (1000, () => {

                // If the user pressed "pause", do not count this second.
                if (pause) {
                    return false;
                }

                if (past_seconds_10 < 5 && past_seconds_1 == 9) {
                    // The count turns from wx:y9 to wx:(y+1)0
                    past_seconds_10++;
                    past_seconds_1 = 0;
                } else if (past_minutes_1 < 9 && past_seconds_10 == 5 && past_seconds_1 == 9) {
                    // The count turns from wx:59 to w(x+1):00
                    past_minutes_1++;
                    past_seconds_1 = past_seconds_10 = 0;
                } else if (past_minutes_1 == 9 && past_seconds_10 == 5 && past_seconds_1 == 9) {
                    // The count turns from w9:59 to (w+1)0:00
                    past_minutes_10++;
                    past_minutes_1 = past_seconds_10 = past_seconds_1 = 0;
                } else {
                    // The count turns from wx:yx to wx:y(z+1)
                    past_seconds_1++;
                }

                show_timer_label (time_label, past_minutes_10, past_minutes_1, past_seconds_10, past_seconds_1);
                return true;
            });
        }

        public void pause_count () {

            pause = true;
            count = 0;
        }

        public void resume_count () {

            pause = false;
            start_count ();
        }

        public void stop_count () {

            pause = true;
            count = 0;
        }
    }
}