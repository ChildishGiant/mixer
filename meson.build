# Project name, programming language and version
project (
    'com.github.childishgiant.mixer',
    'vala', 'c',
    version: '0.1.4'
)

# Translation module
i18n = import ('i18n')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

add_project_arguments(
    ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
    language: 'vala'
)


# Listing dependencies
dependencies = [
    dependency ('glib-2.0'),
    dependency ('gee-0.8'),
    dependency ('gtk4'),
    dependency ('granite-7'),
    dependency ('libpulse'),
    dependency ('libpulse-mainloop-glib'),
]

subdir ('src')

# Executable
executable (
    meson.project_name (),
    sources,
    dependencies: dependencies,
    install: true
)

subdir ('data')
subdir ('po')

meson.add_install_script ('meson/post_install.py')
