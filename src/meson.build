sources = [
  'main.vala',
  'window.vala',
  'application.vala',
  'alertView.vala',
  'digest.vala',
  'pulseManager.vala',
  'util.vala',
  'mockup.vala'
]

dependencies = [
  dependency('libadwaita-1', version: '>= 1.0'),
  dependency ('glib-2.0', version: '>= 2.74.4'),
  dependency ('gee-0.8'),
  dependency ('gtk4'),
  dependency ('libpulse'),
  dependency ('libpulse-mainloop-glib'),
]

gnome = import('gnome')

sources += gnome.compile_resources('mixer-resources',
  'mixer.gresource.xml',
  c_name: 'mixer'
)

sources += configure_file(
  input: 'constants.vala.in',
  output: 'constants.vala',
  configuration: config_data
)

# Executable
executable(
  app_id,
  sources,
  vala_args: [
    '--target-glib=2.50',
    '--gresourcesdir=src/',
  ],
  dependencies: dependencies,
  install: true,
)
