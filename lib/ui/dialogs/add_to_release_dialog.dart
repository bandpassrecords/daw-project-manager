import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/release.dart';
import '../../providers/providers.dart';
import '../../repository/project_repository.dart';

class AddToReleaseDialog extends ConsumerStatefulWidget {
  final List<String> projectIds;

  const AddToReleaseDialog({super.key, required this.projectIds});

  @override
  ConsumerState<AddToReleaseDialog> createState() => _AddToReleaseDialogState();
}

class _AddToReleaseDialogState extends ConsumerState<AddToReleaseDialog> {
  final _titleController = TextEditingController();
  String? _selectedReleaseId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final releases = ref.watch(releasesProvider).asData?.value ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add to Release'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Create New'),
              Tab(text: 'Add to Existing'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Create New Release Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Release Title'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_titleController.text.isNotEmpty) {
                        final repo = await ref.read(repositoryProvider.future);
                        final newRelease = Release(
                          id: const Uuid().v4(),
                          title: _titleController.text,
                          trackIds: widget.projectIds,
                          releaseDate: DateTime.now(),
                        );
                        await repo.addRelease(newRelease);
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Create and Add'),
                  ),
                ],
              ),
            ),

            // Add to Existing Release Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (releases.isNotEmpty)
                    DropdownButton<String>(
                      value: _selectedReleaseId,
                      hint: const Text('Select a release'),
                      isExpanded: true,
                      items: releases.map((Release release) {
                        return DropdownMenuItem<String>(
                          value: release.id,
                          child: Text(release.title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedReleaseId = value;
                        });
                      },
                    )
                  else
                    const Text('No existing releases found.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedReleaseId == null
                        ? null
                        : () async {
                            final repo = await ref.read(repositoryProvider.future);
                            final existingRelease = releases.firstWhere((r) => r.id == _selectedReleaseId);
                            final updatedTrackIds = {...existingRelease.trackIds, ...widget.projectIds}.toList();
                            final updatedRelease = existingRelease.copyWith(trackIds: updatedTrackIds);
                            await repo.updateRelease(updatedRelease);
                            Navigator.of(context).pop();
                          },
                    child: const Text('Add to Selected Release'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
