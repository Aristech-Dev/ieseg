import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'search_criteria.dart';

class CritAirSection extends StatelessWidget {
  const CritAirSection({super.key});

  @override
  Widget build(BuildContext context) {
    final criteria = context.watch<SearchCriteria>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          key: const Key('critair-checkbox'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Vignette Crit\'Air'),
          subtitle: const Text(
            'De quelle vignette ai-je besoin pour circuler dans ma ville ?',
          ),
          value: criteria.critAir,
          onChanged: (v) => criteria.setCritAir(v ?? false),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: criteria.critAir
              ? Card(
                  key: const Key('critair-text'),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'La vignette Crit\'Air classe les véhicules de 0 '
                      '(électrique et hydrogène) à 5 selon leurs émissions. '
                      'Selon votre ville, certaines zones à faibles émissions '
                      'peuvent limiter l\'accès aux véhicules les plus '
                      'polluants. (Texte de démonstration.)',
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
