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

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src' / 'Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

# Listing dependencies
dependencies = [
    dependency ('glib-2.0'),
    dependency ('gtk+-3.0'),
    dependency ('granite'),
    dependency('libhandy-1', version: '>=1.0.0'),
    dependency('libpulse'),
    dependency('libpulse-mainloop-glib'),
]

subdir ('src')

# Executable
executable (
    meson.project_name (),
    config_file,
    sources,
    dependencies: dependencies,
    install: true
)

subdir ('data')
subdir ('po')

meson.add_install_script ('meson/post_install.py')
