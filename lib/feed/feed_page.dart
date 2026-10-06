import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../onboarding/search_criteria.dart';
import 'photo_carousel.dart';
import 'vehicle.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    const vehicle = Vehicle.demo;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre sélection'),
        actions: [
          IconButton(
            key: const Key('filter-button'),
            tooltip: 'Modifier ma recherche',
            icon: const Icon(Icons.filter_list),
            onPressed: () => context.go('/onboarding'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhotoCarousel(photos: vehicle.photos),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicle.title,
                            style: theme.textTheme.headlineSmall),
                        Text(vehicle.version,
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${formatNumber(vehicle.price)} €',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Spec(Icons.calendar_today, '${vehicle.year}'),
                            _Spec(Icons.speed,
                                '${formatNumber(vehicle.mileage)} km'),
                            _Spec(Icons.local_gas_station, vehicle.fuel),
                            _Spec(Icons.bolt, '${vehicle.power} ch'),
                            _Spec(Icons.eco, 'Crit\'Air ${vehicle.critAir}'),
                            _Spec(Icons.place, vehicle.city),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(vehicle.description),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('contact-button'),
              onPressed: () {},
              child: const Text('Je souhaite être contacté'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('home-button'),
              onPressed: () {
                context.read<SearchCriteria>().reset();
                context.go('/onboarding');
              },
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}
