project('mixer', ['c', 'vala'],
          version: '2.0.0',
    meson_version: '>= 0.59.0',
  default_options: [ 'warning_level=2']
)

app_id = 'com.github.childishgiant.mixer'
resource_path = '/com/github/childishgiant/mixer'

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

i18n = import('i18n')
gnome = import('gnome')

# config variables

config_data = configuration_data()


# project version
config_data.set('VERSION', meson.project_version())

# application ID
config_data.set('APP_ID', app_id)

# application resource path
config_data.set('RESOURCE_PATH', resource_path)

# GNU GetText package name
config_data.set('GETTEXT_PACKAGE', meson.project_name())

# data directory paths
config_data.set('LOCALE_DIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set('DATA_DIR', join_paths(get_option('prefix'), get_option('datadir'), meson.project_name()))



subdir('data')
subdir('src')
subdir('po')


gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
