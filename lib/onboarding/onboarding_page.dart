import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../core/app_logo.dart';
import 'brand_button.dart';
import 'crit_air_section.dart';
import 'search_criteria.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final criteria = context.watch<SearchCriteria>();
    final power = criteria.power;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('onboarding-logout'),
            tooltip: 'Me déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const Center(child: AppLogo(size: 56)),
            const SizedBox(height: 24),
            const _SectionTitle('Je cherche une voiture à'),
            SegmentedButton<SearchMode>(
              segments: [
                for (final m in SearchMode.values)
                  ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {criteria.mode},
              onSelectionChanged: (s) => criteria.setMode(s.first),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Lieu'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('location-around'),
                  label: const Text('Autour de moi'),
                  selected: criteria.aroundMe,
                  onSelected: (_) => criteria.setAroundMe(true),
                ),
                ChoiceChip(
                  key: const Key('location-city'),
                  label: const Text('Sélectionner une ville'),
                  selected: !criteria.aroundMe,
                  onSelected: (_) => criteria.setAroundMe(false),
                ),
              ],
            ),
            if (!criteria.aroundMe) ...[
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Ville'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('city-dropdown'),
                    isExpanded: true,
                    value: criteria.city,
                    items: [
                      for (final c in kCities)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (c) {
                      if (c != null) criteria.setCity(c);
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const _SectionTitle('Motorisation'),
            Wrap(
              spacing: 8,
              children: [
                for (final f in Fuel.values)
                  FilterChip(
                    key: Key('fuel-${f.name}'),
                    label: Text(f.label),
                    selected: criteria.fuels.contains(f),
                    onSelected: (_) => criteria.toggleFuel(f),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Nombre de chevaux'),
            Text(
              '${power.start.round()} – ${power.end.round()} ch',
              key: const Key('power-label'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RangeSlider(
              values: power,
              min: kMinPower,
              max: kMaxPower,
              divisions: 94,
              labels: RangeLabels(
                '${power.start.round()} ch',
                '${power.end.round()} ch',
              ),
              onChanged: criteria.setPower,
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Marque'),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final b in Brand.values)
                      SizedBox(
                        width: width,
                        child: BrandButton(
                          key: Key('brand-${b.name}'),
                          brand: b,
                          selected: criteria.brands.contains(b),
                          onPressed: () => criteria.toggleBrand(b),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const CritAirSection(),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('validate-button'),
              onPressed: () => context.go('/feed'),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
