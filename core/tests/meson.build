foreach name : ['context', 'device']
  test('core/@0@'.format(name), executable('test-@0@'.format(name), name + '.vala',
      c_args: ['-I' + join_paths(meson.project_build_root(), 'core')],
      vala_args: libdevident_core_flags,
      dependencies: [libdevident_core]),
    env: [
      'G_TEST_SRCDIR=@0@'.format(meson.current_source_dir()),
      'G_TEST_BUILDDIR=@0@'.format(meson.current_build_dir())
    ], protocol: 'tap')
endforeach
