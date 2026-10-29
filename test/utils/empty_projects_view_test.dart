import 'package:daw_project_manager/utils/empty_projects_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('before the library is read, it is loading — never "no projects"', () {
    // Read as none, it put the first-run Drive screen up on every launch.
    expect(emptyProjectsView(libraryLoaded: false, totalProjects: 0),
        EmptyProjectsView.loading);
  });

  test('a read library with projects is filtered out', () {
    expect(emptyProjectsView(libraryLoaded: true, totalProjects: 3),
        EmptyProjectsView.filteredOut);
  });

  test('a read library with none is the first run', () {
    expect(emptyProjectsView(libraryLoaded: true, totalProjects: 0),
        EmptyProjectsView.noProjects);
  });
}
