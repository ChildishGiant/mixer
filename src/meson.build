sources = [
  'main.vala',
  'window.vala',
  'application.vala',
  'digest.vala',
  'pulseManager.vala',
  'util.vala',
  'mockup.vala'
]

dependencies = [
  dependency('libadwaita-1', version: '>= 1.0'),
  dependency ('glib-2.0', version: '>= 2.74.1'),
  dependency ('gee-0.8'),
  dependency ('gtk4'),
  dependency ('libpulse'),
  dependency ('libpulse-mainloop-glib'),
]

gnome = import('gnome')

blueprints_src = [
  'window.blp',
  'appEntry.blp'
]

blueprints_ui = []
blueprints_vala = []
foreach b : blueprints_src
  blueprints_ui += b.replace('.blp', '.ui')
  blueprints_vala += b + '.vala'
endforeach


blueprints = custom_target('blueprints',
  input: blueprints_src,
  output: blueprints_ui,
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTDIR@', '@CURRENT_SOURCE_DIR@', '@INPUT@']
)

sources += custom_target('blueprints_hack',
  input: blueprints,
  output: blueprints_vala,
  command: [find_program('touch'), '@OUTPUT@']
)

sources += configure_file(
  input: 'constants.vala.in',
  output: 'constants.vala',
  configuration: config_data
)

sources += gnome.compile_resources('mixer-resources',
  'mixer.gresource.xml',
  c_name: 'mixer',
  dependencies: blueprints,
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
