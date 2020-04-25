//
//  Copyright (C) 2011-2015 Eidete Developers
//  Copyright (C) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
//  Copyright (C) 2020 Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

namespace ScreenRec {

    public class Countdown : Gtk.Dialog {
        
        public Gtk.Label count;
        public int time;

        public Countdown (int time) {

            this.time = time;
            this.set_default_size (400, 200);
            this.set_deletable(false);
            this.window_position = Gtk.WindowPosition.CENTER;
            this.set_keep_above (true);
            this.stick ();

            var content_area = this.get_content_area ();

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.margin_start = 30;
            box.margin_end = 40;
            box.margin_top = box.margin_bottom = 20;

            var title = new Gtk.Label ("<span size='20000'>" + _("Recording starts in") + "…" + "</span>");
            title.use_markup = true;
            title.margin_bottom = 10;

            this.time = time;
            this.count = new Gtk.Label ("<span size='50000'>" + time.to_string () + "</span>");
            this.count.use_markup = true;

            box.pack_start (title);
            box.pack_start (count);

            content_area.add (box);
        }

        public void start (Recorder recorder) {

            this.show_all ();

            Timeout.add (1000, () => {
                this.time--;

                count.label = "<span size='50000'>" + time.to_string () + "</span>";

                if (time == -1) {
                    this.destroy ();

                    // let the countdown disappear before starting
                    Timeout.add (100, () => {
                        recorder.start ();
                        return false;
                    });

                    return false;
                }

                return true;
            });
        }
    }
}