/*
* Copyright (c) 2018 mohelm97 (https://github.com/mohelm97/ScreenRecorder)
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
               Stevy THOMAS (dr_Styki) <dr_Styki@hack.i.ng>
*/

namespace ScreenRec {
    public class FormatComboBox : Gtk.ComboBoxText {
        private string _text_value;
        public string text_value {
            get { return _text_value; }
            set {
                _text_value = value;
                switch (value) {
                    case "raw":
                        active = 0;
                        break;
                    case "mp4":
                        active = 1;
                        break;
                    case "mov":
                        active = 2;
                        break;
                    case "gif":
                        active = 3;
                        break;
                }
            }
        }
        public FormatComboBox () {
            append_text ("raw");
            append_text ("mp4");
            append_text ("mov");
            append_text ("gif");
            changed.connect (() => {
                text_value = get_active_text ();
            });
        }
    }
}
