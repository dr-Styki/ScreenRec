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

    public class SendNotification : GLib.Object {

        private Gtk.ApplicationWindow app;
        private string app_id = "com.github.dr-styki.ScreenRec";

        private Notification start_notification = new Notification (_("Recording started"));
        private Notification stop_notification = new Notification (_("Recording stopped"));
        private Notification pause_notification = new Notification (_("Recording paused"));
        private Notification resume_notification = new Notification (_("Recording resumed"));
        private Notification cancel_cd_notification = new Notification (_("Countdown cancelled"));
        

        public SendNotification (Gtk.ApplicationWindow? app) {

            this.app = app;

            start_notification.set_body (_("The recording has been started"));
            stop_notification.set_body (_("The recording is complete"));
            pause_notification.set_body (_("The recording has been paused"));
            resume_notification.set_body (_("The recording has been resumed"));
            cancel_cd_notification.set_body (_("The countdown has been cancelled"));

        }
        
        public void start () {
            this.app.application.send_notification (app_id, start_notification);
        }

        public void stop () {
            this.app.application.send_notification (app_id, stop_notification);
        }

        public void pause () {
            this.app.application.send_notification (app_id, pause_notification);
        }

        public void resume () {
            this.app.application.send_notification (app_id, resume_notification);
        }

        public void cancel_countdown () {
            this.app.application.send_notification (app_id, cancel_cd_notification);
        }
    }
}
