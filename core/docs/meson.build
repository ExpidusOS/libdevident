libdevident_core_docs_devhelp = custom_target('core-docs-devhelp',
  input: libdevident_core_sources,
  depends: libdevident_core_shlib,
  output: 'devhelp',
  command: [valadoc, '-o', join_paths(meson.current_build_dir(), 'devhelp'),
      '--doclet', 'devhelp', '@INPUT@', '--force',
      '--pkg', 'vadi-0.0', '--pkg', 'gio-2.0',
      '--vapidir', join_paths(meson.project_build_root(), 'subprojects', 'gxml', 'gxml'),
      '--vapidir', join_paths(meson.project_build_root(), 'subprojects', 'vadi', 'lib'),
      '--vapidir', join_paths(gee.get_variable('datadir'), 'vala', 'vapi'),
      vala_defines,
      libdevident_core_docs_args],
  build_by_default: true)

install_subdir(join_paths(meson.current_build_dir(), 'devhelp', 'libdevident'), install_dir: join_paths(datadir, 'devhelp', 'books'))
