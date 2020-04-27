# project name and programming language
project('com.github.dr-styki.screenrec', 'vala', 'c')

# Include the translations module
i18n = import('i18n')
gnome = import('gnome')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

icon_res = gnome.compile_resources(
    'screenrecorder-icon-resources',
    'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data'
)

# Adding deps
message ('Listing dependencies')

dependencies = [
    dependency('gee-0.8'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    dependency('x11'),
    dependency('gdk-x11-3.0'),
    dependency('gstreamer-1.0'),
    dependency('clutter-gst-3.0'),
    dependency('clutter-gtk-1.0')
]

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    icon_res,
    'src/Application.vala',
    'src/ScreenrecorderWindow.vala',
    'src/Dialogs/Countdown.vala',
    'src/Dialogs/ProgressDialog.vala',
    'src/Dialogs/SaveDialog.vala',
    'src/Tools/Recorder.vala',
    'src/Utils/KeybindingManager.vala',
    'src/Widgets/SelectionArea.vala',
    'src/Widgets/VideoPlayer.vala',
    dependencies: dependencies,
    install: true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')