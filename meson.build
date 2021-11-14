# Project name, programming language and version
project (
    'com.github.dr_styki.screenrec',
    'vala', 'c',
    version: '3.0.2',
    license: 'GPL-3.0'
)

# Translation module
i18n = import ('i18n')

# GNOME module
gnome = import ('gnome')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

add_project_arguments(
    ['--vapidir', meson.current_source_dir() / 'vapi'],
    language: 'vala'
)

# Compiling resources
asresources = gnome.compile_resources (
    'as-resources',
    join_paths ('data', meson.project_name ()) + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

# Listing dependencies
dependencies = [
    dependency ('glib-2.0'),
    dependency ('gee-0.8'),
    dependency ('granite', version: '>=6.0.0'),
    dependency ('gtk+-3.0'),
    dependency ('libhandy-1'),
    dependency ('x11'),
    dependency ('gdk-x11-3.0'),
    dependency ('gstreamer-1.0'),
    dependency ('clutter-gst-3.0'),
    dependency ('clutter-gtk-1.0'),
    dependency ('libpulse'),
    dependency ('libpulse-mainloop-glib')
]

subdir ('src')

# Defining executable
executable (
    meson.project_name (),
    sources,
    asresources,
    dependencies: dependencies,
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
