import 'package:flutter/material.dart';
import 'package:throwings_core/throwings_core.dart';

/// Returns via [Navigator.pop] the selected throwing. Null if none is selected.
class SelectTrowingOnMapDialog extends StatelessWidget {
  const SelectTrowingOnMapDialog({
    super.key,
    required this.throwings,
    required this.map,
  });

  final List<Throwing> throwings;
  final CS2Map map;

  @override
  Widget build(BuildContext context) {
    const pointSize = 10.0;

    return SimpleDialog(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select throwing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Image.network(map.pathToImage),
                    for (final throwing in throwings)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(throwing);
                          },
                          child: Align(
                            alignment: Alignment(
                              (2 * throwing.selectedPosition.x) - 1,
                              (2 * throwing.selectedPosition.y) - 1,
                            ),
                            child: Container(
                              height: pointSize,
                              width: pointSize,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
